import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:stitch/app/failure_messages.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/core/time/time.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/audio/application/audio_providers.dart';
import 'package:stitch/features/audio/application/bundled_files.dart';
import 'package:stitch/features/audio/data/audio_device.dart';
import 'package:stitch/features/audio/data/bundled_audio.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/timeline/domain/models.dart' as m;
import 'package:stitch/l10n/generated/app_localizations.dart';

enum AudioLibraryKind { music, effects }

enum _Source { bundled, device }

/// Music or sound effects to add at the playhead: the bundled library,
/// tried before adding, and (for music) a file from the device.
class AudioLibraryScreen extends ConsumerStatefulWidget {
  const new({required this.projectId, required this.kind, super.key});

  final String projectId;
  final AudioLibraryKind kind;

  @override
  ConsumerState<AudioLibraryScreen> createState() => _AudioLibraryState();
}

class _AudioLibraryState extends ConsumerState<AudioLibraryScreen> {
  _Source _source = _Source.bundled;
  bool _busy = false;
  Object? _error;

  /// The sound being tried, while its file is prepared or it plays.
  BundledSound? _trying;

  // Read up front: dispose may not use ref.
  late final AudioDevice _device;
  late final Directory _cache;

  @override
  void initState() {
    super.initState();
    _device = ref.read(audioDeviceProvider);
    _cache = ref.read(cacheRootProvider);
  }

  bool get _music => widget.kind == AudioLibraryKind.music;

  @override
  void dispose() {
    unawaited(_device.stopPreview());
    super.dispose();
  }

  Future<void> _toggle(BundledSound sound, AudioPreviewState state) async {
    if (_trying?.id == sound.id && state.isPlaying) {
      setState(() => _trying = null);
      await _device.stopPreview();
      return;
    }
    setState(() => _trying = sound);
    final file = await bundledSoundFile(sound, _cache);
    if (!mounted || _trying?.id != sound.id) return;
    await _device.startPreview(file.path);
  }

  Future<void> _run(Future<void> Function() add) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    await _device.stopPreview();
    try {
      await add();
      if (mounted) context.pop();
    } on _Cancelled {
      // Nothing picked: stay, with nothing to report.
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  EditorController get _controller =>
      ref.read(editorControllerProvider(widget.projectId).notifier);

  int get _playhead => ref.read(playbackControllerProvider).positionUs;

  Future<void> _addBundled(BundledSound sound, String name) => _run(() async {
    final file = await bundledSoundFile(sound, _cache);
    await _controller.addAudioFile(
      file,
      name: name,
      kind: _music ? m.AudioKind.music : m.AudioKind.soundEffect,
      atUs: _playhead,
    );
  });

  Future<void> _pickFile() => _run(() async {
    final dir = Directory(p.join(_cache.path, 'picked'));
    final picked = await _device.pickFile(dir.path);
    if (picked == null) throw const _Cancelled();
    await _controller.addAudioFile(
      File(picked.path),
      name: picked.name,
      kind: m.AudioKind.music,
      atUs: _playhead,
      move: true,
    );
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final preview = ref.watch(_previewStateProvider);
    final state = preview.value ?? AudioPreviewState.stopped;
    final playing = _trying != null && state.isPlaying ? _trying : null;
    final error = _error;

    return Scaffold(
      appBar: AppBar(
        leading: AppIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.back,
          onPressed: () => context.pop(),
        ),
        title: Text(_music ? l10n.musicTitle : l10n.soundEffectsTitle),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_music)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.sm,
                AppSpacing.screen,
                AppSpacing.sm,
              ),
              child: SegmentedControl<_Source>(
                segments: [
                  Segment(_Source.bundled, l10n.tabBundled),
                  Segment(_Source.device, l10n.tabFromDevice),
                ],
                selected: _source,
                onChanged: _busy ? null : (s) => setState(() => _source = s),
              ),
            ),
          if (error != null && failureMessage(l10n, error) != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: ErrorBanner(message: failureMessage(l10n, error)!),
            ),
          if (_busy) const LinearProgress(),
          Expanded(
            child: _source == _Source.device
                ? EmptyState(
                    title: l10n.deviceAudioTitle,
                    message: l10n.deviceAudioMessage,
                    actionLabel: l10n.chooseFile,
                    primaryAction: true,
                    onAction: _pickFile,
                  )
                : _BundledList(
                    sounds: _music ? bundledMusic : bundledEffects,
                    music: _music,
                    playingId: playing?.id,
                    enabled: !_busy,
                    onToggle: (s) => _toggle(s, state),
                    onAdd: _addBundled,
                  ),
          ),
          if (playing != null)
            MiniPlayer(
              caption: l10n.nowPlaying,
              title: _soundName(l10n, playing),
              progress: state.durationUs == 0
                  ? 0
                  : state.positionUs / state.durationUs,
              stopLabel: l10n.stopPreview,
              onStop: () => _toggle(playing, state),
            ),
        ],
      ),
    );
  }
}

/// A cancelled file pick: nothing to add, nothing to report.
final class _Cancelled implements Exception {
  const new();
}

final StreamProvider<AudioPreviewState> _previewStateProvider =
    StreamProvider.autoDispose<AudioPreviewState>(
      (ref) => ref.watch(audioDeviceProvider).previewState,
    );

class _BundledList extends StatelessWidget {
  const new({
    required this.sounds,
    required this.music,
    required this.playingId,
    required this.enabled,
    required this.onToggle,
    required this.onAdd,
  });

  final List<BundledSound> sounds;
  final bool music;
  final String? playingId;
  final bool enabled;
  final ValueChanged<BundledSound> onToggle;
  final void Function(BundledSound sound, String name) onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final groups = <String, List<BundledSound>>{};
    for (final s in sounds) {
      (groups[_groupName(l10n, s)] ??= []).add(s);
    }
    return ListView(
      children: [
        for (final MapEntry(key: heading, value: members)
            in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.lg,
              AppSpacing.screen,
              AppSpacing.xs,
            ),
            child: Semantics(
              header: true,
              child: Text(
                heading,
                style: AppTypography.caption.semibold.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
          for (final sound in members)
            () {
              final name = _soundName(l10n, sound);
              final playing = sound.id == playingId;
              final length = formatDuration(sound.durationUs);
              return ListRow(
                title: name,
                subtitle: music ? '${sound.artist}, $length' : length,
                onTap: enabled ? () => onToggle(sound) : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIconButton(
                      icon: playing ? AppIcons.stop : AppIcons.play,
                      semanticLabel: playing
                          ? l10n.stopPreview
                          : l10n.playPreviewOf(name),
                      onPressed: enabled ? () => onToggle(sound) : null,
                    ),
                    AppTextButton(
                      label: l10n.add,
                      onPressed: enabled ? () => onAdd(sound, name) : null,
                    ),
                  ],
                ),
              );
            }(),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

String _groupName(AppLocalizations l10n, BundledSound s) => switch (s.mood) {
  MusicMood.upbeat => l10n.moodUpbeat,
  MusicMood.calm => l10n.moodCalm,
  MusicMood.cinematic => l10n.moodCinematic,
  MusicMood.playful => l10n.moodPlayful,
  null => switch (s.group) {
    EffectGroup.clicks => l10n.effectGroupClicks,
    EffectGroup.hits => l10n.effectGroupHits,
    EffectGroup.jingles || null => l10n.effectGroupJingles,
  },
};

/// Tracks keep their titles; effects are named in the app's language.
String _soundName(AppLocalizations l10n, BundledSound s) => s.title.isNotEmpty
    ? s.title
    : switch (s.id) {
        'click' => l10n.effectClick,
        'pop' => l10n.effectPop,
        'confirm' => l10n.effectConfirm,
        'glass' => l10n.effectGlass,
        'switch' => l10n.effectSwitch,
        'punch' => l10n.effectPunch,
        'knock' => l10n.effectKnock,
        'clang' => l10n.effectClang,
        'bell' => l10n.effectBell,
        'step' => l10n.effectStep,
        'sax' => l10n.effectSax,
        'steel_drum' => l10n.effectSteelDrum,
        'pizzicato' => l10n.effectPizzicato,
        'chiptune' => l10n.effectChiptune,
        _ => l10n.effectFanfare,
      };
