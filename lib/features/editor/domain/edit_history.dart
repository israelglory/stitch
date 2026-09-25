/// Undo and redo over immutable snapshots.
///
/// Each edit pushes a new snapshot. A continuous gesture (dragging a trim
/// handle) pushes once when it starts and then [replace]s the present on
/// every update, so the whole drag undoes in one step.
final class EditHistory<T> {
  const new(this.present, {this.limit = defaultLimit})
    : _past = const [],
      _future = const [];

  const new _(this._past, this.present, this._future, this.limit);

  static const int defaultLimit = 100;

  final List<T> _past;
  final T present;
  final List<T> _future;

  /// Oldest snapshots are dropped past this many undo steps.
  final int limit;

  bool get canUndo => _past.isNotEmpty;
  bool get canRedo => _future.isNotEmpty;
  int get undoDepth => _past.length;

  /// Records [next] as a new step. Clears redo. Pushing the current
  /// snapshot itself (a no-op edit) changes nothing.
  EditHistory<T> push(T next) {
    if (identical(next, present) || next == present) return this;
    final past = [..._past, present];
    return EditHistory._(
      past.length > limit ? past.sublist(past.length - limit) : past,
      next,
      const [],
      limit,
    );
  }

  /// Replaces the present without adding a step, for updates during a
  /// gesture that already pushed. A gesture that comes back to where it
  /// began (a letter typed and deleted) leaves no step behind.
  EditHistory<T> replace(T next) {
    if (identical(next, present)) return this;
    if (_past.isNotEmpty && next == _past.last) {
      return EditHistory._(
        _past.sublist(0, _past.length - 1),
        _past.last,
        _future,
        limit,
      );
    }
    return EditHistory._(_past, next, _future, limit);
  }

  /// Applies [transform] to every snapshot, keeping the undo position.
  /// For changes that must not be undone, such as a rename.
  EditHistory<T> map(T Function(T snapshot) transform) => EditHistory._(
    [for (final s in _past) transform(s)],
    transform(present),
    [for (final s in _future) transform(s)],
    limit,
  );

  EditHistory<T> undo() {
    if (!canUndo) return this;
    return EditHistory._(_past.sublist(0, _past.length - 1), _past.last, [
      present,
      ..._future,
    ], limit);
  }

  EditHistory<T> redo() {
    if (!canRedo) return this;
    return EditHistory._(
      [..._past, present],
      _future.first,
      _future.sublist(1),
      limit,
    );
  }
}
