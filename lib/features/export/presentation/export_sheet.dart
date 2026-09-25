import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch/core/storage/bytes.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/engine/editor_engine.dart';
import 'package:stitch/engine/engine_provider.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/export/domain/export_options.dart';
import 'package:stitch/features/settings/application/settings_controller.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// What this device can encode; basic until the engine answers.
final FutureProvider<EngineCapabilities> exportCapabilitiesProvider =
    FutureProvider((ref) => ref.watch(editorEngineProvider).capabilities());

/// Opens the export sheet. Returns the options chosen with Export, or
/// null when it was closed.
Future<ExportOptions?> showExportSheet(
  BuildContext context,
  String projectId,
) => showAppBottomSheet<ExportOptions>(
  context: context,
  builder: (context) => AppBottomSheet(
    title: AppLocalizations.of(context).exportTitle,
    child: ExportPanel(projectId: projectId),
  ),
);

class ExportPanel extends ConsumerStatefulWidget {
  const new({required this.projectId, super.key});

  final String projectId;

  @override
  ConsumerState<ExportPanel> createState() => _ExportPanelState();
}

class _ExportPanelState extends ConsumerState<ExportPanel> {
  /// Starts from the defaults in Settings.
  late ExportOptions _options = ref.read(settingsControllerProvider).export;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final caps =
        ref.watch(exportCapabilitiesProvider).value ?? EngineCapabilities.basic;
    final timeline = ref.watch(
      editorControllerProvider(widget.projectId)
          .select((s) => s.value?.timeline),
    );
    final durationUs = ref.watch(
      editorControllerProvider(widget.projectId)
          .select((s) => s.value?.layout.durationUs ?? 0),
    );
    final hasCaptions = timeline?.captionTrack.segments.isNotEmpty ?? false;
    // Only what this device can do, and the captions file only with
    // captions.
    final options = _options.copyWith(
      resolution: !caps.max4k && _options.resolution == ExportResolution.uhd
          ? ExportResolution.fullHd
          : null,
      hevc: _options.hevc && caps.hevc,
      captionsFile: _options.captionsFile && hasCaptions,
    );

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(color: colors.textSecondary),
      ),
    );
    void set(ExportOptions next) => setState(() => _options = next);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          label(l10n.exportResolution),
          SegmentedControl<ExportResolution>(
            segments: [
              Segment(ExportResolution.hd, l10n.resolution720),
              Segment(ExportResolution.fullHd, l10n.resolution1080),
              if (caps.max4k) Segment(ExportResolution.uhd, l10n.resolution4k),
            ],
            selected: options.resolution,
            onChanged: (r) => set(options.copyWith(resolution: r)),
          ),
          const SizedBox(height: AppSpacing.md),
          label(l10n.exportFrameRate),
          SegmentedControl<int>(
            segments: [
              for (final fps in exportFrameRates) Segment(fps, '$fps'),
            ],
            selected: options.frameRate,
            onChanged: (f) => set(options.copyWith(frameRate: f)),
          ),
          const SizedBox(height: AppSpacing.md),
          label(l10n.exportQuality),
          SegmentedControl<ExportQuality>(
            segments: [
              Segment(ExportQuality.smaller, l10n.qualitySmaller),
              Segment(ExportQuality.better, l10n.qualityBetter),
            ],
            selected: options.quality,
            onChanged: (q) => set(options.copyWith(quality: q)),
          ),
          if (caps.hevc) ...[
            const SizedBox(height: AppSpacing.md),
            label(l10n.exportFormat),
            SegmentedControl<bool>(
              segments: [
                Segment(false, l10n.formatH264),
                Segment(true, l10n.formatHevc),
              ],
              selected: options.hevc,
              onChanged: (h) => set(options.copyWith(hevc: h)),
            ),
          ],
          if (hasCaptions) ...[
            const SizedBox(height: AppSpacing.sm),
            CheckRow(
              title: l10n.exportCaptionsFile,
              checked: options.captionsFile,
              inset: false,
              onChanged: (c) => set(options.copyWith(captionsFile: c)),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.exportEstimate(
              formatBytes(estimatedExportBytes(options, durationUs)),
            ),
            textAlign: TextAlign.center,
            style: AppTypography.body.tabular.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: l10n.export,
            onPressed: timeline == null || timeline.videoClips.isEmpty
                ? null
                : () => Navigator.of(context).pop(options),
          ),
        ],
      ),
    );
  }
}
