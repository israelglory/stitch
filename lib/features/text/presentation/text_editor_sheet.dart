import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/features/timeline/domain/text_ops.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Opens the text editor for [textId], or for new text at the playhead.
/// The preview stays visible above it; changes show as they are made.
Future<void> showTextEditor(
  BuildContext context,
  String projectId, {
  String? textId,
}) => showAppBottomSheet<void>(
  context: context,
  dimBackground: false,
  builder: (context) => AppBottomSheet(
    title: AppLocalizations.of(context).textEditorTitle,
    onConfirm: () => Navigator.of(context).pop(),
    child: TextEditorPanel(projectId: projectId, textId: textId),
  ),
);

enum _Tab { font, style, animation }

/// Most of the screen height the tab controls take before scrolling.
const _tabHeightFraction = 0.26;

/// Smallest and largest text, as fractions of the canvas height.
const _minSize = 0.025;
const _maxSize = 0.12;

/// Edits a text item: its words, font, style, and animations. The whole
/// session is one undo step. New text exists once something is typed;
/// text emptied here is removed.
class TextEditorPanel extends ConsumerStatefulWidget {
  const new({required this.projectId, this.textId, super.key});

  final String projectId;
  final String? textId;

  @override
  ConsumerState<TextEditorPanel> createState() => _TextEditorPanelState();
}

class _TextEditorPanelState extends ConsumerState<TextEditorPanel> {
  late final EditorController _controller = ref.read(
    editorControllerProvider(widget.projectId).notifier,
  );
  late final TextItem? _existing = widget.textId == null
      ? null
      : ref
            .read(editorControllerProvider(widget.projectId))
            .requireValue
            .timeline
            .textById(widget.textId!);

  /// Where new text starts.
  late final int _atUs = ref.read(playbackControllerProvider).positionUs;

  /// The item's id once it exists.
  late String? _id = _existing?.id;
  late final TextEditingController _text = TextEditingController(
    text: _existing?.text ?? '',
  );
  late TextStyleSpec _style = _existing?.style ?? const TextStyleSpec();
  late TextAnimation _in = _existing?.animationIn ?? TextAnimation.none;
  late TextAnimation _out = _existing?.animationOut ?? TextAnimation.none;
  _Tab _tab = _Tab.font;

  @override
  void initState() {
    super.initState();
    _controller.beginGesture();
    if (_id case final id?) _controller.select(TextSelected(id));
  }

  @override
  void dispose() {
    _controller.endGesture();
    _text.dispose();
    super.dispose();
  }

  /// Applies the panel's state to the snapshot taken on opening.
  void _update() {
    final text = _text.text;
    final existing = _existing;
    if (text.trim().isEmpty) {
      // Nothing to show: no new item, and an emptied one is removed.
      final id = _id;
      _controller.updateGesture(
        (base) => existing == null || id == null ? base : base.deleteText(id),
      );
      if (existing == null) _id = null;
      return;
    }
    final id = _id ??= ref.read(idGeneratorProvider).next();
    TextItem edit(TextItem t) => t.copyWith(
      text: text,
      style: _style,
      animationIn: _in,
      animationOut: _out,
    );
    _controller.updateGesture(
      (base) =>
          (existing == null
                  ? base.addText(id: id, text: text, atUs: _atUs)
                  : base)
              .updateText(id, edit),
    );
    _controller.select(TextSelected(id));
  }

  void _setStyle(TextStyleSpec style) {
    setState(() => _style = style);
    _update();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    // Keep the sheet low, so the text stays in view on the preview; the
    // tab's controls scroll instead.
    final tabHeight = MediaQuery.sizeOf(context).height * _tabHeightFraction;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _text,
              hint: l10n.textHint,
              autofocus: _existing == null,
              maxLines: 2,
              onChanged: (_) => _update(),
              semanticLabel: l10n.textEditorTitle,
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedControl<_Tab>(
              segments: [
                Segment(_Tab.font, l10n.tabFont),
                Segment(_Tab.style, l10n.tabStyle),
                Segment(_Tab.animation, l10n.tabAnimation),
              ],
              selected: _tab,
              onChanged: (tab) {
                // Make room for the tab's controls.
                FocusScope.of(context).unfocus();
                setState(() => _tab = tab);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: tabHeight),
              child: SingleChildScrollView(child: _tabBody()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBody() => switch (_tab) {
    _Tab.font => _FontTab(
      selected: _style.fontId,
      onSelected: (id) => _setStyle(_style.copyWith(fontId: id)),
    ),
    _Tab.style => _StyleTab(style: _style, onChanged: _setStyle),
    _Tab.animation => _AnimationTab(
      animationIn: _in,
      animationOut: _out,
      onIn: (a) {
        setState(() => _in = a);
        _update();
      },
      onOut: (a) {
        setState(() => _out = a);
        _update();
      },
    ),
  };
}

class _FontTab extends StatelessWidget {
  const new({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  static const double _tile = 64;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.md,
    children: [
      for (final font in OverlayFont.values)
        SizedBox(
          width: _tile,
          child: ChoiceTile(
            label: font.displayName,
            selected: OverlayFont.byId(selected) == font,
            onTap: () => onSelected(font.id),
            visual: SizedBox.square(
              dimension: _tile,
              child: Center(child: OverlayFontSample(font)),
            ),
          ),
        ),
    ],
  );
}

class _StyleTab extends StatelessWidget {
  const new({required this.style, required this.onChanged});

  final TextStyleSpec style;
  final ValueChanged<TextStyleSpec> onChanged;

  /// Outline width when one is chosen, as a fraction of the font size.
  static const _strokeWidth = 0.08;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final names = _colorNames(l10n);
    Widget row(String label, List<Widget> swatches) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final s in swatches)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                  child: s,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );

    List<Widget> swatches(
      int? current,
      ValueChanged<int?> pick, {
      bool none = false,
    }) => [
      if (none)
        ColorSwatchButton(
          color: null,
          semanticLabel: l10n.none,
          selected: current == null,
          onTap: () => pick(null),
        ),
      for (final (i, color) in TextPalette.colors.indexed)
        ColorSwatchButton(
          color: color,
          semanticLabel: names[i],
          selected: current == color.toARGB32(),
          onTap: () => pick(color.toARGB32()),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSlider(
          label: l10n.textSize,
          value: style.size.clamp(_minSize, _maxSize),
          min: _minSize,
          max: _maxSize,
          formatValue: (v) => l10n.valuePercent((v / 0.05 * 100).round()),
          onChanged: (v) => onChanged(style.copyWith(size: v)),
        ),
        const SizedBox(height: AppSpacing.md),
        row(
          l10n.textColor,
          swatches(style.color, (c) => onChanged(style.copyWith(color: c!))),
        ),
        row(
          l10n.textStroke,
          swatches(
            style.strokeWidth > 0 ? style.strokeColor : null,
            (c) => onChanged(
              style.copyWith(
                strokeColor: c,
                strokeWidth: c == null ? 0 : _strokeWidth,
              ),
            ),
            none: true,
          ),
        ),
        row(
          l10n.textBox,
          swatches(
            style.backgroundColor,
            (c) => onChanged(style.copyWith(backgroundColor: c)),
            none: true,
          ),
        ),
      ],
    );
  }

  /// Names of [TextPalette.colors], in order, for screen readers.
  static List<String> _colorNames(AppLocalizations l10n) => [
    l10n.colorWhite,
    l10n.colorBlack,
    l10n.colorYellow,
    l10n.colorRed,
    l10n.colorGreen,
    l10n.colorBlue,
    l10n.colorPurple,
    l10n.colorOrange,
  ];
}

class _AnimationTab extends StatelessWidget {
  const new({
    required this.animationIn,
    required this.animationOut,
    required this.onIn,
    required this.onOut,
  });

  final TextAnimation animationIn;
  final TextAnimation animationOut;
  final ValueChanged<TextAnimation> onIn;
  final ValueChanged<TextAnimation> onOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String name(TextAnimation a) => switch (a) {
      TextAnimation.none => l10n.none,
      TextAnimation.fade => l10n.animationFade,
      TextAnimation.slideUp => l10n.animationSlideUp,
      TextAnimation.slideDown => l10n.animationSlideDown,
      TextAnimation.scale => l10n.animationScale,
      TextAnimation.typewriter => l10n.animationTypewriter,
    };
    Widget row(
      String label,
      TextAnimation value,
      ValueChanged<TextAnimation> f,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final a in TextAnimation.values)
              OptionChip(
                label: name(a),
                selected: a == value,
                onTap: () => f(a),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(l10n.animationIn, animationIn, onIn),
        row(l10n.animationOut, animationOut, onOut),
      ],
    );
  }
}
