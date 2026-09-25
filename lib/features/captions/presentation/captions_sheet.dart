import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch/app/failure_messages.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/captions/application/caption_generation.dart';
import 'package:stitch/features/captions/application/caption_providers.dart';
import 'package:stitch/features/captions/data/caption_models.dart';
import 'package:stitch/features/captions/domain/caption_languages.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/timeline/domain/models.dart' as m;
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Opens the auto captions sheet: language, sound, and model, then
/// Generate. Generating goes on after the sheet closes.
Future<void> showCaptionsSheet(BuildContext context, String projectId) =>
    showAppBottomSheet<void>(
      context: context,
      dimBackground: false,
      builder: (context) => AppBottomSheet(
        title: AppLocalizations.of(context).captionsTitle,
        child: CaptionsPanel(projectId: projectId),
      ),
    );

class CaptionsPanel extends ConsumerStatefulWidget {
  const new({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<CaptionsPanel> createState() => _CaptionsPanelState();
}

class _CaptionsPanelState extends ConsumerState<CaptionsPanel> {
  /// Null detects the language.
  String? _language;
  CaptionSource _source = CaptionSource.video;
  late CaptionModel _model;

  /// Generate was pressed while the model downloads: start when it is in.
  bool _waitingForModel = false;

  @override
  void initState() {
    super.initState();
    final models = ref.read(captionModelsProvider);
    // The more accurate model when it is already here.
    _model = models[CaptionModel.base] is ModelReady
        ? CaptionModel.base
        : CaptionModel.tiny;
    _language = ref
        .read(editorControllerProvider(widget.projectId))
        .value
        ?.timeline
        .captionTrack
        .language;
    if (captionLanguageName(_language) == null) _language = null;
  }

  Future<void> _generate() async {
    final status = ref.read(captionModelsProvider)[_model];
    if (status is! ModelReady) {
      setState(() => _waitingForModel = true);
      await ref.read(captionModelsProvider.notifier).download(_model);
      if (!mounted || !_waitingForModel) return;
      setState(() => _waitingForModel = false);
      if (ref.read(captionModelsProvider)[_model] is! ModelReady) return;
    }
    unawaited(
      ref
          .read(captionGenerationProvider(widget.projectId).notifier)
          .start(model: _model, source: _source, language: _language),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickLanguage() async {
    final picked = await showAppBottomSheet<(String?,)>(
      context: context,
      builder: (context) => AppBottomSheet(
        title: AppLocalizations.of(context).captionLanguage,
        child: _LanguageList(selected: _language),
      ),
    );
    if (picked != null && mounted) setState(() => _language = picked.$1);
  }

  static String _megabytes(int bytes) =>
      '${(bytes / (1000 * 1000)).round()} MB';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final recognizer = ref.watch(speechRecognizerProvider);
    if (!recognizer.isAvailable) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Text(
          l10n.captionsUnavailable,
          style: AppTypography.body.copyWith(color: colors.textSecondary),
        ),
      );
    }
    final timeline = ref.watch(
      editorControllerProvider(widget.projectId)
          .select((s) => s.value?.timeline),
    );
    final status = ref.watch(captionModelsProvider)[_model]!;
    final hasVoiceover =
        timeline?.audioItems.any((a) => a.kind == m.AudioKind.voiceover) ??
        false;
    final hasCaptions = timeline?.captionTrack.segments.isNotEmpty ?? false;
    final source = !hasVoiceover && _source == CaptionSource.voiceover
        ? CaptionSource.video
        : _source;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(color: colors.textSecondary),
      ),
    );

    final downloading = status is ModelDownloading;
    // Scrolls on small screens with large text.
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListRow(
            title: l10n.captionLanguage,
            value: captionLanguageName(_language) ?? l10n.captionLanguageAuto,
            showChevron: true,
            inset: false,
            onTap: _pickLanguage,
          ),
          const SizedBox(height: AppSpacing.md),
          label(l10n.captionSource),
          SegmentedControl<CaptionSource>(
            segments: [
              Segment(CaptionSource.video, l10n.captionSourceVideo),
              if (hasVoiceover)
                Segment(CaptionSource.voiceover, l10n.captionSourceVoiceover),
              Segment(CaptionSource.all, l10n.captionSourceAll),
            ],
            selected: source,
            onChanged: (s) => setState(() => _source = s),
          ),
          const SizedBox(height: AppSpacing.md),
          label(l10n.captionModel),
          SegmentedControl<CaptionModel>(
            segments: [
              Segment(CaptionModel.tiny, l10n.captionModelTiny),
              Segment(CaptionModel.base, l10n.captionModelBase),
            ],
            selected: _model,
            onChanged: downloading || _waitingForModel
                ? null
                : (m) => setState(() => _model = m),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ModelRow(
            status: status,
            size: _megabytes(_model.bytes),
            onCancel: () {
              setState(() => _waitingForModel = false);
              unawaited(
                ref.read(captionModelsProvider.notifier).cancel(_model),
              );
            },
          ),
          if (hasCaptions) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.captionsReplaceNote,
              style: AppTypography.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: l10n.generateCaptions,
            onPressed: downloading || _waitingForModel || timeline == null
                ? null
                : () => unawaited(_generate()),
          ),
        ],
      ),
    );
  }
}

/// The chosen model: downloaded, its size to download, or its download.
class _ModelRow extends StatelessWidget {
  const new({required this.status, required this.size, required this.onCancel});

  final ModelStatus status;
  final String size;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final note = AppTypography.caption.copyWith(color: colors.textSecondary);
    return switch (status) {
      ModelReady() => Row(
        children: [
          Icon(
            AppIcons.check,
            size: AppSizes.inlineIcon,
            color: colors.success,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(child: Text(l10n.captionModelReady, style: note)),
        ],
      ),
      ModelMissing() => Text(l10n.captionModelDownload(size), style: note),
      ModelFailed(:final failure) => ErrorBanner(
        message: failureMessage(l10n, failure) ?? l10n.failureDownload,
      ),
      // The button goes under the bar, so large text still fits.
      ModelDownloading(:final fraction) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.captionModelDownloading((fraction * 100).floor()),
            style: note.tabular,
          ),
          const SizedBox(height: AppSpacing.xs),
          LinearProgress(value: fraction),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AppTextButton(
              label: l10n.cancelDownload,
              onPressed: onCancel,
            ),
          ),
        ],
      ),
    };
  }
}

/// Auto detect, then every offered language; pops the choice.
class _LanguageList extends StatelessWidget {
  const new({required this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    Widget row(String? code, String name) => ListRow(
      title: name,
      trailing: code == selected
          ? Icon(AppIcons.check, color: colors.accent)
          : null,
      onTap: () => Navigator.of(context).pop((code,)),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.6,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          row(null, l10n.captionLanguageAuto),
          for (final l in captionLanguages) row(l.code, l.name),
        ],
      ),
    );
  }
}
