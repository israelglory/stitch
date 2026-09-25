import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/core/time/time.dart';
import 'package:stitch/design/design.dart';
import 'package:stitch/features/captions/application/caption_rendering.dart';
import 'package:stitch/features/captions/presentation/captions_sheet.dart';
import 'package:stitch/features/editor/application/editor_controller.dart';
import 'package:stitch/features/editor/application/editor_state.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';
import 'package:stitch/features/text/application/text_rendering.dart';
import 'package:stitch/features/timeline/domain/caption_ops.dart';
import 'package:stitch/features/timeline/domain/models.dart';
import 'package:stitch/l10n/generated/app_localizations.dart';

/// Opens the caption editor, on the Style tab when [style], with
/// [captionId] in view. The preview stays visible above it.
Future<void> showCaptionEditor(
  BuildContext context,
  String projectId, {
  String? captionId,
  bool style = false,
}) => showAppBottomSheet<void>(
  context: context,
  dimBackground: false,
  builder: (context) => AppBottomSheet(
    title: AppLocalizations.of(context).captionEditorTitle,
    onConfirm: () => Navigator.of(context).pop(),
    child: CaptionEditorPanel(
      projectId: projectId,
      captionId: captionId,
      style: style,
    ),
  ),
);

enum _Tab { text, style }

/// Most of the screen height the tab body takes before scrolling, so the
/// caption stays in view on the preview.
const _bodyHeightFraction = 0.36;

class CaptionEditorPanel extends ConsumerStatefulWidget {
  const new({
    required this.projectId,
    this.captionId,
    this.style = false,
    super.key,
  });

  final String projectId;
  final String? captionId;
  final bool style;

  @override
  ConsumerState<CaptionEditorPanel> createState() => _CaptionEditorState();
}

class _CaptionEditorState extends ConsumerState<CaptionEditorPanel> {
  late _Tab _tab = widget.style ? _Tab.style : _Tab.text;
  final GlobalKey _focusKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Bring the caption asked for into view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _focusKey.currentContext;
      if (target != null) Scrollable.ensureVisible(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(editorControllerProvider(widget.projectId)).value;
    if (state == null) return const SizedBox.shrink();
    final height = MediaQuery.sizeOf(context).height * _bodyHeightFraction;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedControl<_Tab>(
          segments: [
            Segment(_Tab.text, l10n.tabText),
            Segment(_Tab.style, l10n.tabStyle),
          ],
          selected: _tab,
          onChanged: (tab) {
            FocusScope.of(context).unfocus();
            setState(() => _tab = tab);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: height),
          child: switch (_tab) {
            _Tab.text => _textTab(state),
            _Tab.style => SingleChildScrollView(
              child: _StyleTab(projectId: widget.projectId),
            ),
          },
        ),
      ],
    );
  }

  Widget _textTab(EditorState state) {
    final l10n = AppLocalizations.of(context);
    final segments = state.timeline.sortedCaptions();
    return ListView(
      shrinkWrap: true,
      children: [
        for (final (i, s) in segments.indexed)
          _CaptionRow(
            key: s.id == widget.captionId ? _focusKey : ValueKey(s.id),
            projectId: widget.projectId,
            segment: s,
            startUs: state.layout.startOf(s.anchor),
            nextId: i + 1 < segments.length ? segments[i + 1].id : null,
          ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppTextButton(
            label: l10n.generateAgain,
            onPressed: () {
              Navigator.of(context).pop();
              unawaited(showCaptionsSheet(context, widget.projectId));
            },
          ),
        ),
      ],
    );
  }
}

/// One caption: its time (tap to go there) and its text, edited in
/// place. While editing, it offers split, merge, and delete.
class _CaptionRow extends ConsumerStatefulWidget {
  const new({
    required this.projectId,
    required this.segment,
    required this.startUs,
    required this.nextId,
    super.key,
  });

  final String projectId;
  final CaptionSegment segment;
  final int startUs;
  final String? nextId;

  @override
  ConsumerState<_CaptionRow> createState() => _CaptionRowState();
}

class _CaptionRowState extends ConsumerState<_CaptionRow> {
  late final EditorController _editor = ref.read(
    editorControllerProvider(widget.projectId).notifier,
  );
  late final _text = TextEditingController(text: widget.segment.text);
  final _focus = FocusNode();
  bool _editing = false;

  String get _id => widget.segment.id;

  TextSelection? _selection;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
    // Split depends on where the cursor is.
    _text.addListener(() {
      if (_editing && _text.selection != _selection) {
        setState(() => _selection = _text.selection);
      }
    });
  }

  @override
  void didUpdateWidget(_CaptionRow old) {
    super.didUpdateWidget(old);
    if (!_editing && _text.text != widget.segment.text) {
      _text.text = widget.segment.text;
    }
  }

  @override
  void dispose() {
    if (_editing) {
      _editor.endGesture();
      // Emptied and closed before the field lost focus: gone, as always.
      if (_text.text.trim().isEmpty) {
        final id = _id;
        _editor.apply((t) => t.deleteCaption(id));
      }
    }
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  /// Each visit to the text field is one undo step.
  void _onFocus() {
    if (_focus.hasFocus && !_editing) {
      _editing = true;
      _editor
        ..beginGesture()
        ..select(CaptionSelected(_id));
      setState(() {});
    } else if (!_focus.hasFocus && _editing) {
      _finish();
    }
  }

  void _finish() {
    if (!_editing) return;
    _editing = false;
    _editor.endGesture();
    // Emptied: gone.
    if (_text.text.trim().isEmpty) {
      _editor.apply((t) => t.deleteCaption(_id));
    }
    if (mounted) setState(() {});
  }

  /// Ends editing, then applies [edit] as its own step.
  void _act(Timeline Function(Timeline t) edit) {
    _finish();
    _focus.unfocus();
    _editor.apply(edit);
  }

  /// Words before the cursor; a word the cursor is inside goes after.
  int _wordsBeforeCursor() {
    final text = _text.text;
    final at = _text.selection.baseOffset.clamp(0, text.length);
    // The caption's own words, found in order in its text: this works with
    // and without spaces between words. A word the cursor is inside goes
    // after the split.
    final words = widget.segment.words;
    var cursor = 0;
    for (final (i, w) in words.indexed) {
      final start = text.indexOf(w.text, cursor);
      if (start < 0) break;
      if (at <= start) return i;
      if (at < start + w.text.length) return i;
      cursor = start + w.text.length;
    }
    // Text edited out of step with its words: count words by spaces.
    final before = text.substring(0, at).trim();
    return before.isEmpty ? 0 : before.split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final playhead = ref.watch(
      playbackControllerProvider.select((p) => p.positionUs),
    );
    final timeline = ref.watch(
      editorControllerProvider(widget.projectId)
          .select((s) => s.value?.timeline),
    );
    final current =
        playhead >= widget.startUs &&
        playhead < widget.startUs + widget.segment.durationUs;
    final time = formatPreciseDuration(widget.startUs);
    final splitAt = _editing ? _wordsBeforeCursor() : 0;
    final nextId = widget.nextId;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Pressable(
                semanticLabel: l10n.captionSeek(time),
                onPressed: () => unawaited(
                  ref
                      .read(playbackControllerProvider.notifier)
                      .seek(widget.startUs),
                ),
                child: SizedBox(
                  width: AppSizes.captionTime,
                  height: AppSizes.minTouchTarget,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      time,
                      style: AppTypography.body.tabular.copyWith(
                        color: current ? colors.accent : colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: AppTextField(
                  controller: _text,
                  focusNode: _focus,
                  minLines: 1,
                  maxLines: 3,
                  semanticLabel: l10n.captionText,
                  onChanged: (text) => _editor.updateGesture(
                    (t) => t.editCaptionText(_id, text),
                  ),
                ),
              ),
            ],
          ),
          if (_editing)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSizes.captionTime,
              ),
              child: Wrap(
                spacing: AppSpacing.xs,
                children: [
                  AppTextButton(
                    label: l10n.captionSplit,
                    onPressed:
                        timeline != null &&
                            timeline.canSplitCaption(_id, splitAt)
                        ? () {
                            final newId = ref.read(idGeneratorProvider).next();
                            _act(
                              (t) => t.splitCaption(_id, splitAt, newId: newId),
                            );
                          }
                        : null,
                  ),
                  AppTextButton(
                    label: l10n.captionMerge,
                    onPressed: nextId == null
                        ? null
                        : () => _act((t) => t.mergeCaptions(_id, nextId)),
                  ),
                  AppTextButton(
                    label: l10n.delete,
                    onPressed: () => _act((t) => t.deleteCaption(_id)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Caption style presets and position, for the whole track.
class _StyleTab extends ConsumerWidget {
  const new({required this.projectId});

  final String projectId;

  static const double _tile = 72;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final track = ref.watch(
      editorControllerProvider(projectId)
          .select((s) => s.value?.timeline.captionTrack),
    );
    if (track == null) return const SizedBox.shrink();
    final editor = ref.read(editorControllerProvider(projectId).notifier);
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(color: colors.textSecondary),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.md,
          children: [
            for (final preset in CaptionPreset.values)
              SizedBox(
                width: _tile,
                child: ChoiceTile(
                  label: switch (preset) {
                    CaptionPreset.plain => l10n.captionPresetPlain,
                    CaptionPreset.boxed => l10n.captionPresetBoxed,
                    CaptionPreset.highlightWord => l10n.captionPresetHighlight,
                    CaptionPreset.outline => l10n.captionPresetOutline,
                  },
                  selected: track.preset == preset,
                  onTap: () =>
                      editor.apply((t) => t.setCaptionStyle(preset: preset)),
                  visual: _PresetSample(preset),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        label(l10n.captionPosition),
        SegmentedControl<CaptionPosition>(
          segments: [
            Segment(CaptionPosition.top, l10n.positionTop),
            Segment(CaptionPosition.middle, l10n.positionMiddle),
            Segment(CaptionPosition.bottom, l10n.positionBottom),
          ],
          selected: track.position,
          onChanged: (p) => editor.apply((t) => t.setCaptionStyle(position: p)),
        ),
      ],
    );
  }
}

/// "Aa" in a preset's look, on black like a video frame.
class _PresetSample extends StatelessWidget {
  const new(this.preset);

  final CaptionPreset preset;

  /// A square canvas this size gives the sample a readable size.
  static const _canvas = 400;

  @override
  Widget build(BuildContext context) {
    final style = captionStyle(
      preset,
      canvasWidth: _canvas,
      canvasHeight: _canvas,
    );
    final spec = overlaySpecFor(
      'Aa',
      style,
      canvasWidth: _canvas.toDouble(),
      canvasHeight: _canvas.toDouble(),
      highlight: preset == CaptionPreset.highlightWord
          ? TextHighlight(start: 0, end: 1, color: captionHighlightColor)
          : null,
    );
    return ExcludeSemantics(
      child: ColoredBox(
        color: TextPalette.colors[1],
        child: SizedBox.square(
          dimension: _StyleTab._tile,
          child: CustomPaint(painter: _SamplePainter(spec)),
        ),
      ),
    );
  }
}

class _SamplePainter extends CustomPainter {
  const new(this.spec);

  final OverlayTextSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = OverlayTextLayout(spec);
    final scale = size.width / _PresetSample._canvas * 4;
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(scale)
      ..translate(-layout.size.width / 2, -layout.size.height / 2);
    layout.paint(canvas, Offset.zero);
    canvas.restore();
    layout.dispose();
  }

  @override
  bool shouldRepaint(_SamplePainter old) => false;
}
