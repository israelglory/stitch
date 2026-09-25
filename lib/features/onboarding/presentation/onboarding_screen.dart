import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch/core/storage/bytes.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/design/mocks/editor_mocks.dart';
import 'package:stitch/features/onboarding/application/onboarding_controller.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Three short pages, shown once. Each is one sentence and a mock-up of
/// the real app.
class OnboardingScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  static const _count = 3;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() =>
      ref.read(onboardingControllerProvider.notifier).complete();

  Future<void> _next() async {
    if (_index == _count - 1) return await _finish();
    await _pages.nextPage(
      duration: AppMotion.of(context, AppMotion.slow),
      curve: AppMotion.curve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final pages = <(String, Widget)>[
      (
        l10n.onboardingEditTitle,
        EditorMock(
          splitLabel: l10n.toolSplit,
          speedLabel: l10n.toolSpeed,
          volumeLabel: l10n.toolVolume,
          deleteLabel: l10n.delete,
        ),
      ),
      (
        l10n.onboardingPrivateTitle,
        OnDeviceMock(
          firstProject: l10n.mockProjectOne,
          secondProject: l10n.mockProjectTwo,
          editedLabel: l10n.mockEdited,
          storageTitle: l10n.mockStorageTitle,
          storageValue: formatBytes(l10n, 1200000000),
        ),
      ),
      (
        l10n.onboardingCaptionsTitle,
        CaptionsMock(
          caption: l10n.mockCaption,
          captionStart: l10n.mockCaptionPartOne,
          captionEnd: l10n.mockCaptionPartTwo,
          modelTitle: l10n.mockModelTitle,
          modelValue: l10n.mockModelValue,
        ),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                child: AppTextButton(
                  label: l10n.skip,
                  neutral: true,
                  onPressed: _finish,
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  for (final (title, visual) in pages)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screen,
                      ),
                      child: Column(
                        children: [
                          Expanded(child: Center(child: visual)),
                          const SizedBox(height: AppSpacing.xl),
                          Semantics(
                            header: true,
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              style: AppTypography.display.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PageDots(count: _count, index: _index),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: PrimaryButton(
                label: _index == _count - 1
                    ? l10n.getStarted
                    : l10n.continueAction,
                expand: true,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
