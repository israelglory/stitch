import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:stitch/app/failure_messages.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/core/time/time.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/engine/editor_engine.dart';
import 'package:stitch/engine/engine_provider.dart';
import 'package:stitch/features/audio/application/audio_providers.dart';
import 'package:stitch/features/audio/data/audio_device.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/timeline/domain/models.dart' as m;
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Opens the voiceover recorder. The preview stays visible above it and
/// plays, muted, while recording.
Future<void> showVoiceoverSheet(BuildContext context, String projectId) =>
    showAppBottomSheet<void>(
      context: context,
      dimBackground: false,
      builder: (context) => AppBottomSheet(
        title: AppLocalizations.of(context).voiceoverTitle,
        child: VoiceoverPanel(projectId: projectId),
      ),
    );

enum _Phase {
  checking,
  askAccess,
  askAgain,
  settings,
  ready,
  countdown,
  recording,
  review,
}

/// Records a voiceover from the playhead: asks for the microphone when
/// needed, counts down from 3, records with a live level meter, then
/// offers a retake or adds it to the timeline.
class VoiceoverPanel extends ConsumerStatefulWidget {
  const new({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<VoiceoverPanel> createState() => _VoiceoverPanelState();
}

class _VoiceoverPanelState extends ConsumerState<VoiceoverPanel>
    with WidgetsBindingObserver {
  static const _countdownFrom = 3;
  static const _levelHistory = 120;

  // Read up front: dispose may not use ref.
  late final AudioDevice _device;
  late final EditorEngine _engine;
  late final PlaybackController _playback;

  /// Where the recording starts on the timeline: the playhead on opening.
  late final int _startUs;

  _Phase _phase = _Phase.checking;
  int _count = _countdownFrom;
  Timer? _timer;
  final _levels = <double>[];
  final _stopwatch = Stopwatch();
  StreamSubscription<double>? _levelSub;
  StreamSubscription<Recording?>? _interruptSub;
  Recording? _take;
  String? _notice;
  Object? _error;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _device = ref.read(audioDeviceProvider);
    _engine = ref.read(editorEngineProvider);
    _playback = ref.read(playbackControllerProvider.notifier);
    _startUs = ref.read(playbackControllerProvider).positionUs;
    WidgetsBinding.instance.addObserver(this);
    _interruptSub = _device.interruptions.listen(_onInterrupted);
    unawaited(_checkAccess());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    unawaited(_levelSub?.cancel());
    unawaited(_interruptSub?.cancel());
    if (_phase == _Phase.recording) {
      unawaited(_device.cancelRecording());
      unawaited(_restorePreview());
    }
    // A take that was not added is not kept.
    _discard(_take);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from system settings: access may have changed.
    if (state == AppLifecycleState.resumed && _phase == _Phase.settings) {
      unawaited(_checkAccess());
    }
  }

  Future<void> _checkAccess() async => _show(await _device.micAccess());

  Future<void> _request() async => _show(await _device.requestMic());

  void _show(MicAccess access) {
    if (!mounted) return;
    setState(
      () => _phase = switch (access) {
        MicAccess.granted => _Phase.ready,
        MicAccess.undetermined => _Phase.askAccess,
        MicAccess.denied => _Phase.askAgain,
        MicAccess.permanentlyDenied => _Phase.settings,
      },
    );
  }

  void _startCountdown() {
    setState(() {
      _phase = _Phase.countdown;
      _count = _countdownFrom;
      _notice = null;
      _error = null;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_count > 1) {
        setState(() => _count--);
      } else {
        timer.cancel();
        unawaited(_startRecording());
      }
    });
  }

  Future<void> _startRecording() async {
    final path = p.join(
      ref.read(cacheRootProvider).path,
      'voiceover',
      '${DateTime.now().microsecondsSinceEpoch}.m4a',
    );
    try {
      await _device.startRecording(path);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.ready;
          _error = e;
        });
      }
      return;
    }
    if (!mounted) {
      await _device.cancelRecording();
      return;
    }
    _levels.clear();
    _levelSub = _device.levels.listen((level) {
      if (!mounted) return;
      setState(() {
        _levels.add(level);
        if (_levels.length > _levelHistory) _levels.removeAt(0);
      });
    });
    // Narrate over the video: it plays from the start point, silently.
    await _engine.setPreviewVolume(0);
    await _playback.seek(_startUs);
    await _playback.play();
    _stopwatch
      ..reset()
      ..start();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
    setState(() => _phase = _Phase.recording);
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _stopwatch.stop();
    await _levelSub?.cancel();
    try {
      final take = await _device.stopRecording();
      if (!mounted) {
        _discard(take);
        return;
      }
      setState(() {
        _take = take;
        _phase = _Phase.review;
      });
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.ready;
          _error = e;
        });
      }
    } finally {
      await _restorePreview();
    }
  }

  void _onInterrupted(Recording? kept) {
    if (!mounted || _phase != _Phase.recording) return;
    _timer?.cancel();
    _stopwatch.stop();
    unawaited(_levelSub?.cancel());
    unawaited(_restorePreview());
    setState(() {
      _notice = AppLocalizations.of(context).recordingInterrupted;
      _take = kept;
      _phase = kept == null ? _Phase.ready : _Phase.review;
    });
  }

  Future<void> _restorePreview() async {
    await _playback.pause();
    await _engine.setPreviewVolume(1);
    await _playback.seek(_startUs);
  }

  void _retake() {
    _discard(_take);
    setState(() {
      _take = null;
      _notice = null;
      _phase = _Phase.ready;
    });
  }

  Future<void> _add() async {
    final take = _take;
    if (take == null) return;
    setState(() => _adding = true);
    try {
      await ref
          .read(editorControllerProvider(widget.projectId).notifier)
          .addAudioFile(
            File(take.path),
            name: AppLocalizations.of(context).voiceoverName,
            kind: m.AudioKind.voiceover,
            atUs: _startUs,
            move: true,
          );
      _take = null;
      if (mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _adding = false;
          _error = e;
        });
      }
    }
  }

  static void _discard(Recording? take) {
    if (take == null) return;
    final file = File(take.path);
    if (file.existsSync()) file.deleteSync();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final error = _error;
    final errorText = error == null ? null : failureMessage(l10n, error);

    Widget explain(
      String title,
      String message,
      String action,
      VoidCallback f,
    ) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: AppTypography.bodyLarge.semibold.copyWith(
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          message,
          style: AppTypography.body.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(label: action, onPressed: f),
      ],
    );

    final body = switch (_phase) {
      _Phase.checking => const SizedBox(
        height: AppSizes.recordButton,
        child: Center(child: LinearProgress()),
      ),
      _Phase.askAccess => explain(
        l10n.micAccessTitle,
        l10n.micAccessMessage,
        l10n.allowMicrophone,
        _request,
      ),
      _Phase.askAgain => explain(
        l10n.micDeniedTitle,
        l10n.micAskAgainMessage,
        l10n.allowMicrophone,
        _request,
      ),
      _Phase.settings => explain(
        l10n.micDeniedTitle,
        l10n.micDeniedMessage,
        l10n.openSettings,
        () => unawaited(_device.openSettings()),
      ),
      _Phase.ready || _Phase.countdown || _Phase.recording => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_phase == _Phase.recording)
            LevelMeter(levels: List.of(_levels))
          else
            const SizedBox(height: AppSizes.levelMeter),
          const SizedBox(height: AppSpacing.md),
          Text(
            _phase == _Phase.recording
                ? l10n.recordingElapsed(
                    formatDuration(_stopwatch.elapsedMicroseconds),
                  )
                : l10n.recordsFrom(formatDuration(_startUs)),
            style: AppTypography.body.tabular.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          RecordButton(
            state: switch (_phase) {
              _Phase.countdown => RecordButtonState.countdown,
              _Phase.recording => RecordButtonState.recording,
              _ => RecordButtonState.ready,
            },
            count: _count,
            semanticLabel: switch (_phase) {
              _Phase.countdown => l10n.recordingStartsIn(_count),
              _Phase.recording => l10n.stopRecording,
              _ => l10n.record,
            },
            onPressed: switch (_phase) {
              _Phase.ready => _startCountdown,
              _Phase.recording => () => unawaited(_stop()),
              _ => null,
            },
          ),
        ],
      ),
      _Phase.review => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.recordingLength(formatDuration(_take?.durationUs ?? 0)),
            textAlign: TextAlign.center,
            style: AppTypography.body.tabular.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: l10n.retake,
                  onPressed: _adding ? null : _retake,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: PrimaryButton(
                  label: l10n.useRecording,
                  onPressed: _adding ? null : () => unawaited(_add()),
                ),
              ),
            ],
          ),
        ],
      ),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_notice case final notice?) ...[
          ErrorBanner(message: notice),
          const SizedBox(height: AppSpacing.md),
        ],
        if (errorText != null) ...[
          ErrorBanner(message: errorText),
          const SizedBox(height: AppSpacing.md),
        ],
        body,
      ],
    );
  }
}
