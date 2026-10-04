import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/core/time/time.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/audio/application/sound_library.dart';
import 'package:stitch/features/audio/data/sound_library.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// The online library's music or sound effects: search, categories, and
/// each sound with its preview and download, then Add once it is here.
class OnlineSoundList extends ConsumerStatefulWidget {
  const new({
    required this.kind,
    required this.playingId,
    required this.enabled,
    required this.onToggle,
    required this.onAdd,
    super.key,
  });

  final LibraryKind kind;

  /// The sound being tried, if any.
  final String? playingId;
  final bool enabled;
  final ValueChanged<LibrarySound> onToggle;
  final void Function(LibrarySound sound) onAdd;

  @override
  ConsumerState<OnlineSoundList> createState() => _OnlineSoundListState();
}

class _OnlineSoundListState extends ConsumerState<OnlineSoundList> {
  final _search = TextEditingController();
  String? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final library = ref.watch(soundLibraryProvider);
    if (!library.enabled) {
      return EmptyState(
        title: l10n.onlineSoundsOffTitle,
        message: l10n.onlineSoundsOffMessage,
      );
    }
    final catalog = library.catalog;
    if (catalog == null) {
      return Center(
        child: ProgressRing(semanticLabel: l10n.onlineSoundsLoading),
      );
    }
    final all = [
      for (final s in catalog.sounds)
        if (s.kind == widget.kind) s,
    ];
    final categories = <String>[
      for (final s in all)
        if (!all.takeWhile((x) => x != s).any((x) => x.category == s.category))
          s.category,
    ];
    final query = _search.text.trim().toLowerCase();
    final shown = [
      for (final s in all)
        if ((_category == null || s.category == _category) &&
            (query.isEmpty ||
                s.title.toLowerCase().contains(query) ||
                s.artist.toLowerCase().contains(query) ||
                libraryCategoryName(
                  l10n,
                  s.category,
                ).toLowerCase().contains(query)))
          s,
    ];

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.xs,
            AppSpacing.screen,
            AppSpacing.sm,
          ),
          child: AppTextField(
            controller: _search,
            hint: l10n.searchSounds,
            semanticLabel: l10n.searchSounds,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Row(
            children: [
              for (final c in [null, ...categories])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                  child: OptionChip(
                    label: c == null
                        ? l10n.filterAll
                        : libraryCategoryName(l10n, c),
                    selected: c == _category,
                    onTap: () => setState(() => _category = c),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              l10n.noSoundsFound,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
        for (final sound in shown)
          _SoundRow(
            sound: sound,
            status: library.statusOf(sound),
            playing: sound.id == widget.playingId,
            enabled: widget.enabled,
            onToggle: () => widget.onToggle(sound),
            onAdd: () => widget.onAdd(sound),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          child: Column(
            children: [
              Text(
                l10n.soundLibraryNote,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              AppTextButton(
                label: l10n.soundSourcesLink,
                onPressed: () => unawaited(_showSources(context, all)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SoundRow extends ConsumerWidget {
  const new({
    required this.sound,
    required this.status,
    required this.playing,
    required this.enabled,
    required this.onToggle,
    required this.onAdd,
  });

  final LibrarySound sound;
  final LibrarySoundStatus status;
  final bool playing;
  final bool enabled;
  final VoidCallback onToggle;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final library = ref.read(soundLibraryProvider.notifier);
    final length = formatDuration(sound.durationUs);
    final music = sound.kind == LibraryKind.music;
    final action = switch (status) {
      Downloaded() => AppTextButton(
        label: l10n.add,
        onPressed: enabled ? onAdd : null,
      ),
      Downloading(:final progress) => Semantics(
        button: true,
        label: l10n.downloadingSoundLabel(
          sound.title,
          (progress * 100).floor(),
        ),
        onTap: () => unawaited(library.cancel(sound)),
        child: ExcludeSemantics(
          child: Pressable(
            onPressed: () => unawaited(library.cancel(sound)),
            child: Center(
              child: ProgressRing(value: progress == 0 ? null : progress),
            ),
          ),
        ),
      ),
      NotDownloaded() || DownloadFailed() => AppIconButton(
        icon: AppIcons.download,
        semanticLabel: l10n.downloadSoundLabel(sound.title),
        onPressed: enabled ? () => library.download(sound) : null,
      ),
    };
    return ListRow(
      title: sound.title,
      subtitle: status is DownloadFailed
          ? l10n.soundDownloadFailed
          : music
          ? '${sound.artist}, $length'
          : length,
      onTap: enabled ? onToggle : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconButton(
            icon: playing ? AppIcons.stop : AppIcons.play,
            semanticLabel: playing
                ? l10n.stopPreview
                : l10n.playPreviewOf(sound.title),
            onPressed: enabled ? onToggle : null,
          ),
          SizedBox(
            width: AppSizes.minTouchTarget + AppSpacing.md,
            child: action,
          ),
        ],
      ),
    );
  }
}

/// Where each sound comes from, opening its page on tap.
Future<void> _showSources(BuildContext context, List<LibrarySound> sounds) =>
    showAppBottomSheet<void>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final l10n = AppLocalizations.of(context);
          return AppBottomSheet(
            title: l10n.soundCreditsTitle,
            child: ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    l10n.soundCreditsIntro,
                    style: AppTypography.body.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
                for (final s in sounds)
                  ListRow(
                    title: s.title,
                    subtitle: '${s.artist}, ${Uri.parse(s.source).host}',
                    inset: false,
                    onTap: () => unawaited(
                      ref.read(systemServicesProvider).openUrl(s.source),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );

/// The name of a library category (a music mood or an effect group).
String libraryCategoryName(AppLocalizations l10n, String category) =>
    switch (category) {
      'upbeat' => l10n.moodUpbeat,
      'calm' => l10n.moodCalm,
      'cinematic' => l10n.moodCinematic,
      'playful' => l10n.moodPlayful,
      'beats' => l10n.libraryMoodBeats,
      'seasonal' => l10n.libraryMoodSeasonal,
      'ui' => l10n.libraryGroupUi,
      'impact' => l10n.libraryGroupImpact,
      'game' => l10n.libraryGroupGame,
      'jingle' => l10n.effectGroupJingles,
      'voice' => l10n.libraryGroupVoice,
      'everyday' => l10n.libraryGroupEveryday,
      'whoosh' => l10n.libraryGroupWhoosh,
      'nature' => l10n.libraryGroupNature,
      'crowd' => l10n.libraryGroupCrowd,
      'funny' => l10n.libraryGroupFunny,
      // A category from a newer catalog: its id, readable.
      _ => category[0].toUpperCase() + category.substring(1),
    };
