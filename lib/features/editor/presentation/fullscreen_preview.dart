import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/editor/presentation/preview.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// The preview filling the screen, with playback controls only.
class FullscreenPreview extends StatelessWidget {
  const new({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
                child: AppIconButton(
                  icon: AppIcons.exitFullscreen,
                  semanticLabel: l10n.exitFullScreen,
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            Expanded(child: EditorPreview(projectId: projectId)),
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: AppSpacing.sm,
              ),
              child: Row(children: [TimeReadout(), Spacer(), PlayButton()]),
            ),
          ],
        ),
      ),
    );
  }
}
