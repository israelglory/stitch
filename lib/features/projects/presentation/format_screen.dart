import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stitch/app/failure_messages.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/app/router.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/media/application/library_controller.dart';
import 'package:stitch/features/projects/application/import_controller.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/projects/presentation/import_progress_sheet.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Aspect ratios in the order shown, with their width over height (null
/// for the first clip's own shape).
const aspectChoices = <(AspectPreset, String?, double?)>[
  (AspectPreset.portrait9x16, '9:16', 9 / 16),
  (AspectPreset.landscape16x9, '16:9', 16 / 9),
  (AspectPreset.square, '1:1', 1),
  (AspectPreset.portrait4x5, '4:5', 4 / 5),
  (AspectPreset.original, null, null),
];

/// Label for [preset]: its ratio, or "Original".
String aspectLabel(AppLocalizations l10n, AspectPreset preset) {
  for (final (p, label, _) in aspectChoices) {
    if (p == preset) return label ?? l10n.ratioOriginal;
  }
  return l10n.ratioOriginal;
}

/// Grid of aspect ratio choices, shared by this screen and the editor.
class AspectRatioGrid extends StatelessWidget {
  const new({required this.selected, required this.onSelected, super.key});

  final AspectPreset selected;
  final ValueChanged<AspectPreset> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.lg,
      children: [
        for (final (preset, _, ratio) in aspectChoices)
          ChoiceTile(
            label: aspectLabel(l10n, preset),
            visual: AspectRatioGlyph(ratio: ratio),
            selected: preset == selected,
            onTap: () => onSelected(preset),
          ),
      ],
    );
  }
}

/// Second step of a new project: pick its shape, then create it.
class FormatScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<FormatScreen> createState() => _FormatScreenState();
}

class _FormatScreenState extends ConsumerState<FormatScreen> {
  AspectPreset _preset = AspectPreset.portrait9x16;
  bool _creating = false;

  Future<void> _create() async {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final items = ref.read(mediaSelectionProvider);
    final name = DateFormat.MMMd(locale).format(ref.read(clockProvider)());
    setState(() => _creating = true);
    final id = await runWithImportProgress(
      context,
      () => ref
          .read(importControllerProvider.notifier)
          .createProject(name: name, preset: _preset, items: items),
    );
    if (!mounted) return;
    setState(() => _creating = false);
    // On failure the banner below shows the error; on cancel nothing does.
    if (id != null) context.go(AppRoutes.editor(id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final importState = ref.watch(importControllerProvider);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeader(
            centerTitle: true,
            title: l10n.formatTitle,
            leading: AppIconButton(
              icon: AppIcons.back,
              semanticLabel: l10n.back,
              onPressed: () => context.pop(),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (importState case ImportFailed(:final failure))
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: ErrorBanner(
                        message:
                            failureMessage(l10n, failure) ??
                            l10n.failureGeneric,
                        onRetry: _create,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  AspectRatioGrid(
                    selected: _preset,
                    onSelected: (p) => setState(() => _preset = p),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: PrimaryButton(
                label: l10n.create,
                expand: true,
                isLoading: _creating,
                onPressed: _create,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
