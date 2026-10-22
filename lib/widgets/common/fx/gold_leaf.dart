import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

// Godly material: burnished gold leaf touched by divine light.
// Brushed metal grain, a halo glowing at the top, rays fanning out of it and a few four-point sparkles.
// Static like the ruby crystal (recorded once per size); `glint` (0..1) optionally sweeps a warm beam of light across it.
class GoldLeafDecoration extends Decoration {
  final double glint;
  final double opacity;

  const GoldLeafDecoration({this.glint = -1, this.opacity = .86});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _GoldLeafPainter(glint, opacity);

  @override
  bool operator ==(Object other) => other is GoldLeafDecoration && other.glint == glint && other.opacity == opacity;

  @override
  int get hashCode => Object.hash(glint, opacity);
}

class _GoldLeafPainter extends BoxPainter {
  final double glint, opacity;

  _GoldLeafPainter(this.glint, this.opacity);

  // antique gold: bright at the top left, bronze at the bottom right (light content stays readable)
  static const _body = [Color(0xFFC9A030), Color(0xFF9A7014), Color(0xFF5E440B), Color(0xFF2E2005)];
  static const _light = Color(0xFFFFF6D5);

  static final Map<(Size, double), ui.Picture> _pictures = {};

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null || size.isEmpty) return;
    if (_pictures.length > 8) {
      for (final p in _pictures.values) {
        p.dispose();
      }
      _pictures.clear();
    }
    final picture = _pictures[(size, opacity)] ??= _record(size, opacity);

    canvas.save();
    canvas.clipRect(offset & size);
    canvas.translate(offset.dx, offset.dy);
    canvas.drawPicture(picture);
    if (glint >= 0) {
      // a warm beam of light sweeping across the gold
      final pos = glint * 1.5 - .25;
      final band = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_light.withValues(alpha: 0), _light.withValues(alpha: .42), _light.withValues(alpha: 0)],
            stops: [(pos - .12).clamp(0.0, 1.0), pos.clamp(0.0, 1.0), (pos + .12).clamp(0.0, 1.0)],
          ).createShader(band),
      );
    }
    canvas.restore();
  }

  static ui.Picture _record(Size size, double opacity) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final local = Offset.zero & size;
    final rnd = Random(21);

    // gold leaf
    canvas.drawRect(
      local,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [for (final c in _body) c.withValues(alpha: opacity)],
          stops: const [0, .3, .68, 1],
        ).createShader(local),
    );

    // brushed grain: thin horizontal strokes, light and dark
    final grain = Paint()..strokeWidth = .6;
    final strokes = min(260, (size.height / 2.6).round());
    for (var i = 0; i < strokes; i++) {
      final y = rnd.nextDouble() * size.height;
      final x0 = rnd.nextDouble() * size.width * .5;
      final x1 = x0 + size.width * (.35 + rnd.nextDouble() * .65);
      grain.color = rnd.nextBool()
          ? Color.fromRGBO(255, 248, 220, .05 + rnd.nextDouble() * .10)
          : Color.fromRGBO(90, 60, 0, .05 + rnd.nextDouble() * .09);
      canvas.drawLine(Offset(x0, y), Offset(x1, y), grain);
    }

    // divine rays fanning out of a point above the top edge
    canvas.save();
    canvas.clipRect(local);
    final origin = Offset(size.width / 2, -size.height * .12);
    final reach = size.longestSide * 1.6;
    const rays = 14;
    const span = pi * .76;
    final ray = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < rays; i++) {
      final a0 = pi * .12 + span * i / rays;
      final a1 = a0 + span / rays * .5;
      ray.color = _light.withValues(alpha: i.isEven ? .14 : .07);
      canvas.drawPath(
        Path()
          ..moveTo(origin.dx, origin.dy)
          ..lineTo(origin.dx + cos(a0) * reach, origin.dy + sin(a0) * reach)
          ..lineTo(origin.dx + cos(a1) * reach, origin.dy + sin(a1) * reach)
          ..close(),
        ray,
      );
    }
    canvas.restore();

    // halo glowing at the top
    canvas.drawRect(
      local,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -1.1),
          radius: .9,
          colors: [_light.withValues(alpha: .4), _light.withValues(alpha: 0)],
        ).createShader(local),
    );

    // pavilion: darker bottom, for depth
    final lower = Rect.fromLTWH(0, size.height * .55, size.width, size.height * .45);
    canvas.drawRect(
      lower,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0x553A2800)],
        ).createShader(lower),
    );

    // sparkles
    final sparkles = (size.width * size.height / 14000).round().clamp(2, 8);
    final star = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < sparkles; i++) {
      final c = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      final r = 2.5 + rnd.nextDouble() * 3.5;
      star.color = _light.withValues(alpha: .16);
      canvas.drawCircle(c, r * 1.7, star);
      star.color = _light.withValues(alpha: .9);
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - r)
          ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
          ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
          ..close(),
        star,
      );
    }

    // bevelled rim: bright on top and left, dark bronze on the bottom
    final rim = Paint()..strokeWidth = 1.2;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), rim..color = _light.withValues(alpha: .8));
    canvas.drawLine(Offset.zero, Offset(0, size.height), rim..color = _light.withValues(alpha: .4));
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), rim..color = const Color(0x66402C00));
    return recorder.endRecording();
  }
}
