import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/core/platform/system_services.dart';
import 'package:stitch/features/captions/data/caption_models.dart';
import 'package:stitch/features/captions/data/speech_recognizer.dart';

part 'caption_providers.g.dart';

@Riverpod(keepAlive: true)
SpeechRecognizer speechRecognizer(Ref ref) => const WhisperRecognizer();

/// Models live in the cache folder: kept out of backups, and downloaded
/// again if the system clears them.
@Riverpod(keepAlive: true)
CaptionModelStore captionModelStore(Ref ref) => CaptionModelStore(
  Directory(p.join(ref.watch(cacheRootProvider).path, 'models')),
);

/// Where a caption model stands on this device.
sealed class ModelStatus {
  const new();
}

final class ModelMissing extends ModelStatus {
  const new();
}

final class ModelDownloading extends ModelStatus {
  const new(this.fraction);

  final double fraction;
}

final class ModelReady extends ModelStatus {
  const new();
}

final class ModelFailed extends ModelStatus {
  const new(this.failure);

  final Object failure;
}

/// Each caption model's status, and its download. Downloads carry on
/// while the captions sheet is closed.
@Riverpod(keepAlive: true)
class CaptionModels extends _$CaptionModels {
  final _downloads = <CaptionModel, ModelDownload>{};

  CaptionModelStore get _store => ref.read(captionModelStoreProvider);

  @override
  Map<CaptionModel, ModelStatus> build() {
    final store = ref.watch(captionModelStoreProvider);
    ref.onDispose(() {
      for (final d in _downloads.values) {
        unawaited(d.cancel());
      }
    });
    return {
      for (final m in CaptionModel.values)
        m: store.isInstalled(m.file)
            ? const ModelReady()
            : const ModelMissing(),
    };
  }

  void _set(CaptionModel model, ModelStatus status) {
    if (!ref.mounted) return;
    state = {...state, model: status};
  }

  /// Downloads being set up (space checked) but not yet started.
  final _starting = <CaptionModel>{};

  Future<void> download(CaptionModel model) async {
    if (_downloads.containsKey(model) ||
        _starting.contains(model) ||
        state[model] is ModelReady) {
      return;
    }
    _starting.add(model);
    try {
      await ensureSpace(
        ref.read(systemServicesProvider),
        _store.directory.parent.path,
        model.bytes + 100 * 1000 * 1000,
      );
    } on InsufficientStorageFailure catch (e) {
      _set(model, ModelFailed(e));
      return;
    } finally {
      _starting.remove(model);
    }
    final download = _store.download(model.file);
    _downloads[model] = download;
    _set(model, const ModelDownloading(0));
    final progress = download.progress.listen(
      (f) => _set(model, ModelDownloading(f)),
    );
    try {
      await download.done;
      _set(model, const ModelReady());
    } on CancelledFailure {
      _set(model, const ModelMissing());
    } on Object catch (e) {
      _set(model, ModelFailed(e));
    } finally {
      await progress.cancel();
      _downloads.remove(model);
    }
  }

  Future<void> cancel(CaptionModel model) async {
    await _downloads[model]?.cancel();
  }

  Future<void> delete(CaptionModel model) async {
    await cancel(model);
    await _store.delete(model.file);
    _set(model, const ModelMissing());
  }

  /// After recognition found the model damaged: remove it, so the next
  /// attempt downloads it again.
  Future<void> discard(CaptionModel model) => delete(model);
}
