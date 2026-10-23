import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

// Night Demon material: black volcanic glass (obsidian) with glowing violet cracks.
// Large, sharp conchoidal shards catch a cold violet light, and purple hellfire leaks through fractures.
// The glass and the cracks are recorded once per size and replayed, so the pulse of the cracks only costs
// one translucent layer per frame; `pulse` (0..1) makes the cracks flare up and calm down, -1 is the resting glow.
class DemonGlassDecoration extends Decoration {
  final double pulse;
  final double opacity;

  const DemonGlassDecoration({this.pulse = -1, this.opacity = .9});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _DemonGlassPainter(pulse, opacity);

  @override
  bool operator ==(Object other) => other is DemonGlassDecoration && other.pulse == pulse && other.opacity == opacity;

  @override
  int get hashCode => Object.hash(pulse, opacity);
}

class _Crack {
  final Offset start;
  final double heading;
  final int steps;
  final int depth;

  const _Crack(this.start, this.heading, this.steps, this.depth);
}

class _DemonArt {
  final ui.Picture glass;
  final ui.Picture cracks;

  const _DemonArt(this.glass, this.cracks);

  void dispose() {
    glass.dispose();
    cracks.dispose();
  }
}

class _DemonGlassPainter extends BoxPainter {
  final double pulse, opacity;

  _DemonGlassPainter(this.pulse, this.opacity);

  static const _cell = 64.0;
  static const _body = [Color(0xFF1B0732), Color(0xFF0F0420), Color(0xFF07010F), Color(0xFF000000)];
  static const _violet = Color(0xFFB388FF);

  static final Map<(Size, double), _DemonArt> _art = {};

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null || size.isEmpty) return;
    final key = (size, opacity);
    final cached = _art.remove(key);
    final art = cached ?? _DemonArt(_recordGlass(size, opacity), _recordCracks(size, opacity));
    _art[key] = art;
    // Each entry owns two ui.Pictures, so the cache stays smaller than the
    // ruby cache and disposes both recordings as soon as an entry is evicted.
    while (_art.length > 8) {
      _art.remove(_art.keys.first)?.dispose();
    }

    canvas.save();
    canvas.clipRect(offset & size);
    canvas.translate(offset.dx, offset.dy);
    canvas.drawPicture(art.glass);
    if (pulse < 0) {
      canvas.drawPicture(art.cracks);
    } else {
      // the fire inside the cracks flares up and calms down
      final glow = .45 + .55 * sin(pi * pulse.clamp(0.0, 1.0));
      canvas.saveLayer(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, glow));
      canvas.drawPicture(art.cracks);
      canvas.restore();
    }
    canvas.restore();
  }

  static ui.Picture _recordGlass(Size size, double opacity) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final local = Offset.zero & size;

    // black glass, slightly lighter at the top left
    canvas.drawRect(
      local,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [for (final c in _body) c.withValues(alpha: opacity)],
          stops: const [0, .4, .75, 1],
        ).createShader(local),
    );

    // sharp shards: a jittered lattice, with a stronger jitter than the ruby cut
    final rnd = Random(66);
    final cols = max(1, (size.width / _cell).round());
    final rows = max(1, (size.height / _cell).round());
    final cw = size.width / cols;
    final ch = size.height / rows;
    final pts = List.generate(rows + 1, (r) {
      return List.generate(cols + 1, (c) {
        var x = c * cw, y = r * ch;
        if (c > 0 && c < cols) x += (rnd.nextDouble() - .5) * cw * .9;
        if (r > 0 && r < rows) y += (rnd.nextDouble() - .5) * ch * .9;
        return Offset(x, y);
      });
    });
    final fill = Paint()..style = PaintingStyle.fill;
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .6
      ..strokeJoin = StrokeJoin.round
      ..color = _violet.withValues(alpha: .16);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final a = pts[r][c], b = pts[r][c + 1], d = pts[r + 1][c], e = pts[r + 1][c + 1];
        final flip = rnd.nextBool();
        final triangles = flip ? [[a, b, e], [a, e, d]] : [[a, b, d], [b, e, d]];
        for (final t in triangles) {
          final tilt = rnd.nextDouble() * 2 - 1;
          if (tilt > .3) {
            // facing the cold light
            fill.color = _violet.withValues(alpha: ((tilt - .3) * .2).clamp(0.0, .16));
          } else if (tilt < -.2) {
            // fallen into shadow
            fill.color = const Color(0xFF000000).withValues(alpha: (-tilt * .5).clamp(0.0, .45));
          } else {
            continue;
          }
          final path = Path()
            ..moveTo(t[0].dx, t[0].dy)
            ..lineTo(t[1].dx, t[1].dy)
            ..lineTo(t[2].dx, t[2].dy)
            ..close();
          canvas.drawPath(path, fill);
          canvas.drawPath(path, edge);
        }
      }
    }

    // glassy reflection near the top
    final sheen = Rect.fromLTWH(0, 0, size.width, size.height * .4);
    canvas.drawRect(
      sheen,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_violet.withValues(alpha: .16), _violet.withValues(alpha: 0)],
        ).createShader(sheen),
    );
    // rim: cold light on top and left, void on the bottom
    final rim = Paint()..strokeWidth = 1.2;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), rim..color = _violet.withValues(alpha: .5));
    canvas.drawLine(Offset.zero, Offset(0, size.height), rim..color = _violet.withValues(alpha: .28));
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), rim..color = const Color(0x99000000));
    return recorder.endRecording();
  }

  static ui.Picture _recordCracks(Size size, double opacity) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // translucent surfaces get dimmer cracks, so that the content behind stays readable
    final k = (opacity * 1.6).clamp(.35, 1.0);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF9B5DE5).withValues(alpha: .5 * k)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFE9D5FF).withValues(alpha: .9 * k);
    for (final path in _buildCracks(size)) {
      canvas.drawPath(path, glow);
      canvas.drawPath(path, core);
    }
    return recorder.endRecording();
  }

  // fractures spreading from the edges towards the center, branching as they go
  static List<Path> _buildCracks(Size size) {
    final rnd = Random(13);
    final bounds = (Offset.zero & size).inflate(8);
    final center = size.center(Offset.zero);
    final seeds = (size.width * size.height / 16000).round().clamp(2, 7);
    final paths = <Path>[];
    final queue = <_Crack>[];
    for (var i = 0; i < seeds; i++) {
      final side = rnd.nextInt(4);
      final start = side == 0
          ? Offset(rnd.nextDouble() * size.width, 0)
          : side == 1
          ? Offset(size.width, rnd.nextDouble() * size.height)
          : side == 2
          ? Offset(rnd.nextDouble() * size.width, size.height)
          : Offset(0, rnd.nextDouble() * size.height);
      final heading = atan2(center.dy - start.dy, center.dx - start.dx) + (rnd.nextDouble() - .5) * 1.2;
      queue.add(_Crack(start, heading, 12 + rnd.nextInt(8), 0));
    }
    while (queue.isNotEmpty && paths.length < 36) {
      final crack = queue.removeLast();
      final path = Path()..moveTo(crack.start.dx, crack.start.dy);
      var pos = crack.start;
      var heading = crack.heading;
      for (var step = 0; step < crack.steps; step++) {
        heading += (rnd.nextDouble() - .5) * .9;
        pos = pos + Offset(cos(heading), sin(heading)) * (8 + rnd.nextDouble() * 14);
        path.lineTo(pos.dx, pos.dy);
        if (!bounds.contains(pos)) break;
        if (crack.depth < 2 && rnd.nextDouble() < .16) {
          final turn = rnd.nextBool() ? 1.0 : -1.0;
          queue.add(_Crack(pos, heading + turn * (.5 + rnd.nextDouble() * .6), ((crack.steps - step) * .6).round(), crack.depth + 1));
        }
      }
      paths.add(path);
    }
    return paths;
  }
}
