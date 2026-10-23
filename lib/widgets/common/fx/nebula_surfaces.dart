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
enum NebulaSurfaceArt { imperial, solarFlare, abyssal, sakura, aurora, sapphire, amber, onyx, pearl, ivory, neon, voidGlass, forge, hermetic, eclipse, crimson, emerald, noxTerroris }

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
      case NebulaSurfaceArt.aurora:
        _aurora(canvas, size, opacity);
      case NebulaSurfaceArt.sapphire:
        _sapphire(canvas, size, opacity);
      case NebulaSurfaceArt.amber:
        _amber(canvas, size, opacity);
      case NebulaSurfaceArt.onyx:
        _onyx(canvas, size, opacity);
      case NebulaSurfaceArt.pearl:
        _pearl(canvas, size, opacity);
      case NebulaSurfaceArt.ivory:
        _ivory(canvas, size, opacity);
      case NebulaSurfaceArt.neon:
        _neon(canvas, size, opacity);
      case NebulaSurfaceArt.voidGlass:
        _void(canvas, size, opacity);
      case NebulaSurfaceArt.forge:
        _forge(canvas, size, opacity);
      case NebulaSurfaceArt.hermetic:
        _hermetic(canvas, size, opacity);
      case NebulaSurfaceArt.eclipse:
        _eclipse(canvas, size, opacity);
      case NebulaSurfaceArt.crimson:
        _crimson(canvas, size, opacity);
      case NebulaSurfaceArt.emerald:
        _emerald(canvas, size, opacity);
      case NebulaSurfaceArt.noxTerroris:
        _noxTerroris(canvas, size, opacity);
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

  // ------------------------------------------------------------------ aurora

  static void _aurora(Canvas canvas, Size size, double opacity) {
    final rnd = Random(61);
    final local = Offset.zero & size;
    _fill(canvas, size, const [Color(0xFF061C28), Color(0xFF04121C), Color(0xFF02070D)], const [0, .55, 1], opacity, begin: Alignment.topCenter, end: Alignment.bottomCenter);

    // stars
    final star = Paint();
    for (var i = 0; i < (size.width * size.height / 1500).round().clamp(6, 60); i++) {
      star.color = Color.fromRGBO(220, 255, 250, .15 + rnd.nextDouble() * .5);
      canvas.drawCircle(Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height * .7), .5 + rnd.nextDouble() * .8, star);
    }

    // curtains of light: wavy vertical ribbons, soft and bright
    canvas.save();
    canvas.clipRect(local);
    const colors = [Color(0xFF00E676), Color(0xFF18FFFF), Color(0xFF7C4DFF)];
    for (var k = 0; k < 3; k++) {
      final x0 = size.width * (.1 + k * .32);
      final amp = size.width * (.05 + rnd.nextDouble() * .05);
      final phase = rnd.nextDouble() * 2 * pi;
      final top = size.height * (.05 + rnd.nextDouble() * .1);
      final bottom = size.height * (.7 + rnd.nextDouble() * .2);
      final path = Path()..moveTo(x0, top);
      for (var y = top; y <= bottom; y += 6) {
        path.lineTo(x0 + sin(y / size.height * 5 + phase) * amp, y);
      }
      final width = size.width * .26;
      for (var y = bottom; y >= top; y -= 6) {
        path.lineTo(x0 + width + sin(y / size.height * 5 + phase + 1) * amp, y);
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, top), Offset(0, bottom), [colors[k].withValues(alpha: .0), colors[k].withValues(alpha: .26), colors[k].withValues(alpha: .06)], const [0, .25, 1])
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 7),
      );
    }
    canvas.restore();

    // treeline silhouette
    final ridge = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= size.width; x += 9) {
      final h = 6 + rnd.nextDouble() * 12;
      ridge.lineTo(x, size.height - h * .5);
      ridge.lineTo(x + 4.5, size.height - h);
    }
    ridge..lineTo(size.width, size.height)..close();
    canvas.drawPath(ridge, Paint()..color = const Color(0xFF010508).withValues(alpha: .9));

    final rim = Paint()..strokeWidth = 1.2;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), rim..color = const Color(0xFF69F0AE).withValues(alpha: .5));
    canvas.drawLine(Offset.zero, Offset(0, size.height), rim..color = const Color(0xFF69F0AE).withValues(alpha: .2));
  }

  // ---------------------------------------------------------------- sapphire

  static void _sapphire(Canvas canvas, Size size, double opacity) {
    final w = size.width, h = size.height;
    _fill(canvas, size, const [Color(0xFF2A6FE8), Color(0xFF14409F), Color(0xFF0A2262), Color(0xFF040C28)], const [0, .3, .68, 1], opacity);

    // step cut: nested chamfered frames, like the pavilion of an emerald-cut gem
    Path frame(double inset, double chamfer) => Path()
      ..moveTo(inset + chamfer, inset)
      ..lineTo(w - inset - chamfer, inset)
      ..lineTo(w - inset, inset + chamfer)
      ..lineTo(w - inset, h - inset - chamfer)
      ..lineTo(w - inset - chamfer, h - inset)
      ..lineTo(inset + chamfer, h - inset)
      ..lineTo(inset, h - inset - chamfer)
      ..lineTo(inset, inset + chamfer)
      ..close();
    final insets = [0.0, min(w, h) * .13, min(w, h) * .27];
    final line = Paint()..style = PaintingStyle.stroke..strokeWidth = .9;
    for (var i = 0; i < insets.length; i++) {
      final path = frame(insets[i], 9 - i * 2.5);
      line.color = const Color(0xFFBBDEFB).withValues(alpha: .38 - i * .08);
      canvas.drawPath(path, line);
    }
    // facets between frames: alternate lit and shadowed bands
    final a = frame(insets[0], 9), b = frame(insets[1], 6.5);
    canvas.drawPath(Path.combine(PathOperation.difference, a, b), Paint()..color = const Color(0xFF90CAF9).withValues(alpha: .10));
    final c = frame(insets[2], 4);
    canvas.drawPath(Path.combine(PathOperation.difference, b, c), Paint()..color = const Color(0xFF020A30).withValues(alpha: .22));
    // diagonal facet joins from the corners
    final join = Paint()..strokeWidth = .7..color = const Color(0xFFBBDEFB).withValues(alpha: .22);
    final m = insets[2];
    canvas.drawLine(Offset.zero, Offset(m, m), join);
    canvas.drawLine(Offset(w, 0), Offset(w - m, m), join);
    canvas.drawLine(Offset(0, h), Offset(m, h - m), join);
    canvas.drawLine(Offset(w, h), Offset(w - m, h - m), join);

    // table reflection and a star glint
    final table = Rect.fromLTWH(insets[2], insets[2], w - insets[2] * 2, (h - insets[2] * 2) * .45);
    canvas.drawRect(table, Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withValues(alpha: .20), Colors.white.withValues(alpha: 0)]).createShader(table));
    final g = Offset(w * .18, h * .2);
    canvas.drawPath(
      Path()
        ..moveTo(g.dx, g.dy - 6)..quadraticBezierTo(g.dx, g.dy, g.dx + 6, g.dy)..quadraticBezierTo(g.dx, g.dy, g.dx, g.dy + 6)
        ..quadraticBezierTo(g.dx, g.dy, g.dx - 6, g.dy)..quadraticBezierTo(g.dx, g.dy, g.dx, g.dy - 6)..close(),
      Paint()..color = Colors.white.withValues(alpha: .9),
    );
  }

  // ------------------------------------------------------------------- amber

  static void _amber(Canvas canvas, Size size, double opacity) {
    final rnd = Random(333);
    final w = size.width, h = size.height;
    _fill(canvas, size, const [Color(0xFFFFB74D), Color(0xFFE58A00), Color(0xFF8A4A00), Color(0xFF301500)], const [0, .3, .7, 1], opacity,
        begin: Alignment.topCenter, end: Alignment.bottomCenter);
    final local = Offset.zero & size;
    // glow of light passing through the resin
    canvas.drawRect(local, Paint()..shader = RadialGradient(center: const Alignment(-.3, -.5), radius: .9, colors: [const Color(0xFFFFE082).withValues(alpha: .38), const Color(0x00FFE082)]).createShader(local));

    // flow lines of the cooling resin
    final flow = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final y = h * (.1 + i * .16) + rnd.nextDouble() * 8;
      final path = Path()..moveTo(0, y);
      path.cubicTo(w * .3, y + (rnd.nextDouble() - .5) * 30, w * .7, y + (rnd.nextDouble() - .5) * 30, w, y + (rnd.nextDouble() - .5) * 20);
      flow..strokeWidth = 3..color = const Color(0xFFFFE082).withValues(alpha: .07);
      canvas.drawPath(path, flow);
      flow..strokeWidth = .7..color = const Color(0xFFFFF3C4).withValues(alpha: .18);
      canvas.drawPath(path, flow);
    }

    // plant fibers trapped inside
    final fiber = Paint()..style = PaintingStyle.stroke..strokeWidth = .9..color = const Color(0xFF4A2400).withValues(alpha: .5);
    for (var i = 0; i < 3; i++) {
      final p = Offset(w * (.2 + rnd.nextDouble() * .6), h * (.3 + rnd.nextDouble() * .5));
      final dir = rnd.nextDouble() * pi;
      canvas.drawPath(Path()..moveTo(p.dx, p.dy)..quadraticBezierTo(p.dx + cos(dir) * 14, p.dy + sin(dir) * 6, p.dx + cos(dir) * 26, p.dy + sin(dir + .6) * 14), fiber);
    }
    // a tiny fossil: two wings and a body
    if (w > 70 && h > 50) {
      final c = Offset(w * .72, h * .64);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(-.4);
      final dark = Paint()..color = const Color(0xFF2A1400).withValues(alpha: .6);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 12, height: 3.6), dark);
      canvas.drawOval(Rect.fromCenter(center: const Offset(-1, -5), width: 11, height: 4.4), Paint()..color = const Color(0xFF2A1400).withValues(alpha: .28));
      canvas.drawOval(Rect.fromCenter(center: const Offset(-1, 5), width: 11, height: 4.4), Paint()..color = const Color(0xFF2A1400).withValues(alpha: .28));
      canvas.restore();
    }

    // bubbles
    for (var i = 0; i < (w * h / 3800).round().clamp(4, 22); i++) {
      final p = Offset(rnd.nextDouble() * w, rnd.nextDouble() * h);
      final r = .8 + rnd.nextDouble() * 3;
      canvas.drawCircle(p, r, Paint()..style = PaintingStyle.stroke..strokeWidth = .7..color = const Color(0xFFFFF3C4).withValues(alpha: .5));
      canvas.drawCircle(p + Offset(-r * .35, -r * .35), r * .25, Paint()..color = Colors.white.withValues(alpha: .7));
    }
    final rim = Paint()..strokeWidth = 1.3;
    canvas.drawLine(Offset.zero, Offset(w, 0), rim..color = const Color(0xFFFFF3C4).withValues(alpha: .7));
    canvas.drawLine(Offset.zero, Offset(0, h), rim..color = const Color(0xFFFFF3C4).withValues(alpha: .3));
    canvas.drawLine(Offset(0, h), Offset(w, h), rim..color = const Color(0x99301500));
  }

  // -------------------------------------------------------------------- onyx

  static void _onyx(Canvas canvas, Size size, double opacity) {
    final w = size.width, h = size.height;
    _fill(canvas, size, const [Color(0xFF212124), Color(0xFF111113), Color(0xFF060607)], const [0, .5, 1], opacity);
    // one thin polished streak, nothing else
    final streak = Path()
      ..moveTo(w * .12, 0)..lineTo(w * .2, 0)..lineTo(w * .2 - h * .45, h)..lineTo(w * .12 - h * .45, h)..close();
    canvas.drawPath(streak, Paint()..shader = ui.Gradient.linear(Offset(w * .12, 0), Offset(w * .2, 0), [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: .09), Colors.white.withValues(alpha: 0)], const [0, .5, 1]));
    final streak2 = streak.shift(Offset(w * .08, 0));
    canvas.drawPath(streak2, Paint()..color = Colors.white.withValues(alpha: .025));
    // hairline frame and four dots
    canvas.drawRect(Rect.fromLTWH(5, 5, w - 10, h - 10), Paint()..style = PaintingStyle.stroke..strokeWidth = .6..color = Colors.white.withValues(alpha: .14));
    for (final p in [Offset(5, 5), Offset(w - 5, 5), Offset(5, h - 5), Offset(w - 5, h - 5)]) {
      canvas.drawCircle(p, 1.1, Paint()..color = Colors.white.withValues(alpha: .5));
    }
    final rim = Paint()..strokeWidth = 1;
    canvas.drawLine(Offset.zero, Offset(w, 0), rim..color = Colors.white.withValues(alpha: .35));
    canvas.drawLine(Offset(0, h), Offset(w, h), rim..color = const Color(0xAA000000));
  }

  // ------------------------------------------------------------------- pearl

  static void _pearl(Canvas canvas, Size size, double opacity) {
    final rnd = Random(808);
    final w = size.width, h = size.height;
    final local = Offset.zero & size;
    _fill(canvas, size, const [Color(0xFF4C4553), Color(0xFF2F2A36), Color(0xFF1A1620)], const [0, .55, 1], opacity);

    // iridescent nacre: soft overlapping blooms of pink, mint, lavender and gold
    const blooms = [Color(0xFFFFB3D1), Color(0xFFA7FFEB), Color(0xFFD1C4E9), Color(0xFFFFE9A3), Color(0xFFB3E5FC)];
    for (var i = 0; i < 6; i++) {
      final c = Offset(rnd.nextDouble() * w, rnd.nextDouble() * h);
      final r = min(w, h) * (.5 + rnd.nextDouble() * .5);
      canvas.drawCircle(c, r, Paint()..shader = ui.Gradient.radial(c, r, [blooms[i % blooms.length].withValues(alpha: .24), blooms[i % blooms.length].withValues(alpha: 0)]));
    }

    // mother-of-pearl growth rings fanning from the bottom
    final ring = Paint()..style = PaintingStyle.stroke..strokeWidth = .7;
    final origin = Offset(w * .5, h * 1.25);
    for (var i = 1; i <= 9; i++) {
      ring.color = Colors.white.withValues(alpha: .05 + .02 * (i % 3));
      canvas.drawCircle(origin, h * .18 * i, ring);
    }
    canvas.save();
    canvas.clipRect(local);
    for (var i = 0; i < 9; i++) {
      final a = -pi * (.12 + i * .095);
      canvas.drawLine(origin, origin + Offset(cos(a), sin(a)) * h * 2, Paint()..strokeWidth = .6..color = Colors.white.withValues(alpha: .05));
    }
    canvas.restore();

    // a few little pearls
    final n = (w * h / 9000).round().clamp(1, 5);
    for (var i = 0; i < n; i++) {
      final c = Offset(w * (.12 + rnd.nextDouble() * .76), h * (.62 + rnd.nextDouble() * .3));
      final r = 3 + rnd.nextDouble() * 3.4;
      canvas.drawCircle(c, r, Paint()..shader = ui.Gradient.radial(c + Offset(-r * .35, -r * .35), r * 1.5, const [Color(0xFFFFFFFF), Color(0xFFF3D9E8), Color(0xFF9C8AA8)], const [0, .5, 1]));
    }
    final rim = Paint()..strokeWidth = 1.2;
    canvas.drawLine(Offset.zero, Offset(w, 0), rim..color = Colors.white.withValues(alpha: .6));
    canvas.drawLine(Offset.zero, Offset(0, h), rim..color = Colors.white.withValues(alpha: .25));
    canvas.drawLine(Offset(0, h), Offset(w, h), rim..color = const Color(0x88000000));
  }

  // ------------------------------------------------------------------- ivory

  static void _ivory(Canvas canvas, Size size, double opacity) {
    final rnd = Random(1888);
    final w = size.width, h = size.height;
    const gold = Color(0xFFE6C068);
    _fill(canvas, size, const [Color(0xFF45301E), Color(0xFF2E1F13), Color(0xFF1A110A)], const [0, .55, 1], opacity);

    // walnut grain
    final grain = Paint()..style = PaintingStyle.stroke..strokeWidth = .7;
    for (var i = 0; i < min(40, (h / 5).round()); i++) {
      final y = rnd.nextDouble() * h;
      final path = Path()..moveTo(0, y);
      path.cubicTo(w * .3, y + (rnd.nextDouble() - .5) * 10, w * .65, y + (rnd.nextDouble() - .5) * 10, w, y + (rnd.nextDouble() - .5) * 8);
      grain.color = rnd.nextBool() ? Color.fromRGBO(255, 214, 160, .05) : Color.fromRGBO(0, 0, 0, .12);
      canvas.drawPath(path, grain);
    }

    // ivory inlay: a soft cream oval in the middle
    final c = Offset(w / 2, h / 2);
    final oval = Rect.fromCenter(center: c, width: w * .72, height: h * .62);
    canvas.drawOval(oval, Paint()..shader = RadialGradient(colors: [const Color(0xFFFFF8E1).withValues(alpha: .12), const Color(0x00FFF8E1)]).createShader(oval));

    // gold double frame with corner scrolls
    final outer = Rect.fromLTWH(5, 5, w - 10, h - 10);
    canvas.drawRect(outer, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = gold.withValues(alpha: .8));
    canvas.drawRect(outer.deflate(4), Paint()..style = PaintingStyle.stroke..strokeWidth = .6..color = gold.withValues(alpha: .45));
    final scroll = Paint()..style = PaintingStyle.stroke..strokeWidth = 1..strokeCap = StrokeCap.round..color = gold.withValues(alpha: .85);
    for (final (corner, dx, dy) in [(Offset(5, 5), 1.0, 1.0), (Offset(w - 5, 5), -1.0, 1.0), (Offset(5, h - 5), 1.0, -1.0), (Offset(w - 5, h - 5), -1.0, -1.0)]) {
      final p = corner + Offset(dx * 7, dy * 7);
      canvas.drawPath(
        Path()
          ..moveTo(p.dx + dx * 14, p.dy)
          ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + dy * 14)
          ..moveTo(p.dx + dx * 8, p.dy + dy * 3)
          ..quadraticBezierTo(p.dx + dx * 3, p.dy + dy * 3, p.dx + dx * 3, p.dy + dy * 8),
        scroll,
      );
      canvas.drawCircle(p, 1.6, Paint()..color = gold);
    }
    final rim = Paint()..strokeWidth = 1.2;
    canvas.drawLine(Offset.zero, Offset(w, 0), rim..color = const Color(0xFFFFE9A3).withValues(alpha: .45));
    canvas.drawLine(Offset(0, h), Offset(w, h), rim..color = const Color(0xAA000000));
  }

  // -------------------------------------------------------------------- neon

  static void _neon(Canvas canvas, Size size, double opacity) {
    final w = size.width, h = size.height;
    final local = Offset.zero & size;
    const pink = Color(0xFFFF2D95);
    const cyan = Color(0xFF00E5FF);
    _fill(canvas, size, const [Color(0xFF1B0634), Color(0xFF0C0220), Color(0xFF05010F)], const [0, .55, 1], opacity, begin: Alignment.topCenter, end: Alignment.bottomCenter);

    // retro sun with cut stripes
    final horizon = h * .62;
    final sunC = Offset(w * .5, horizon - min(w, h) * .02);
    final sunR = min(w, h) * .3;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, horizon));
    canvas.drawCircle(sunC, sunR * 1.5, Paint()..shader = ui.Gradient.radial(sunC, sunR * 1.5, [pink.withValues(alpha: .28), pink.withValues(alpha: 0)]));
    canvas.drawCircle(sunC, sunR, Paint()..shader = ui.Gradient.linear(Offset(0, sunC.dy - sunR), Offset(0, sunC.dy + sunR), const [Color(0xFFFFE066), Color(0xFFFF2D95), Color(0xFF7B1FA2)]));
    for (var i = 0; i < 5; i++) {
      final y = sunC.dy - sunR * .1 + i * sunR * .2;
      canvas.drawRect(Rect.fromLTWH(0, y, w, 1.2 + i * .9), Paint()..color = const Color(0xFF0C0220));
    }
    canvas.restore();

    // perspective grid
    canvas.drawRect(Rect.fromLTWH(0, horizon, w, h - horizon), Paint()..color = const Color(0xFF07010F).withValues(alpha: .85));
    final grid = Paint()..strokeWidth = .9..color = cyan.withValues(alpha: .55);
    for (var i = -8; i <= 8; i++) {
      canvas.drawLine(Offset(w / 2 + i * 6, horizon), Offset(w / 2 + i * w * .16, h), grid);
    }
    for (var i = 1; i <= 5; i++) {
      final t = i / 5;
      final y = horizon + (h - horizon) * t * t;
      canvas.drawLine(Offset(0, y), Offset(w, y), grid..color = cyan.withValues(alpha: .15 + .4 * t));
    }
    canvas.drawLine(Offset(0, horizon), Offset(w, horizon), Paint()..strokeWidth = 1.6..color = pink.withValues(alpha: .9));

    // neon tube frame: wide soft halo, thin hot core
    final frame = RRect.fromRectAndRadius(Rect.fromLTWH(3, 3, w - 6, h - 6), const Radius.circular(3));
    canvas.drawRRect(frame, Paint()..style = PaintingStyle.stroke..strokeWidth = 4..color = pink.withValues(alpha: .45)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3));
    canvas.drawRRect(frame, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.1..color = const Color(0xFFFFD1E8));
    canvas.drawRect(local, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(w, h), [cyan.withValues(alpha: .06), const Color(0x00000000)]));
  }

  // -------------------------------------------------------------------- void

  static void _void(Canvas canvas, Size size, double opacity) {
    final rnd = Random(9);
    final w = size.width, h = size.height;
    const green = Color(0xFF39FF14);
    _fill(canvas, size, const [Color(0xFF14171A), Color(0xFF0A0C0E), Color(0xFF020303)], const [0, .5, 1], opacity);
    final c = Offset(w * .72, h * .55);
    final r = min(w, h) * .22;

    // stars stretched towards the singularity
    final streak = Paint()..strokeWidth = .7;
    for (var i = 0; i < (w * h / 1400).round().clamp(10, 90); i++) {
      final p = Offset(rnd.nextDouble() * w, rnd.nextDouble() * h);
      final d = c - p;
      final dist = d.distance;
      if (dist < r * 1.4) continue;
      final dir = d / dist;
      final len = (r * 3 / dist * 10).clamp(1.0, 14.0);
      streak.color = Colors.white.withValues(alpha: .12 + rnd.nextDouble() * .3);
      canvas.drawLine(p, p + dir * len, streak);
    }

    // accretion disc: tilted glowing ellipse behind and in front of the hole
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-.35);
    final disc = Rect.fromCenter(center: Offset.zero, width: r * 4.2, height: r * 1.1);
    canvas.drawOval(disc, Paint()..style = PaintingStyle.stroke..strokeWidth = r * .22..color = green.withValues(alpha: .35)..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, r * .18));
    canvas.drawOval(disc, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = const Color(0xFFCCFFC2).withValues(alpha: .85));
    canvas.restore();

    // the event horizon and its photon ring
    canvas.drawCircle(c, r * 1.12, Paint()..color = green.withValues(alpha: .25)..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, r * .2));
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF000000));
    canvas.drawCircle(c, r, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = green.withValues(alpha: .9));

    // faint concentric lensing arcs
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(c, r * (1.6 + i * .5), Paint()..style = PaintingStyle.stroke..strokeWidth = .6..color = green.withValues(alpha: .10 / i));
    }
    final rim = Paint()..strokeWidth = 1.1;
    canvas.drawLine(Offset.zero, Offset(w, 0), rim..color = green.withValues(alpha: .35));
    canvas.drawLine(Offset.zero, Offset(0, h), rim..color = green.withValues(alpha: .15));
  }

  // ------------------------------------------------------------------- forge

  static void _forge(Canvas canvas, Size size, double opacity) {
    final rnd = Random(12);
    final w = size.width, h = size.height;
    _fill(canvas, size, const [Color(0xFF3B2A22), Color(0xFF241812), Color(0xFF130C09), Color(0xFF080403)], const [0, .35, .72, 1], opacity,
        begin: Alignment.topCenter, end: Alignment.bottomCenter);

    // hammered iron: shallow dimples, light on the upper lip, dark on the lower one
    final n = (w * h / 260).round().clamp(20, 260);
    for (var i = 0; i < n; i++) {
      final c = Offset(rnd.nextDouble() * w, rnd.nextDouble() * h);
      final r = 2 + rnd.nextDouble() * 4;
      canvas.drawCircle(c, r, Paint()..style = PaintingStyle.stroke..strokeWidth = .8..color = Colors.black.withValues(alpha: .22));
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), pi * 1.1, pi * .8, false, Paint()..style = PaintingStyle.stroke..strokeWidth = .7..color = const Color(0xFFFFD9B0).withValues(alpha: .10));
    }

    // heat rising from the bottom
    final heat = Rect.fromLTWH(0, h * .45, w, h * .55);
    canvas.drawRect(heat, Paint()..shader = ui.Gradient.linear(Offset(0, h), Offset(0, h * .45), [const Color(0xFFFF6D00).withValues(alpha: .38), const Color(0x00FF6D00)]));

    // molten seams: cracks full of liquid metal
    for (var i = 0; i < 3; i++) {
      var p = Offset(w * (.15 + i * .35 + rnd.nextDouble() * .1), h);
      final path = Path()..moveTo(p.dx, p.dy);
      for (var s = 0; s < 9; s++) {
        p += Offset((rnd.nextDouble() - .5) * 16, -h * .07 - rnd.nextDouble() * 6);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..color = const Color(0xFFFF6D00).withValues(alpha: .4)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3));
      canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.1..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..color = const Color(0xFFFFE082));
    }

    // bolted straps
    final strap = Paint()..color = const Color(0xFF0A0605).withValues(alpha: .6);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, 7), strap);
    for (var x = 10.0; x < w; x += 42) {
      canvas.drawCircle(Offset(x, 3.5), 1.6, Paint()..color = const Color(0xFF8A6A58));
    }
    final rim = Paint()..strokeWidth = 1.2;
    canvas.drawLine(Offset(0, 7), Offset(w, 7), rim..color = const Color(0xFFFFB074).withValues(alpha: .4));
    canvas.drawLine(Offset(0, h), Offset(w, h), rim..color = const Color(0xFFFF8A00).withValues(alpha: .6));
  }

  // ---------------------------------------------------------------- hermetic

  static void _hermetic(Canvas canvas, Size size, double opacity) {
    final w = size.width, h = size.height;
    const green = Color(0xFF38D39A);
    const violet = Color(0xFFB388FF);
    _fill(canvas, size, const [Color(0xFF10242B), Color(0xFF0A141E), Color(0xFF060A12)], const [0, .55, 1], opacity);

    // engraved alchemical wheel, big and faint
    final c = Offset(w * .5, h * .5);
    final r = min(w, h) * .42;
    final line = Paint()..style = PaintingStyle.stroke..strokeWidth = .8;
    line.color = green.withValues(alpha: .30);
    canvas.drawCircle(c, r, line);
    canvas.drawCircle(c, r * .8, line..color = violet.withValues(alpha: .24));
    for (var i = 0; i < 48; i++) {
      final a = i * 2 * pi / 48;
      final l = i % 4 == 0 ? 5.0 : 2.5;
      canvas.drawLine(c + Offset(cos(a), sin(a)) * (r - l), c + Offset(cos(a), sin(a)) * r, line..color = green.withValues(alpha: .28));
    }
    for (var k = 0; k < 2; k++) {
      final path = Path();
      for (var i = 0; i < 3; i++) {
        final a = k * pi / 3 + i * 2 * pi / 3 - pi / 2;
        final p = c + Offset(cos(a), sin(a)) * r * .62;
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, line..color = (k == 0 ? green : violet).withValues(alpha: .36));
    }

    // planet marks in the corners
    const marks = ['☉', '☽', '☿', '♀'];
    final corners = [Offset(12, 12), Offset(w - 12, 12), Offset(12, h - 12), Offset(w - 12, h - 12)];
    for (var i = 0; i < 4; i++) {
      final tp = TextPainter(text: TextSpan(text: marks[i], style: TextStyle(color: green.withValues(alpha: .55), fontSize: 11)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, corners[i] - Offset(tp.width / 2, tp.height / 2));
      tp.dispose();
    }

    // double frame, sharp corners
    canvas.drawRect(Rect.fromLTWH(3, 3, w - 6, h - 6), Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = green.withValues(alpha: .55));
    canvas.drawRect(Rect.fromLTWH(6.5, 6.5, w - 13, h - 13), Paint()..style = PaintingStyle.stroke..strokeWidth = .5..color = violet.withValues(alpha: .35));
  }

  // ----------------------------------------------------------------- eclipse

  static void _eclipse(Canvas canvas, Size size, double opacity) {
    final rnd = Random(20);
    final w = size.width, h = size.height;
    _fill(canvas, size, const [Color(0xFF0A1C2E), Color(0xFF050E1C), Color(0xFF02060D)], const [0, .5, 1], opacity, begin: Alignment.topRight, end: Alignment.bottomLeft);
    for (var i = 0; i < (w * h / 1600).round().clamp(6, 50); i++) {
      canvas.drawCircle(Offset(rnd.nextDouble() * w, rnd.nextDouble() * h), .5 + rnd.nextDouble() * .7, Paint()..color = Colors.white.withValues(alpha: .12 + rnd.nextDouble() * .4));
    }
    final c = Offset(w * .76, h * .42);
    final r = min(w, h) * .26;

    // corona: rays and halo
    final ray = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < 30; i++) {
      final a = i * 2 * pi / 30;
      final len = r * (.5 + rnd.nextDouble() * 1.4);
      final p0 = c + Offset(cos(a), sin(a)) * r;
      final p1 = c + Offset(cos(a), sin(a)) * (r + len);
      ray
        ..strokeWidth = 1 + rnd.nextDouble()
        ..shader = ui.Gradient.linear(p0, p1, [const Color(0xFF9AF5FF).withValues(alpha: .4), const Color(0x0029D9FF)]);
      canvas.drawLine(p0, p1, ray);
    }
    canvas.drawCircle(c, r * 1.4, Paint()..shader = ui.Gradient.radial(c, r * 1.4, [const Color(0x0029D9FF), const Color(0x6629D9FF), const Color(0x0029D9FF)], const [.55, .72, 1]));
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF000206));
    canvas.drawCircle(c, r, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = const Color(0xFF9AF5FF).withValues(alpha: .7));

    // the diamond ring
    final d = c + Offset(cos(-pi * .8), sin(-pi * .8)) * r;
    canvas.drawCircle(d, r * .5, Paint()..shader = ui.Gradient.radial(d, r * .5, [Colors.white.withValues(alpha: .7), const Color(0x339AF5FF), const Color(0x009AF5FF)], const [0, .3, 1]));
    canvas.drawCircle(d, 2, Paint()..color = Colors.white);

    final rim = Paint()..strokeWidth = 1.1;
    canvas.drawLine(Offset.zero, Offset(w, 0), rim..color = const Color(0xFF9AF5FF).withValues(alpha: .4));
    canvas.drawLine(Offset.zero, Offset(0, h), rim..color = const Color(0xFF9AF5FF).withValues(alpha: .18));
  }

  // ----------------------------------------------------------------- crimson

  static void _crimson(Canvas canvas, Size size, double opacity) {
    final rnd = Random(1);
    final w = size.width, h = size.height;
    _fill(canvas, size, const [Color(0xFF4A0A1C), Color(0xFF2A0610), Color(0xFF14030A), Color(0xFF090105)], const [0, .35, .72, 1], opacity,
        begin: Alignment.topLeft, end: Alignment.bottomRight);

    // veins from the edges
    for (var corner = 0; corner < 4; corner++) {
      final origin = Offset(corner % 2 == 0 ? 0 : w, corner < 2 ? 0 : h);
      final inward = atan2(h / 2 - origin.dy, w / 2 - origin.dx);
      for (var b = 0; b < 3; b++) {
        var pos = origin;
        var heading = inward + (rnd.nextDouble() - .5) * 1.2;
        final path = Path()..moveTo(pos.dx, pos.dy);
        for (var s = 0; s < 9 + rnd.nextInt(6); s++) {
          heading += (rnd.nextDouble() - .5) * .8;
          pos += Offset(cos(heading), sin(heading)) * 9;
          path.lineTo(pos.dx, pos.dy);
        }
        canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round..color = const Color(0xFFFF1744).withValues(alpha: .18)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.5));
        canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = .8..strokeCap = StrokeCap.round..color = const Color(0xFFFF5C7C).withValues(alpha: .55));
      }
    }

    // wet sheen
    final sheen = Path()..moveTo(0, h * .18)..quadraticBezierTo(w * .5, h * .02, w, h * .14)..lineTo(w, h * .06)..quadraticBezierTo(w * .5, -h * .08, 0, h * .06)..close();
    canvas.drawPath(sheen, Paint()..color = Colors.white.withValues(alpha: .07));

    // drops hanging from the top edge
    for (var i = 0; i < (w / 38).round().clamp(2, 10); i++) {
      final x = rnd.nextDouble() * w;
      final len = 5 + rnd.nextDouble() * 12;
      canvas.drawRect(Rect.fromLTWH(x - .8, 0, 1.6, len), Paint()..color = const Color(0xFFB0102E).withValues(alpha: .85));
      canvas.drawCircle(Offset(x, len + 1.5), 2.3, Paint()..color = const Color(0xFFD81B3F));
      canvas.drawCircle(Offset(x - .7, len + .8), .7, Paint()..color = Colors.white.withValues(alpha: .6));
    }
    final rim = Paint()..strokeWidth = 1.2;
    canvas.drawLine(Offset(0, h), Offset(w, h), rim..color = const Color(0xFF000000).withValues(alpha: .7));
    canvas.drawLine(Offset.zero, Offset(0, h), rim..color = const Color(0xFFFF5C7C).withValues(alpha: .3));
  }

  // ----------------------------------------------------------------- emerald

  static void _emerald(Canvas canvas, Size size, double opacity) {
    final rnd = Random(55);
    final w = size.width, h = size.height;
    const gold = Color(0xFFFFD54F);
    _fill(canvas, size, const [Color(0xFF138A5E), Color(0xFF0A5A3E), Color(0xFF04301F), Color(0xFF01130C)], const [0, .3, .68, 1], opacity);

    // big lit and shadowed facets
    final cols = max(2, (w / 54).round()), rows = max(2, (h / 54).round());
    final cw = w / cols, ch = h / rows;
    final pts = List.generate(rows + 1, (r) => List.generate(cols + 1, (c) => Offset(c * cw + (c > 0 && c < cols ? (rnd.nextDouble() - .5) * cw * .5 : 0), r * ch + (r > 0 && r < rows ? (rnd.nextDouble() - .5) * ch * .5 : 0))));
    final fill = Paint();
    final edge = Paint()..style = PaintingStyle.stroke..strokeWidth = .6..color = const Color(0xFFB9F6CA).withValues(alpha: .20);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final a = pts[r][c], b = pts[r][c + 1], d = pts[r + 1][c], e = pts[r + 1][c + 1];
        for (final tri in [[a, b, e], [a, e, d]]) {
          final tilt = rnd.nextDouble() * 2 - 1;
          fill.color = tilt > 0 ? const Color(0xFFB9F6CA).withValues(alpha: tilt * .16) : Colors.black.withValues(alpha: -tilt * .3);
          final path = Path()..moveTo(tri[0].dx, tri[0].dy)..lineTo(tri[1].dx, tri[1].dy)..lineTo(tri[2].dx, tri[2].dy)..close();
          canvas.drawPath(path, fill);
          canvas.drawPath(path, edge);
        }
      }
    }

    // gold veins running through the stone
    for (var i = 0; i < 2; i++) {
      final y = h * (.3 + i * .4);
      final path = Path()..moveTo(0, y)..cubicTo(w * .3, y - 14, w * .5, y + 16, w * .7, y - 4)..cubicTo(w * .85, y - 14, w * .95, y + 6, w, y - 6);
      canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = gold.withValues(alpha: .20)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.5));
      canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..strokeCap = StrokeCap.round..color = gold.withValues(alpha: .85));
    }

    final rim = Paint()..strokeWidth = 1.2;
    canvas.drawLine(Offset.zero, Offset(w, 0), rim..color = const Color(0xFFB9F6CA).withValues(alpha: .6));
    canvas.drawLine(Offset.zero, Offset(0, h), rim..color = const Color(0xFFB9F6CA).withValues(alpha: .25));
    canvas.drawLine(Offset(0, h), Offset(w, h), rim..color = const Color(0x99000000));
  }
  // ------------------------------------------------------------- nox terroris
  // A watching aperture surrounded by ossuary ribs; the center stays quiet for content.
  static void _noxTerroris(Canvas canvas, Size size, double opacity) {
    final w = size.width, h = size.height, m = min(size.width, size.height);
    const bone = Color(0xFFDCE8B0);
    const acid = Color(0xFFB7D86B);
    _fill(canvas, size, const [Color(0xFF171A17), Color(0xFF090B0A), Color(0xFF020303)], const [0, .48, 1], opacity,
        begin: Alignment.topLeft, end: Alignment.bottomRight);
    final eye = Offset(w * .72, h * .42);
    final er = m * .22;
    canvas.drawOval(Rect.fromCenter(center: eye, width: er * 2.8, height: er * .92),
      Paint()..shader = ui.Gradient.radial(eye, er * 1.5, [acid.withValues(alpha: opacity * .16), acid.withValues(alpha: 0)]));
    final socket = Rect.fromCenter(center: eye, width: er * 2.1, height: er * .56);
    canvas.drawOval(socket, Paint()..color = const Color(0xFF020403).withValues(alpha: opacity * .9));
    canvas.drawOval(socket, Paint()..style = PaintingStyle.stroke..strokeWidth = max(.8, m * .008)..color = bone.withValues(alpha: opacity * .34));
    canvas.drawLine(Offset(eye.dx, socket.top + socket.height * .08), Offset(eye.dx, socket.bottom - socket.height * .08),
      Paint()..strokeWidth = max(1.0, m * .012)..color = acid.withValues(alpha: opacity * .85));
    final rib = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round
      ..strokeWidth = max(.8, m * .009)..color = bone.withValues(alpha: opacity * .22);
    for (var i = 0; i < 3; i++) {
      final inset = m * (.035 + i * .025);
      final path = Path()
        ..moveTo(inset, 0)
        ..quadraticBezierTo(w * .12, h * .12, w * (.08 + i * .025), h * .34)
        ..moveTo(w - inset, h)
        ..quadraticBezierTo(w * .88, h * .84, w * (.92 - i * .025), h * .62);
      canvas.drawPath(path, rib);
    }
    final crack = Paint()..style = PaintingStyle.stroke..strokeWidth = max(.65, m * .006)
      ..color = acid.withValues(alpha: opacity * .28);
    final paths = [
      Path()..moveTo(0, h * .58)..lineTo(w * .09, h * .53)..lineTo(w * .13, h * .60)..lineTo(w * .19, h * .57),
      Path()..moveTo(w, h * .24)..lineTo(w * .91, h * .29)..lineTo(w * .87, h * .22)..lineTo(w * .81, h * .26),
      Path()..moveTo(w * .12, h)..lineTo(w * .17, h * .91)..lineTo(w * .22, h * .94),
    ];
    for (final path in paths) canvas.drawPath(path, crack);
    final seal = Offset(w * .5, h * .91);
    final sealPath = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4 - pi / 8;
      final p = seal + Offset(cos(a), sin(a)) * m * .035;
      i == 0 ? sealPath.moveTo(p.dx, p.dy) : sealPath.lineTo(p.dx, p.dy);
    }
    sealPath.close();
    canvas.drawPath(sealPath, Paint()..style = PaintingStyle.stroke..strokeWidth = max(.7, m * .007)..color = bone.withValues(alpha: opacity * .34));
    final rim = Paint()..strokeWidth = max(.8, m * .008);
    canvas.drawLine(Offset.zero, Offset(w, 0), rim..color = bone.withValues(alpha: opacity * .20));
    canvas.drawLine(Offset(0, h), Offset(w, h), rim..color = Colors.black.withValues(alpha: opacity * .8));
  }


}
