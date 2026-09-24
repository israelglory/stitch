import 'dart:math';

/// Creates unique ids for projects, clips, and items.
abstract interface class IdGenerator {
  String next();
}

/// Random 16-character base-36 ids (about 82 bits), unique enough for
/// everything a single device creates.
final class RandomIdGenerator implements IdGenerator {
  new([Random? random]) : _random = random ?? Random.secure();

  final Random _random;
  static const _alphabet = '0123456789abcdefghijklmnopqrstuvwxyz';

  @override
  String next() => String.fromCharCodes([
    for (var i = 0; i < 16; i++)
      _alphabet.codeUnitAt(_random.nextInt(_alphabet.length)),
  ]);
}

/// Predictable ids for tests: prefix0, prefix1, ...
final class SequentialIdGenerator implements IdGenerator {
  new([this.prefix = 'id']);

  final String prefix;
  var _next = 0;

  @override
  String next() => '$prefix${_next++}';
}
