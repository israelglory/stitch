import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// One side of a [TransitionPreview]: a picture, or a plain [color] while
/// there is none (or it cannot be read).
@immutable
class TransitionFrame {
  const new({required this.color, this.image});

  final Color color;
  final ImageProvider? image;

  @override
  bool operator ==(Object other) =>
      other is TransitionFrame && other.color == color && other.image == image;

  @override
  int get hashCode => Object.hash(color, image);
}

/// A short looping preview of a transition between two frames, drawn by
/// the same shader the video uses (shaders/transitions/, generated from
/// transitions/ in the repo). A null [transition] is a hard cut. Stills
/// are shown instead when the system asks for reduced motion.
class TransitionPreview extends StatefulWidget {
  const new({
    required this.transition,
    required this.from,
    required this.to,
    this.animate = true,
    super.key,
  });

  /// A transition id, or null for none.
  final String? transition;
  final TransitionFrame from;
  final TransitionFrame to;

  /// False shows the midpoint still, for goldens and reduced motion.
  final bool animate;

  /// Shader programs by transition id, loaded once.
  static final _programs = <String, Future<ui.FragmentProgram>>{};

  static Future<ui.FragmentProgram> _program(String id) =>
      _programs.putIfAbsent(
        id,
        () => ui.FragmentProgram.fromAsset('shaders/transitions/$id.frag'),
      );

  @override
  State<TransitionPreview> createState() => _TransitionPreviewState();
}

class _TransitionPreviewState extends State<TransitionPreview>
    with SingleTickerProviderStateMixin {
  // Hold the first frame, transition, hold the second frame.
  static const _cycle = Duration(milliseconds: 1800);
  static const _holdFraction = 0.3;

  late final _controller = AnimationController(vsync: this, duration: _cycle);

  ui.FragmentShader? _shader;
  String? _shaderFor;

  /// The two frames drawn at the preview's size: the shader samples them
  /// edge to edge.
  ui.Image? _fromFrame;
  ui.Image? _toFrame;
  Size? _framesSize;

  /// Decoded source pictures, by side.
  ui.Image? _fromPicture;
  ui.Image? _toPicture;
  final _listeners = <(ImageStream, ImageStreamListener)>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
    _resolve();
  }

  @override
  void didUpdateWidget(TransitionPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
    if (oldWidget.from != widget.from || oldWidget.to != widget.to) {
      _resolve();
    }
    if (oldWidget.transition != widget.transition) _loadShader();
  }

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  void _sync() {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.animate && !reduce) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0.5;
    }
  }

  void _loadShader() {
    final id = widget.transition;
    if (id == null) return;
    unawaited(
      TransitionPreview._program(id).then(
        (program) {
          if (!mounted || widget.transition != id) return;
          setState(() {
            _shader?.dispose();
            _shader = program.fragmentShader();
            _shaderFor = id;
          });
        },
        // An unknown transition (or none built in this test run) shows the
        // outgoing frame, still.
        onError: (Object _) {},
      ),
    );
  }

  void _resolve() {
    for (final (stream, listener) in _listeners) {
      stream.removeListener(listener);
    }
    _listeners.clear();
    _fromPicture = null;
    _toPicture = null;
    _dropFrames();
    final config = createLocalImageConfiguration(context);
    void listen(ImageProvider? provider, void Function(ui.Image) done) {
      if (provider == null) return;
      final stream = provider.resolve(config);
      final listener = ImageStreamListener((info, _) {
        if (!mounted) return;
        setState(() {
          done(info.image);
          _dropFrames();
        });
      }, onError: (_, _) {});
      stream.addListener(listener);
      _listeners.add((stream, listener));
    }

    listen(widget.from.image, (image) => _fromPicture = image);
    listen(widget.to.image, (image) => _toPicture = image);
  }

  void _dropFrames() {
    _fromFrame?.dispose();
    _toFrame?.dispose();
    _fromFrame = null;
    _toFrame = null;
    _framesSize = null;
  }

  /// [frame] drawn to fill [size] (cover), at [pixelRatio].
  static ui.Image _draw(
    TransitionFrame frame,
    ui.Image? picture,
    Size size,
    double pixelRatio,
  ) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(pixelRatio);
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = frame.color);
    if (picture != null) {
      paintImage(canvas: canvas, rect: rect, image: picture, fit: BoxFit.cover);
    }
    return recorder.endRecording().toImageSync(
      (size.width * pixelRatio).ceil(),
      (size.height * pixelRatio).ceil(),
    );
  }

  void _ensureFrames(Size size) {
    if (_framesSize == size && _fromFrame != null) return;
    _dropFrames();
    final ratio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    _fromFrame = _draw(widget.from, _fromPicture, size, ratio);
    _toFrame = _draw(widget.to, _toPicture, size, ratio);
    _framesSize = size;
  }

  @override
  void dispose() {
    for (final (stream, listener) in _listeners) {
      stream.removeListener(listener);
    }
    _controller.dispose();
    _shader?.dispose();
    _dropFrames();
    super.dispose();
  }

  /// Progress of the transition itself (0 to 1) at loop position [t].
  static double _progress(double t) {
    final p = (t - _holdFraction) / (1 - _holdFraction * 2);
    return Curves.easeInOut.transform(p.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, box) {
            final size = box.biggest;
            if (size.isEmpty || !size.isFinite) return const SizedBox.shrink();
            _ensureFrames(size);
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                size: size,
                painter: _TransitionPainter(
                  shader:
                      widget.transition != null &&
                          _shaderFor == widget.transition
                      ? _shader
                      : null,
                  cut: widget.transition == null,
                  from: _fromFrame!,
                  to: _toFrame!,
                  progress: _progress(_controller.value),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TransitionPainter extends CustomPainter {
  const new({
    required this.shader,
    required this.cut,
    required this.from,
    required this.to,
    required this.progress,
  });

  final ui.FragmentShader? shader;
  final bool cut;
  final ui.Image from;
  final ui.Image to;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shader = this.shader;
    if (shader == null) {
      // A cut, or the shader is still loading.
      final image = cut && progress >= 0.5 ? to : from;
      paintImage(canvas: canvas, rect: rect, image: image, fit: BoxFit.fill);
      return;
    }
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, progress)
      ..setFloat(3, size.width / size.height)
      ..setImageSampler(0, from)
      ..setImageSampler(1, to);
    canvas.drawRect(rect, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_TransitionPainter old) =>
      old.progress != progress ||
      old.shader != shader ||
      old.from != from ||
      old.to != to;
}
