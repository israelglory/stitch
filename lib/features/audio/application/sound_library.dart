import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/core/logging/logger.dart';
import 'package:stitch/core/network/file_download.dart';
import 'package:stitch/features/audio/data/sound_library.dart';
import 'package:stitch/features/settings/application/settings_controller.dart';

part 'sound_library.g.dart';

const _log = Logger('SoundLibrary');

/// Downloaded library sounds, kept when the cache is cleared (see
/// storage.dart).
@Riverpod(keepAlive: true)
SoundLibraryStore soundLibraryStore(Ref ref) => SoundLibraryStore(
  Directory(p.join(ref.watch(cacheRootProvider).path, 'sounds')),
);

/// The catalog the app ships, used until a newer one is fetched (and
/// offline). Tests override it.
@Riverpod(keepAlive: true)
Future<String> shippedSoundCatalog(Ref ref) =>
    rootBundle.loadString('assets/sound_library/catalog.json');

/// Where one library sound stands on this device.
sealed class LibrarySoundStatus {
  const new();
}

final class NotDownloaded extends LibrarySoundStatus {
  const new();
}

/// Waiting for a free download slot, or downloading ([progress] 0 to 1).
final class Downloading extends LibrarySoundStatus {
  const new(this.progress);

  final double progress;
}

final class Downloaded extends LibrarySoundStatus {
  const new();
}

/// The last download failed; [error] says why.
final class DownloadFailed extends LibrarySoundStatus {
  const new(this.error);

  final Object error;
}

/// The online library as the screens show it.
@immutable
final class SoundLibraryState {
  const new({required this.enabled, this.catalog, this.statuses = const {}});

  /// False when the user turned the online library off in Settings.
  final bool enabled;

  /// Null until loaded.
  final SoundCatalog? catalog;
  final Map<String, LibrarySoundStatus> statuses;

  LibrarySoundStatus statusOf(LibrarySound sound) =>
      statuses[sound.id] ?? const NotDownloaded();

  SoundLibraryState copyWith({
    SoundCatalog? catalog,
    Map<String, LibrarySoundStatus>? statuses,
  }) => SoundLibraryState(
    enabled: enabled,
    catalog: catalog ?? this.catalog,
    statuses: statuses ?? this.statuses,
  );
}

/// The online library: its catalog (the newest is fetched once per run of
/// the app) and downloads, at most [_parallel] at a time.
@Riverpod(keepAlive: true)
class SoundLibrary extends _$SoundLibrary {
  static const _parallel = 2;

  final _running = <String, FileDownload>{};
  final _queue = <LibrarySound>[];
  bool _fetched = false;

  SoundLibraryStore get _store => ref.read(soundLibraryStoreProvider);

  @override
  SoundLibraryState build() {
    final enabled = ref.watch(
      settingsControllerProvider.select((s) => s.onlineSounds),
    );
    ref.onDispose(() {
      for (final d in _running.values) {
        unawaited(d.cancel());
      }
      _running.clear();
      _queue.clear();
    });
    if (!enabled) return const SoundLibraryState(enabled: false);
    unawaited(_load());
    return const SoundLibraryState(enabled: true);
  }

  Future<void> _load() async {
    final store = _store;
    var catalog = store.savedCatalog();
    if (catalog == null) {
      try {
        catalog = SoundCatalog.parse(
          await ref.read(shippedSoundCatalogProvider.future),
        );
      } on Object catch (e, st) {
        _log.error('Shipped sound catalog unreadable', e, st);
      }
    }
    if (!ref.mounted || catalog == null) return;
    _show(catalog);
    if (_fetched) return;
    _fetched = true;
    final fresh = await store.fetchCatalog(catalog);
    if (ref.mounted && fresh != null) _show(fresh);
  }

  void _show(SoundCatalog catalog) {
    state = state.copyWith(
      catalog: catalog,
      statuses: {
        for (final s in catalog.sounds)
          s.id: switch (state.statuses[s.id]) {
            final Downloading d => d,
            _ when _store.isDownloaded(s) => const Downloaded(),
            final DownloadFailed f => f,
            _ => const NotDownloaded(),
          },
      },
    );
  }

  void _set(String id, LibrarySoundStatus status) {
    if (!ref.mounted) return;
    state = state.copyWith(statuses: {...state.statuses, id: status});
  }

  /// Downloads [sound] (queued behind others); also retries a failure.
  void download(LibrarySound sound) {
    final status = state.statusOf(sound);
    if (status is Downloading || status is Downloaded) return;
    if (state.catalog == null) return;
    _queue.add(sound);
    _set(sound.id, const Downloading(0));
    _next();
  }

  void _next() {
    final catalog = state.catalog;
    if (catalog == null) return;
    while (_running.length < _parallel && _queue.isNotEmpty) {
      final sound = _queue.removeAt(0);
      final download = _store.download(catalog, sound);
      _running[sound.id] = download;
      final progress = download.progress.listen(
        (v) => _set(sound.id, Downloading(v)),
      );
      unawaited(
        download.done
            .then<LibrarySoundStatus>((_) => const Downloaded())
            .catchError((Object e, StackTrace st) {
              if (e is CancelledFailure) return const NotDownloaded();
              _log.warning('Sound ${sound.id} did not download', e, st);
              return DownloadFailed(e);
            })
            .then((status) async {
              await progress.cancel();
              _running.remove(sound.id);
              _set(sound.id, status);
              if (ref.mounted) _next();
            }),
      );
    }
  }

  /// Stops [sound]'s download; what arrived is kept, to resume from.
  Future<void> cancel(LibrarySound sound) async {
    if (_queue.remove(sound)) {
      _set(sound.id, const NotDownloaded());
      return;
    }
    await _running[sound.id]?.cancel();
  }

  Future<void> delete(LibrarySound sound) async {
    await cancel(sound);
    await _store.delete(sound);
    _set(sound.id, const NotDownloaded());
  }

  /// Deletes every downloaded sound (Settings).
  Future<void> deleteAll() async {
    for (final s in [..._queue]) {
      await cancel(s);
    }
    for (final d in [..._running.values]) {
      await d.cancel();
    }
    await _store.deleteAll();
    final catalog = state.catalog;
    if (catalog != null && ref.mounted) _show(catalog);
  }

  /// A file to try [sound] with before downloading it.
  Future<File> previewFile(LibrarySound sound) async {
    final catalog = state.catalog;
    if (catalog == null) throw const DownloadFailure(cause: 'No catalog');
    final file = await _store.previewFile(catalog, sound);
    // Trying an effect downloads it.
    if (_store.isDownloaded(sound)) _set(sound.id, const Downloaded());
    return file;
  }

  /// The downloaded file of [sound].
  File fileOf(LibrarySound sound) => _store.file(sound);
}
