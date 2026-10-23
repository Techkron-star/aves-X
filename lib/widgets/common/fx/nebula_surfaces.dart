import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

// Surfaces of the Nebula materials that paint a whole scene instead of a crystal:
// - imperial: riveted gunmetal plate with a brass frame.
// - solarFlare: the surface of a star, with granulation, sunspots and flare arcs.
// - abyssal: deep water with caustics, bubbles and bioluminescent specks.
// - sakura: ink black washi with a blossoming branch and fallen petals.
// Like the other glass decorations, each one is recorded once per (size, opacity) and replayed.
enum NebulaSurfaceArt { imperial, solarFlare, abyssal, sakura }

class NebulaSurfaceDecoration extends Decoration {
  final NebulaSurfaceArt art;
  final double opacity;

  const NebulaSurfaceDecoration(this.art, {this.opacity = .86});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _SurfacePainter(art, opacity);

  @override
  bool operator ==(Object other) => other is NebulaSurfaceDecoration && other.art == art && other.opacity == opacity;

  @override
  int get hashCode => Object.hash(art, opacity);
}

class _SurfacePainter extends BoxPainter {
  final NebulaSurfaceArt art;
  final double opacity;

  _SurfacePainter(this.art, this.opacity);

  static final Map<(NebulaSurfaceArt, Size, double), ui.Picture> _pictures = {};

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null || size.isEmpty) return;
    if (_pictures.length > 16) {
      for (final p in _pictures.values) {
        p.dispose();
      }
      _pictures.clear();
    }
    final picture = _pictures[(art, size, opacity)] ??= _record(art, size, opacity);
    canvas.save();
    canvas.clipRect(offset & size);
    canvas.translate(offset.dx, offset.dy);
    canvas.drawPicture(picture);
    canvas.restore();
  }

  static ui.Picture _record(NebulaSurfaceArt art, Size size, double opacity) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    switch (art) {
      case NebulaSurfaceArt.imperial:
        _imperial(canvas, size, opacity);
      case NebulaSurfaceArt.solarFlare:
        _solar(canvas, size, opacity);
      case NebulaSurfaceArt.abyssal:
        _abyssal(canvas, size, opacity);
      case NebulaSurfaceArt.sakura:
        _sakura(canvas, size, opacity);
    }
    return recorder.endRecording();
  }

  static void _fill(Canvas canvas, Size size, List<Color> colors, List<double> stops, double opacity,
      {Alignment begin = Alignment.topLeft, Alignment end = Alignment.bottomRight}) {
    final local = Offset.zero & size;
    canvas.drawRect(
      local,
      Paint()
        ..shader = LinearGradient(
          begin: begin,
          end: end,
          colors: [for (final c in colors) c.withValues(alpha: opacity)],
          stops: stops,
        ).createShader(local),
    );
  }

  // ---------------------------------------------------------------- imperial

  static void _imperial(Canvas canvas, Size size, double opacity) {
    const brass = Color(0xFFD4A72A);
    const bone = Color(0xFFC9B896);
    final rnd = Random(40);
    _fill(canvas, size, const [Color(0xFF3A3A3C), Color(0xFF262628), Color(0xFF171718), Color(0xFF0B0B0C)], const [0, .35, .72, 1], opacity);

    // scratched, brushed steel
    final scratch = Paint()..strokeWidth = .6;
    final count = min(220, (size.height / 2.4).round());
    for (var i = 0; i < count; i++) {
      final y = rnd.nextDouble() * size.height;
      final x0 = rnd.nextDouble() * size.width * .6;
      final x1 = x0 + size.width * (.2 + rnd.nextDouble() * .6);
      scratch.color = rnd.nextBool()
          ? Color.fromRGBO(255, 255, 255, .03 + rnd.nextDouble() * .06)
          : Color.fromRGBO(0, 0, 0, .06 + rnd.nextDouble() * .12);
      canvas.drawLine(Offset(x0, y), Offset(x1, y + (rnd.nextDouble() - .5) * 3), scratch);
    }

    // weathering stains running down from the rivets
    final inset = min(11.0, min(size.width, size.height) / 5);
    final spacing = 46.0;
    final rivets = <Offset>[];
    for (var x = inset; x <= size.width - inset + 1; x += max(spacing, (size.width - 2 * inset) / max(1, ((size.width - 2 * inset) / spacing).floor()))) {
      rivets..add(Offset(x, inset))..add(Offset(x, size.height - inset));
    }
    for (var y = inset + spacing; y < size.height - inset - 8; y += spacing) {
      rivets..add(Offset(inset, y))..add(Offset(size.width - inset, y));
    }
    final stain = Paint()..strokeWidth = 1.6..strokeCap = StrokeCap.round;
    for (final r in rivets) {
      if (rnd.nextDouble() < .35) {
        stain.color = Color.fromRGBO(70, 40, 10, .18);
        canvas.drawLine(r + const Offset(0, 3), r + Offset(0, 3 + 6 + rnd.nextDouble() * 12), stain);
      }
    }

    // gilded double frame
    final frame = Rect.fromLTWH(inset * .45, inset * .45, size.width - inset * .9, size.height - inset * .9);
    canvas.drawRect(frame, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.1..color = brass.withValues(alpha: .55));
    canvas.drawRect(frame.deflate(2.5), Paint()..style = PaintingStyle.stroke..strokeWidth = .6..color = bone.withValues(alpha: .28));

    // brass rivets with a specular dot
    for (final r in rivets) {
      canvas.drawCircle(r + const Offset(.8, 1.2), 3.1, Paint()..color = const Color(0x88000000));
      canvas.drawCircle(
        r,
        3,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.4, -.4),
            colors: [Color(0xFFFFE9A3), Color(0xFFB8860B), Color(0xFF5E440B)],
          ).createShader(Rect.fromCircle(center: r, radius: 3)),
      );
    }

    // corner plates
    final plate = Paint()..color = brass.withValues(alpha: .5)..style = PaintingStyle.stroke..strokeWidth = 1.6;
    final l = min(20.0, min(size.width, size.height) / 3);
    for (final (corner, dx, dy) in [(Offset.zero, 1.0, 1.0), (Offset(size.width, 0), -1.0, 1.0), (Offset(0, size.height), 1.0, -1.0), (Offset(size.width, size.height), -1.0, -1.0)]) {
      canvas.drawPath(
        Path()
          ..moveTo(corner.dx + dx * l, corner.dy + dy * 1.5)
          ..lineTo(corner.dx + dx * 1.5, corner.dy + dy * 1.5)
          ..lineTo(corner.dx + dx * 1.5, corner.dy + dy * l),
        plate,
      );
    }

    // red wax seal: bottom right
    if (size.width > 90 && size.height > 70) {
      final c = Offset(size.width - inset * 2.6, size.height - inset * 2.6);
      final seal = Path();
      for (var i = 0; i < 14; i++) {
        final a = i * 2 * pi / 14;
        final rr = i.isEven ? 11.0 : 9.2;
        final p = c + Offset(cos(a), sin(a)) * rr;
        i == 0 ? seal.moveTo(p.dx, p.dy) : seal.lineTo(p.dx, p.dy);
      }
      seal.close();
      canvas.drawPath(seal, Paint()..shader = const RadialGradient(center: Alignment(-.3, -.3), colors: [Color(0xFFD02222), Color(0xFF7A0A0A)]).createShader(Rect.fromCircle(center: c, radius: 11)));
      canvas.drawCircle(c, 5.6, Paint()..style = PaintingStyle.stroke..strokeWidth = .9..color = const Color(0xFF3A0000).withValues(alpha: .7));
      canvas.drawLine(c + const Offset(0, -3.5), c + const Offset(0, 3.5), Paint()..strokeWidth = 1.1..color = const Color(0xFF3A0000).withValues(alpha: .7));
    }

    // top rim light, bottom shadow
    final rim = Paint()..strokeWidth = 1.2;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), rim..color = const Color(0xFFFFF1C8).withValues(alpha: .55));
    canvas.drawLine(Offset.zero, Offset(0, size.height), rim..color = const Color(0xFFFFF1C8).withValues(alpha: .22));
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), rim..color = const Color(0xAA000000));
  }

  // ------------------------------------------------------------- solar flare

  static void _solar(Canvas canvas, Size size, double opacity) {
    final rnd = Random(88);
    final local = Offset.zero & size;
    _fill(canvas, size, const [Color(0xFFFFC42E), Color(0xFFE8620A), Color(0xFF7A1D02), Color(0xFF210600)], const [0, .28, .68, 1], opacity,
        begin: Alignment.topCenter, end: Alignment.bottomCenter);

    // white-hot core glowing at the top
    canvas.drawRect(
      local,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.25, -1.15),
          radius: 1.0,
          colors: [const Color(0xFFFFFBE0).withValues(alpha: .8 * opacity + .1), const Color(0xFFFFD54F).withValues(alpha: .25), const Color(0x00FFB300)],
          stops: const [0, .4, 1],
        ).createShader(local),
    );

    // granulation: convection cells, bright rim and dark lane
    final cell = 26.0;
    final cols = max(2, (size.width / cell).ceil()), rows = max(2, (size.height / cell).ceil());
    final bright = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0;
    final fillp = Paint();
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final center = Offset((c + .5 + (r.isOdd ? .5 : 0)) * cell + (rnd.nextDouble() - .5) * 8, (r + .5) * cell * .9 + (rnd.nextDouble() - .5) * 6);
        final rr = cell * (.34 + rnd.nextDouble() * .18);
        final depth = (center.dy / size.height).clamp(0.0, 1.0);
        fillp.color = Color.fromRGBO(255, 214, 120, (.10 - .08 * depth).clamp(.01, .1));
        canvas.drawOval(Rect.fromCenter(center: center, width: rr * 2.1, height: rr * 1.5), fillp);
        bright.color = Color.fromRGBO(60, 12, 0, .10 + .12 * depth);
        canvas.drawOval(Rect.fromCenter(center: center, width: rr * 2.5, height: rr * 1.9), bright);
      }
    }

    // sunspots: umbra and penumbra
    final spots = (size.width * size.height / 26000).round().clamp(1, 4);
    for (var i = 0; i < spots; i++) {
      final c = Offset(size.width * (.15 + rnd.nextDouble() * .7), size.height * (.35 + rnd.nextDouble() * .5));
      final r = 4 + rnd.nextDouble() * 7;
      canvas.drawCircle(c, r * 1.7, Paint()..color = const Color(0xFF3A0C00).withValues(alpha: .35));
      canvas.drawCircle(c, r, Paint()..color = const Color(0xFF120300).withValues(alpha: .75));
    }

    // prominences: glowing arcs rising from the bottom edge and falling back
    final arc = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final x = size.width * (.18 + i * .32 + rnd.nextDouble() * .1);
      final span = size.width * (.12 + rnd.nextDouble() * .1);
      final rise = size.height * (.22 + rnd.nextDouble() * .18);
      final base = size.height;
      final path = Path()
        ..moveTo(x - span, base)
        ..cubicTo(x - span * .7, base - rise * 1.5, x + span * .7, base - rise * 1.5, x + span, base);
      arc
        ..strokeWidth = 5
        ..color = const Color(0xFFFF8A00).withValues(alpha: .22)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
      canvas.drawPath(path, arc);
      arc
        ..strokeWidth = 1.3
        ..color = const Color(0xFFFFF3C4).withValues(alpha: .85)
        ..maskFilter = null;
      canvas.drawPath(path, arc);
    }

    // rim: corona on top, ember on the bottom
    final rim = Paint()..strokeWidth = 1.4;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), rim..color = const Color(0xFFFFFBE0).withValues(alpha: .9));
    canvas.drawLine(Offset.zero, Offset(0, size.height), rim..color = const Color(0xFFFFE08A).withValues(alpha: .4));
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), rim..color = const Color(0x99400800));
  }

  // ----------------------------------------------------------------- abyssal

  static void _abyssal(Canvas canvas, Size size, double opacity) {
    final rnd = Random(404);
    final local = Offset.zero & size;
    _fill(canvas, size, const [Color(0xFF0C4A5C), Color(0xFF05293A), Color(0xFF02111B), Color(0xFF010609)], const [0, .3, .7, 1], opacity,
        begin: Alignment.topCenter, end: Alignment.bottomCenter);

    // caustics: bright wavering lines just under the surface
    final caustic = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    for (var i = 0; i < 7; i++) {
      final y0 = size.height * (.02 + i * .07) + rnd.nextDouble() * 8;
      final amp = 3 + rnd.nextDouble() * 5;
      final freq = 2 + rnd.nextDouble() * 3;
      final ph = rnd.nextDouble() * 2 * pi;
      final path = Path();
      for (var x = 0.0; x <= size.width; x += 4) {
        final y = y0 + sin(x / size.width * freq * 2 * pi + ph) * amp;
        x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      final fade = 1 - i / 8;
      caustic
        ..strokeWidth = 3
        ..color = const Color(0xFF80FFEA).withValues(alpha: .06 * fade)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
      canvas.drawPath(path, caustic);
      caustic
        ..strokeWidth = .8
        ..color = const Color(0xFFB2FFF2).withValues(alpha: .22 * fade)
        ..maskFilter = null;
      canvas.drawPath(path, caustic);
    }

    // light shafts from above
    canvas.save();
    canvas.clipRect(local);
    final shaft = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 4; i++) {
      final x = size.width * (.12 + i * .25 + rnd.nextDouble() * .08);
      final w = size.width * (.07 + rnd.nextDouble() * .06);
      final lean = size.height * (.25 + rnd.nextDouble() * .15);
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + w, 0)
        ..lineTo(x + w + lean + w, size.height)
        ..lineTo(x + lean, size.height)
        ..close();
      shaft.shader = ui.Gradient.linear(Offset(x, 0), Offset(x + lean, size.height), [const Color(0xFF9BFFF0).withValues(alpha: .10), const Color(0x009BFFF0)]);
      canvas.drawPath(path, shaft);
    }
    canvas.restore();

    // bubbles
    final bubble = Paint()..style = PaintingStyle.stroke..strokeWidth = .8;
    final n = (size.width * size.height / 3600).round().clamp(4, 30);
    for (var i = 0; i < n; i++) {
      final c = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      final r = 1.2 + rnd.nextDouble() * 4.2;
      bubble.color = const Color(0xFFB2FFF2).withValues(alpha: .35);
      canvas.drawCircle(c, r, bubble);
      canvas.drawCircle(c + Offset(-r * .35, -r * .35), r * .22, Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: .6));
    }

    // bioluminescent plankton
    final glow = Paint()..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
    final plankton = Paint();
    final p = (size.width * size.height / 5000).round().clamp(4, 24);
    for (var i = 0; i < p; i++) {
      final c = Offset(rnd.nextDouble() * size.width, size.height * (.25 + rnd.nextDouble() * .75));
      final bright = rnd.nextDouble();
      glow.color = const Color(0xFF1DE9C6).withValues(alpha: .4 * bright);
      canvas.drawCircle(c, 3.2, glow);
      plankton.color = const Color(0xFFE0FFF9).withValues(alpha: .35 + .5 * bright);
      canvas.drawCircle(c, .9 + bright * .8, plankton);
    }

    // the abyss swallows the bottom
    final lower = Rect.fromLTWH(0, size.height * .5, size.width, size.height * .5);
    canvas.drawRect(lower, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0x88000508)]).createShader(lower));

    final rim = Paint()..strokeWidth = 1.2;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), rim..color = const Color(0xFF80FFEA).withValues(alpha: .6));
    canvas.drawLine(Offset.zero, Offset(0, size.height), rim..color = const Color(0xFF80FFEA).withValues(alpha: .25));
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), rim..color = const Color(0x99000000));
  }

  // ------------------------------------------------------------------ sakura

  static void blossom(Canvas canvas, Offset c, double r, Color petal, {double turn = 0}) {
    final paint = Paint()..color = petal;
    for (var i = 0; i < 5; i++) {
      final a = turn + i * 2 * pi / 5 - pi / 2;
      final tip = c + Offset(cos(a), sin(a)) * r;
      final left = c + Offset(cos(a - .55), sin(a - .55)) * r * .62;
      final right = c + Offset(cos(a + .55), sin(a + .55)) * r * .62;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy)
          ..quadraticBezierTo(left.dx, left.dy, tip.dx, tip.dy)
          ..quadraticBezierTo(right.dx, right.dy, c.dx, c.dy)
          ..close(),
        paint,
      );
    }
    canvas.drawCircle(c, r * .16, Paint()..color = const Color(0xFFFFD966).withValues(alpha: .9));
  }

  static void _sakura(Canvas canvas, Size size, double opacity) {
    final rnd = Random(77);
    _fill(canvas, size, const [Color(0xFF2E1520), Color(0xFF1B0B12), Color(0xFF0F0509), Color(0xFF070204)], const [0, .35, .72, 1], opacity,
        begin: Alignment.topRight, end: Alignment.bottomLeft);

    // washi paper fibers
    final fiber = Paint()..strokeWidth = .5;
    final fibers = min(160, (size.width * size.height / 700).round());
    for (var i = 0; i < fibers; i++) {
      final p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      final a = rnd.nextDouble() * pi;
      final l = 3 + rnd.nextDouble() * 7;
      fiber.color = Color.fromRGBO(255, 214, 226, .03 + rnd.nextDouble() * .04);
      canvas.drawLine(p, p + Offset(cos(a), sin(a)) * l, fiber);
    }

    // pale moon behind the branch
    final moon = Offset(size.width * .78, size.height * .3);
    final mr = min(size.width, size.height) * .22;
    canvas.drawCircle(moon, mr * 1.6, Paint()..shader = RadialGradient(colors: [const Color(0xFFFFE0EA).withValues(alpha: .16), const Color(0x00FFE0EA)]).createShader(Rect.fromCircle(center: moon, radius: mr * 1.6)));
    canvas.drawCircle(moon, mr, Paint()..color = const Color(0xFFFFE9F0).withValues(alpha: .10));

    // sumi-e branch entering from the top right
    final branch = Path()
      ..moveTo(size.width + 4, size.height * .05)
      ..cubicTo(size.width * .85, size.height * .1, size.width * .72, size.height * .3, size.width * .5, size.height * .26);
    canvas.drawPath(branch, Paint()..style = PaintingStyle.stroke..strokeWidth = 3.4..strokeCap = StrokeCap.round..color = const Color(0xFF05020A).withValues(alpha: .9));
    canvas.drawPath(branch, Paint()..style = PaintingStyle.stroke..strokeWidth = .7..strokeCap = StrokeCap.round..color = const Color(0xFFFFC2D4).withValues(alpha: .25));
    final twig = Path()
      ..moveTo(size.width * .76, size.height * .22)
      ..quadraticBezierTo(size.width * .74, size.height * .42, size.width * .62, size.height * .5);
    canvas.drawPath(twig, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round..color = const Color(0xFF05020A).withValues(alpha: .9));

    // blossoms along the branch
    final bl = [
      (Offset(size.width * .9, size.height * .09), .055),
      (Offset(size.width * .74, size.height * .22), .07),
      (Offset(size.width * .6, size.height * .27), .05),
      (Offset(size.width * .64, size.height * .48), .06),
      (Offset(size.width * .84, size.height * .17), .04),
    ];
    final scale = min(size.width, size.height * 1.4);
    for (final (c, k) in bl) {
      final r = max(5.0, min(16.0, scale * k));
      blossom(canvas, c, r * 1.9, const Color(0xFFFF9DB8).withValues(alpha: .18), turn: rnd.nextDouble() * 2);
      blossom(canvas, c, r, const Color(0xFFFFC2D4).withValues(alpha: .85), turn: rnd.nextDouble() * 2);
    }

    // fallen petals
    final petals = (size.width * size.height / 7000).round().clamp(3, 14);
    for (var i = 0; i < petals; i++) {
      final c = Offset(rnd.nextDouble() * size.width, size.height * (.3 + rnd.nextDouble() * .7));
      final a = rnd.nextDouble() * pi;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(a);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 6 + rnd.nextDouble() * 3, height: 3.4), Paint()..color = const Color(0xFFFFB3C8).withValues(alpha: .25 + rnd.nextDouble() * .35));
      canvas.restore();
    }

    // ink wash at the bottom
    final wash = Rect.fromLTWH(0, size.height * .6, size.width, size.height * .4);
    canvas.drawRect(wash, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0x99000000)]).createShader(wash));

    // vermilion hanko seal
    if (size.width > 90 && size.height > 70) {
      final s = Rect.fromLTWH(14, size.height - 30, 14, 14);
      canvas.drawRRect(RRect.fromRectAndRadius(s, const Radius.circular(2)), Paint()..color = const Color(0xFFD62828).withValues(alpha: .8));
      canvas.drawLine(s.center + const Offset(0, -4), s.center + const Offset(0, 4), Paint()..strokeWidth = 1.2..color = const Color(0xFF140608));
      canvas.drawLine(s.center + const Offset(-4, 0), s.center + const Offset(4, 0), Paint()..strokeWidth = 1.2..color = const Color(0xFF140608));
    }

    final rim = Paint()..strokeWidth = 1.2;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), rim..color = const Color(0xFFFFC2D4).withValues(alpha: .5));
    canvas.drawLine(Offset.zero, Offset(0, size.height), rim..color = const Color(0xFFFFC2D4).withValues(alpha: .22));
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), rim..color = const Color(0x99000000));
  }
}
