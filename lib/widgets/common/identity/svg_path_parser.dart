import 'dart:ui';

// Minimal SVG path parser, with no extra dependency.
//
// `flutter_svg` is not part of the Aves-X dependency set, and the logo artwork only
// needs a small subset of the SVG grammar, so the paths are parsed in place:
// `M/m`, `L/l`, `H/h`, `V/v`, `C/c`, `S/s`, `Q/q`, `T/t` and `Z/z`.
//
// Elliptical arcs (`A/a`) are not supported: the Aves-X artwork does not use them,
// and an arc needs its own endpoint-to-center conversion. A path with an arc is
// parsed up to the arc and the rest of the path is skipped instead of throwing,
// so a future artwork edit degrades visibly instead of crashing the UI.
Path parseSvgPath(String source) {
  final path = Path();
  final reader = _PathReader(source);

  var current = Offset.zero;
  var start = Offset.zero;
  Offset? cubicRef;
  Offset? quadRef;
  String? command;

  while (true) {
    reader.skipSeparators();
    if (reader.isDone) break;

    // safety net: an iteration must always consume input, otherwise a malformed
    // path would loop forever
    final before = reader.index;
    final next = reader.readCommand();
    if (next != null) command = next;
    final cmd = command;
    if (cmd == null) break;

    switch (cmd) {
      case 'M':
      case 'm':
        if (!reader.hasNumber()) break;
        var first = true;
        while (reader.hasNumber()) {
          final x = reader.readNumber();
          final y = reader.readNumber();
          if (x == null || y == null) break;
          final point = cmd == 'M' ? Offset(x, y) : current + Offset(x, y);
          if (first) {
            path.moveTo(point.dx, point.dy);
            start = point;
            first = false;
          } else {
            path.lineTo(point.dx, point.dy);
          }
          current = point;
        }
        cubicRef = null;
        quadRef = null;
      case 'L':
      case 'l':
        while (reader.hasNumber()) {
          final x = reader.readNumber();
          final y = reader.readNumber();
          if (x == null || y == null) break;
          final point = cmd == 'L' ? Offset(x, y) : current + Offset(x, y);
          path.lineTo(point.dx, point.dy);
          current = point;
        }
        cubicRef = null;
        quadRef = null;
      case 'H':
      case 'h':
        while (reader.hasNumber()) {
          final x = reader.readNumber();
          if (x == null) break;
          final point = Offset(cmd == 'H' ? x : current.dx + x, current.dy);
          path.lineTo(point.dx, point.dy);
          current = point;
        }
        cubicRef = null;
        quadRef = null;
      case 'V':
      case 'v':
        while (reader.hasNumber()) {
          final y = reader.readNumber();
          if (y == null) break;
          final point = Offset(current.dx, cmd == 'V' ? y : current.dy + y);
          path.lineTo(point.dx, point.dy);
          current = point;
        }
        cubicRef = null;
        quadRef = null;
      case 'C':
      case 'c':
        while (reader.hasNumber()) {
          final x1 = reader.readNumber();
          final y1 = reader.readNumber();
          final x2 = reader.readNumber();
          final y2 = reader.readNumber();
          final x = reader.readNumber();
          final y = reader.readNumber();
          if (x1 == null || y1 == null || x2 == null || y2 == null || x == null || y == null) break;
          final relative = cmd == 'c';
          final c1 = relative ? current + Offset(x1, y1) : Offset(x1, y1);
          final c2 = relative ? current + Offset(x2, y2) : Offset(x2, y2);
          final end = relative ? current + Offset(x, y) : Offset(x, y);
          path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
          current = end;
          cubicRef = c2;
        }
        quadRef = null;
      case 'S':
      case 's':
        while (reader.hasNumber()) {
          final x2 = reader.readNumber();
          final y2 = reader.readNumber();
          final x = reader.readNumber();
          final y = reader.readNumber();
          if (x2 == null || y2 == null || x == null || y == null) break;
          final relative = cmd == 's';
          final smoothRef = cubicRef;
          final c1 = smoothRef == null ? current : current * 2 - smoothRef;
          final c2 = relative ? current + Offset(x2, y2) : Offset(x2, y2);
          final end = relative ? current + Offset(x, y) : Offset(x, y);
          path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
          current = end;
          cubicRef = c2;
        }
        quadRef = null;
      case 'Q':
      case 'q':
        while (reader.hasNumber()) {
          final x1 = reader.readNumber();
          final y1 = reader.readNumber();
          final x = reader.readNumber();
          final y = reader.readNumber();
          if (x1 == null || y1 == null || x == null || y == null) break;
          final relative = cmd == 'q';
          final c = relative ? current + Offset(x1, y1) : Offset(x1, y1);
          final end = relative ? current + Offset(x, y) : Offset(x, y);
          path.quadraticBezierTo(c.dx, c.dy, end.dx, end.dy);
          current = end;
          quadRef = c;
        }
        cubicRef = null;
      case 'T':
      case 't':
        while (reader.hasNumber()) {
          final x = reader.readNumber();
          final y = reader.readNumber();
          if (x == null || y == null) break;
          final relative = cmd == 't';
          final smoothRef = quadRef;
          final c = smoothRef == null ? current : current * 2 - smoothRef;
          final end = relative ? current + Offset(x, y) : Offset(x, y);
          path.quadraticBezierTo(c.dx, c.dy, end.dx, end.dy);
          current = end;
          quadRef = c;
        }
        cubicRef = null;
      case 'Z':
      case 'z':
        path.close();
        current = start;
        cubicRef = null;
        quadRef = null;
      default:
        // Unsupported command (`A/a` and anything newer than SVG 1.1): stop here
        // rather than drawing something wrong.
        return path;
    }

    if (reader.index == before) return path;
  }
  return path;
}

class _PathReader {
  static final _numberPattern = RegExp(r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?');

  _PathReader(this.source);

  final String source;
  int _index = 0;

  bool get isDone => _index >= source.length;

  /// Current offset in [source], used to detect malformed loops.
  int get index => _index;

  void skipSeparators() {
    while (_index < source.length) {
      final code = source.codeUnitAt(_index);
      // space, tab, line feed, carriage return, comma
      if (code == 0x20 || code == 0x09 || code == 0x0A || code == 0x0D || code == 0x2C) {
        _index++;
      } else {
        break;
      }
    }
  }

  bool _isLetterAt(int index) {
    if (index >= source.length) return false;
    final code = source.codeUnitAt(index);
    return (code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A);
  }

  /// Returns the next command letter, or `null` when the next token is a number
  /// (an implicit repetition of the previous command).
  String? readCommand() {
    skipSeparators();
    if (!_isLetterAt(_index)) return null;
    final command = source[_index];
    _index++;
    return command;
  }

  bool hasNumber() {
    skipSeparators();
    if (isDone) return false;
    return !_isLetterAt(_index);
  }

  double? readNumber() {
    skipSeparators();
    final match = _numberPattern.matchAsPrefix(source, _index);
    if (match == null) return null;
    _index = match.end;
    return double.parse(match.group(0)!);
  }
}
