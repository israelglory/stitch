import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/features/editor/domain/edit_history.dart';

void main() {
  test('undo and redo walk the snapshots', () {
    var h = const EditHistory(0).push(1).push(2);
    expect(h.present, 2);
    h = h.undo();
    expect(h.present, 1);
    h = h.undo();
    expect(h.present, 0);
    expect(h.canUndo, isFalse);
    h = h.redo().redo();
    expect(h.present, 2);
    expect(h.canRedo, isFalse);
  });

  test('a new edit clears redo', () {
    final h = const EditHistory(0).push(1).push(2).undo().push(9);
    expect(h.present, 9);
    expect(h.canRedo, isFalse);
    expect(h.undo().present, 1);
  });

  test('pushing the present is a no-op', () {
    const h = EditHistory('a');
    expect(identical(h.push('a'), h), isTrue);
  });

  test('a gesture pushes once and replaces, undoing in one step', () {
    var h = const EditHistory(0).push(10); // drag start
    h = h.replace(11).replace(12).replace(13); // drag updates
    expect(h.present, 13);
    expect(h.undoDepth, 1);
    expect(h.undo().present, 0);
  });

  test('keeps at most limit steps', () {
    var h = const EditHistory(0, limit: 3);
    for (var i = 1; i <= 10; i++) {
      h = h.push(i);
    }
    expect(h.undoDepth, 3);
    expect(h.undo().undo().undo().present, 7);
  });

  test('undo and redo at the ends return the same history', () {
    const h = EditHistory(0);
    expect(identical(h.undo(), h), isTrue);
    expect(identical(h.redo(), h), isTrue);
  });
}
