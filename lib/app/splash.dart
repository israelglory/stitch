import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:stitch/design/design.dart';

/// How long the logo stays after the native launch screen hands over,
/// before it fades.
const _hold = Duration(milliseconds: 600);

/// Continues the native launch screen: the same logo, at the same size and
/// place, on the same background. Like the launch screen it follows the
/// system's light or dark mode, whatever theme the app uses, then fades to
/// reveal [child].
///
/// The first frame waits for the logo image, so the native screen stays up
/// until Flutter can draw exactly what it shows.
class SplashOverlay extends StatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay> {
  bool _fading = false;
  bool _gone = false;
  bool _loading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.deferFirstFrame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) return;
    _loading = true;
    // Both, so a mode change during the hold does not flash an empty box.
    unawaited(
      Future.wait([
        for (final dark in [false, true])
          precacheImage(AssetImage(_logo(dark: dark)), context),
      ]).whenComplete(_start),
    );
  }

  void _start() {
    WidgetsBinding.instance.allowFirstFrame();
    _timer = Timer(_hold, () {
      if (!mounted) return;
      // With reduced motion there is no fade to wait for.
      final fades = AppMotion.of(context, AppMotion.slow) > Duration.zero;
      setState(() => fades ? _fading = true : _gone = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static String _logo({required bool dark}) =>
      'assets/splash/logo_${dark ? 'dark' : 'light'}.png';

  @override
  Widget build(BuildContext context) {
    if (_gone) return widget.child;
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final colors = dark ? AppColors.dark : AppColors.light;
    final icons = dark ? Brightness.light : Brightness.dark;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _fading ? 0 : 1,
              duration: AppMotion.of(context, AppMotion.slow),
              curve: AppMotion.curve,
              onEnd: () => setState(() => _gone = true),
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: colors.background,
                  statusBarBrightness: dark
                      ? Brightness.dark
                      : Brightness.light,
                  statusBarIconBrightness: icons,
                  systemNavigationBarColor: colors.background,
                  systemNavigationBarIconBrightness: icons,
                ),
                child: ColoredBox(
                  color: colors.background,
                  child: Center(
                    child: Image.asset(
                      _logo(dark: dark),
                      width: AppSizes.splashLogo,
                      height: AppSizes.splashLogo,
                      excludeFromSemantics: true,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
