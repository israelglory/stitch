import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/app/not_found_screen.dart';
import 'package:stitch/design/gallery/design_gallery_screen.dart';
import 'package:stitch/design/tokens.dart';
import 'package:stitch/features/audio/presentation/audio_library_screen.dart';
import 'package:stitch/features/editor/presentation/editor_screen.dart';
import 'package:stitch/features/editor/presentation/fullscreen_preview.dart';
import 'package:stitch/features/export/domain/export_options.dart';
import 'package:stitch/features/export/presentation/export_screen.dart';
import 'package:stitch/features/media/presentation/media_picker_screen.dart';
import 'package:stitch/features/onboarding/application/onboarding_controller.dart';
import 'package:stitch/features/onboarding/presentation/onboarding_screen.dart';
import 'package:stitch/features/projects/presentation/format_screen.dart';
import 'package:stitch/features/projects/presentation/projects_screen.dart';
import 'package:stitch/features/settings/presentation/licenses_screen.dart';
import 'package:stitch/features/settings/presentation/settings_screen.dart';

part 'router.g.dart';

/// Route paths. Use the helpers for parameterized routes.
abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const projects = '/';
  static const settings = '/settings';
  static const designGallery = '/settings/design-gallery';
  static const licenses = '/settings/licenses';

  static String license(String package) =>
      '$licenses/${Uri.encodeComponent(package)}';
  static const newProject = '/new';
  static const newProjectFormat = '/new/format';
  static const _editor = '/editor/:projectId';

  static String editor(String projectId) =>
      '/editor/${Uri.encodeComponent(projectId)}';

  /// Picker for adding clips; pops with the chosen `List<LibraryItem>`.
  static String editorAdd(String projectId) => '${editor(projectId)}/add';

  /// Picker for replacing a clip; pops with the chosen `LibraryItem`.
  static String editorReplace(String projectId) =>
      '${editor(projectId)}/replace';

  static String editorPreview(String projectId) =>
      '${editor(projectId)}/preview';

  /// Adds music at the playhead.
  static String editorMusic(String projectId) => '${editor(projectId)}/music';

  /// Adds a sound effect at the playhead.
  static String editorEffects(String projectId) =>
      '${editor(projectId)}/effects';

  /// Exports with the `ExportOptions` passed as `extra`.
  static String editorExport(String projectId) => '${editor(projectId)}/export';
}

/// The design gallery is a developer screen, absent from release builds.
const bool _devGalleryEnabled = kDebugMode || kProfileMode;

/// Debug-only start location, for example
/// `--dart-define=START_ROUTE=/settings/design-gallery`.
const _startRoute = String.fromEnvironment('START_ROUTE');

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  // Rebuilding the router would reset navigation, so the redirect reads the
  // onboarding state lazily and this notifier only asks it to re-run.
  final refresh = ValueNotifier<bool>(ref.read(onboardingControllerProvider));
  ref
    ..listen(onboardingControllerProvider, (_, next) => refresh.value = next)
    ..onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: _devGalleryEnabled && _startRoute.isNotEmpty
        ? _startRoute
        : AppRoutes.projects,
    refreshListenable: refresh,
    redirect: (context, state) {
      if (_devGalleryEnabled &&
          state.matchedLocation == AppRoutes.designGallery) {
        return null;
      }
      final completed = ref.read(onboardingControllerProvider);
      final atOnboarding = state.matchedLocation == AppRoutes.onboarding;
      if (!completed && !atOnboarding) return AppRoutes.onboarding;
      if (completed && atOnboarding) return AppRoutes.projects;
      return null;
    },
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.projects,
        builder: (context, state) => const ProjectsScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) =>
                const MediaPickerScreen(mode: PickerMode.create),
            routes: [
              GoRoute(
                path: 'format',
                builder: (context, state) => const FormatScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'licenses',
                builder: (context, state) => const LicensesScreen(),
                routes: [
                  GoRoute(
                    path: ':package',
                    builder: (context, state) => LicenseScreen(
                      package: state.pathParameters['package']!,
                    ),
                  ),
                ],
              ),
              // Developer screen, never reachable in release builds.
              if (_devGalleryEnabled)
                GoRoute(
                  path: 'design-gallery',
                  builder: (context, state) => const DesignGalleryScreen(),
                ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes._editor,
        builder: (context, state) =>
            EditorScreen(projectId: state.pathParameters['projectId']!),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) =>
                const MediaPickerScreen(mode: PickerMode.add),
          ),
          GoRoute(
            path: 'replace',
            builder: (context, state) =>
                const MediaPickerScreen(mode: PickerMode.replace),
          ),
          GoRoute(
            path: 'music',
            builder: (context, state) => AudioLibraryScreen(
              projectId: state.pathParameters['projectId']!,
              kind: AudioLibraryKind.music,
            ),
          ),
          GoRoute(
            path: 'export',
            builder: (context, state) => ExportScreen(
              projectId: state.pathParameters['projectId']!,
              options: state.extra as ExportOptions? ?? const ExportOptions(),
            ),
          ),
          GoRoute(
            path: 'effects',
            builder: (context, state) => AudioLibraryScreen(
              projectId: state.pathParameters['projectId']!,
              kind: AudioLibraryKind.effects,
            ),
          ),
          GoRoute(
            path: 'preview',
            pageBuilder: (context, state) => CustomTransitionPage(
              transitionDuration: AppMotion.standard,
              reverseTransitionDuration: AppMotion.standard,
              child: FullscreenPreview(
                projectId: state.pathParameters['projectId']!,
              ),
              transitionsBuilder: (context, animation, _, child) =>
                  MediaQuery.maybeDisableAnimationsOf(context) ?? false
                  ? child
                  : FadeTransition(opacity: animation, child: child),
            ),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
