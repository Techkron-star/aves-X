import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:aves/theme/nebula/nebula_material.dart';
import 'package:aves/widgets/common/fx/demon_glass.dart';
import 'package:aves/widgets/common/fx/gold_leaf.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

// The decoration of a Nebula material, so every glass surface shares the active identity.
// `phase` (0..1) animates a restrained glint; -1 is the resting state.
Decoration nebulaMaterialDecoration(NebulaMaterial material, {double phase = -1, double opacity = .86}) {
  switch (material) {
    case NebulaMaterial.ruby:
      return DiamondDecoration(glint: phase, opacity: opacity);
    case NebulaMaterial.nightDemon:
      return DemonGlassDecoration(pulse: phase, opacity: opacity);
    case NebulaMaterial.godly:
      return GoldLeafDecoration(glint: phase, opacity: opacity);
    default:
      final style = nebulaMaterialStylesByMaterial[material];
      if (style == null) return const BoxDecoration();
      return NebulaMaterialDecoration(style: style, phase: phase, opacity: opacity);
  }
}

/// Palette-driven glass for phase-2 themes. Colors and signature patterns come
/// from the central material registry rather than new screen-local literals.
class NebulaMaterialDecoration extends Decoration {
  final NebulaMaterialStyle style;
  final double phase;
  final double opacity;

  const NebulaMaterialDecoration({required this.style, this.phase = -1, this.opacity = .86});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _NebulaMaterialPainter(style, phase, opacity);

  @override
  bool operator ==(Object other) =>
      other is NebulaMaterialDecoration && other.style.material == style.material && other.phase == phase && other.opacity == opacity;

  @override
  int get hashCode => Object.hash(style.material, phase, opacity);
}

class _NebulaMaterialPainter extends BoxPainter {
  final NebulaMaterialStyle style;
  final double phase;
  final double opacity;

  _NebulaMaterialPainter(this.style, this.phase, this.opacity);

  // The art is drawn in a normalized 100 × 100 canvas and replayed as a Picture.
  // Animated glints therefore do not rebuild the facets or signature pattern on every frame.
  static final Map<(NebulaMaterial, Color, Color, Color, Color, double), ui.Picture> _art = {};

  static double _radiusFor(NebulaMaterial material) => switch (material) {
    NebulaMaterial.hermetic || NebulaMaterial.voidGlass || NebulaMaterial.imperial => 4.0,
    NebulaMaterial.pearl || NebulaMaterial.aurora => 20.0,
    NebulaMaterial.solarFlare => 13.0,
    NebulaMaterial.forge || NebulaMaterial.neon || NebulaMaterial.sapphire => 8.0,
    _ => 12.0,
  };

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null || size.isEmpty) return;

    if (_art.length > 32) {
      for (final picture in _art.values) {
        picture.dispose();
      }
      _art.clear();
    }

    final key = (style.material, style.surface, style.liquidDeep, style.accent, style.liquidHighlight, opacity);
    final picture = _art[key] ??= _recordArt(style, opacity);

    canvas.save();
    canvas.clipRect(offset & size);
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(size.width / 100, size.height / 100);
    canvas.drawPicture(picture);

    // A moving, coloured specular reflection — never a permanent white stripe.
    if (phase >= 0) {
      final left = -46 + phase * 172;
      const bandWidth = 42.0;
      final band = Rect.fromLTWH(left, -14, bandWidth, 128);
      canvas.save();
      canvas.clipRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 100, 100), Radius.circular(_radiusFor(style.material))));
      canvas.drawRect(
        band,
        Paint()
          ..blendMode = BlendMode.screen
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              style.liquidHighlight.withValues(alpha: 0),
              style.liquidHighlight.withValues(alpha: opacity * .46),
              style.accent.withValues(alpha: opacity * .20),
              style.liquidHighlight.withValues(alpha: 0),
            ],
            stops: const [0, .38, .57, 1],
          ).createShader(band),
      );
      canvas.restore();
    }
    canvas.restore();
  }

  static ui.Picture _recordArt(NebulaMaterialStyle style, double opacity) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const rect = Rect.fromLTWH(0, 0, 100, 100);
    final shape = RRect.fromRectAndRadius(rect, Radius.circular(_radiusFor(style.material)));
    final bright = style.liquidHighlight;
    final accent = style.accent;
    final deep = style.liquidDeep;
    final edge = style.edge;

    // Smoked crystal body: a deep base, a tinted core and a real light source in the upper-left.
    canvas.drawRRect(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            style.surface.withValues(alpha: opacity),
            deep.withValues(alpha: opacity * .78),
            style.surface.withValues(alpha: opacity * .96),
          ],
          stops: const [0, .52, 1],
        ).createShader(rect),
    );
    canvas.save();
    canvas.clipRRect(shape);

    // Five restrained glass facets add volume without obscuring content beneath the translucent layer.
    final facetPaint = Paint()..style = PaintingStyle.fill;
    final facets = <(Path, Color)>[
      (Path()..moveTo(0, 0)..lineTo(70, 0)..lineTo(43, 43)..close(), bright.withValues(alpha: opacity * .105)),
      (Path()..moveTo(0, 0)..lineTo(43, 43)..lineTo(0, 72)..close(), bright.withValues(alpha: opacity * .055)),
      (Path()..moveTo(100, 0)..lineTo(70, 0)..lineTo(43, 43)..lineTo(100, 28)..close(), accent.withValues(alpha: opacity * .105)),
      (Path()..moveTo(0, 100)..lineTo(43, 43)..lineTo(55, 100)..close(), deep.withValues(alpha: opacity * .16)),
      (Path()..moveTo(100, 100)..lineTo(43, 43)..lineTo(55, 100)..close(), Colors.black.withValues(alpha: opacity * .12)),
    ];
    for (final facet in facets) {
      facetPaint.color = facet.$2;
      canvas.drawPath(facet.$1, facetPaint);
    }

    // Broad soft reflection plus a darker pavilion near the lower edge.
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bright.withValues(alpha: opacity * .19),
            bright.withValues(alpha: opacity * .025),
            Colors.transparent,
            deep.withValues(alpha: opacity * .14),
          ],
          stops: const [0, .22, .58, 1],
        ).createShader(rect),
    );
    canvas.drawRect(
      const Rect.fromLTWH(0, 61, 100, 39),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0x33000000)],
        ).createShader(const Rect.fromLTWH(0, 61, 100, 39)),
    );

    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.25
      ..color = accent.withValues(alpha: opacity * .38);
    final lightInk = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.7
      ..color = bright.withValues(alpha: opacity * .62);

    // Every material has its own engraved signature, not merely a different tint.
    switch (style.material) {
      case NebulaMaterial.forge:
        final vein = Path()
          ..moveTo(-6, 77)
          ..cubicTo(13, 53, 29, 83, 46, 48)
          ..cubicTo(61, 18, 77, 47, 106, 12);
        canvas.drawPath(vein, Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round
          ..strokeWidth = 5..color = accent.withValues(alpha: opacity * .18)
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 3));
        canvas.drawPath(vein, lightInk);
        canvas.drawPath(Path()..moveTo(-4, 91)..cubicTo(25, 69, 39, 95, 64, 60)..cubicTo(79, 40, 91, 62, 104, 43), ink);
        for (final point in const [Offset(17, 65), Offset(47, 47), Offset(78, 36)]) {
          canvas.drawCircle(point, 2.4, Paint()..color = bright.withValues(alpha: opacity * .8));
          canvas.drawCircle(point, 5.5, Paint()..color = accent.withValues(alpha: opacity * .22)..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 3));
        }
        break;
      case NebulaMaterial.hermetic:
        canvas.drawCircle(const Offset(50, 50), 37, ink);
        canvas.drawCircle(const Offset(50, 50), 30, Paint()..style = PaintingStyle.stroke..strokeWidth = .7..color = bright.withValues(alpha: opacity * .45));
        canvas.drawPath(Path()..moveTo(50, 13)..lineTo(84, 76)..lineTo(16, 76)..close(), lightInk);
        canvas.drawPath(Path()..moveTo(16, 24)..lineTo(84, 24)..lineTo(50, 87)..close(), ink);
        canvas.drawCircle(const Offset(50, 50), 7, Paint()..color = deep.withValues(alpha: opacity * .85));
        canvas.drawCircle(const Offset(50, 50), 4.2, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = bright.withValues(alpha: opacity * .8));
        for (var i = 0; i < 8; i++) {
          final a = i * pi / 4;
          final p = Offset(50 + cos(a) * 43, 50 + sin(a) * 43);
          canvas.drawCircle(p, 1.4, Paint()..color = bright.withValues(alpha: opacity * .72));
        }
        break;
      case NebulaMaterial.eclipse:
        // A cold blue eclipse with a luminous, deliberately broken corona.
        canvas.drawCircle(const Offset(53, 47), 36, Paint()..style = PaintingStyle.stroke..strokeWidth = 5
          ..color = bright.withValues(alpha: opacity * .18)
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 3));
        canvas.drawArc(const Rect.fromLTWH(13, 7, 76, 76), -.9, 2.4, false, lightInk);
        canvas.drawArc(const Rect.fromLTWH(13, 7, 76, 76), 2.05, 2.6, false, ink);
        canvas.drawCircle(const Offset(53, 47), 29, Paint()..shader = RadialGradient(
          colors: [style.surface.withValues(alpha: opacity), deep.withValues(alpha: opacity), Colors.black.withValues(alpha: opacity)],
        ).createShader(const Rect.fromLTWH(24, 18, 58, 58)));
        canvas.drawArc(const Rect.fromLTWH(17, 11, 72, 72), -.55, 1.1, false, Paint()
          ..style = PaintingStyle.stroke..strokeWidth = 1.1..color = bright.withValues(alpha: opacity * .85));
        break;
      case NebulaMaterial.solarFlare:
        // Total solar eclipse: black disc, gold-white corona and short plasma prominences.
        for (var i = 0; i < 28; i++) {
          final angle = i * 2 * pi / 28;
          final inner = i.isEven ? 30.0 : 33.0;
          final outer = i.isEven ? 45.0 : 40.0;
          final p1 = Offset(50 + cos(angle) * inner, 50 + sin(angle) * inner);
          final p2 = Offset(50 + cos(angle) * outer, 50 + sin(angle) * outer);
          canvas.drawLine(p1, p2, Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round
            ..strokeWidth = i.isEven ? 1.8 : .8
            ..color = (i % 4 == 0 ? bright : accent).withValues(alpha: opacity * (i.isEven ? .74 : .42)));
        }
        canvas.drawCircle(const Offset(50, 50), 29, Paint()..style = PaintingStyle.stroke..strokeWidth = 7
          ..color = accent.withValues(alpha: opacity * .28)..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 4));
        canvas.drawCircle(const Offset(50, 50), 27, Paint()..shader = SweepGradient(
          colors: [bright, accent, deep, bright],
          stops: const [0, .3, .68, 1],
        ).createShader(const Rect.fromLTWH(22, 22, 56, 56)));
        canvas.drawCircle(const Offset(50, 50), 22.5, Paint()..shader = RadialGradient(
          colors: [Colors.black, style.surface, deep.withValues(alpha: opacity * .65)],
          stops: const [0, .7, 1],
        ).createShader(const Rect.fromLTWH(27.5, 27.5, 45, 45)));
        canvas.drawArc(const Rect.fromLTWH(23, 23, 54, 54), -.8, 1.35, false, lightInk);
        break;
      case NebulaMaterial.voidGlass:
        for (final radius in const [23.0, 34.0, 45.0]) {
          final hexagon = Path()
            ..moveTo(50, 50 - radius)
            ..lineTo(50 + radius * .86, 50 - radius * .5)
            ..lineTo(50 + radius * .86, 50 + radius * .5)
            ..lineTo(50, 50 + radius)
            ..lineTo(50 - radius * .86, 50 + radius * .5)
            ..lineTo(50 - radius * .86, 50 - radius * .5)
            ..close();
          canvas.drawPath(hexagon, radius == 34 ? lightInk : ink);
        }
        canvas.drawCircle(const Offset(50, 50), 12, Paint()..color = Colors.black.withValues(alpha: opacity * .85));
        canvas.drawCircle(const Offset(50, 50), 14, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = bright.withValues(alpha: opacity * .72));
        for (var i = 0; i < 6; i++) {
          final a = i * pi / 3;
          canvas.drawCircle(Offset(50 + cos(a) * 42, 50 + sin(a) * 42), 1.8, Paint()..color = accent.withValues(alpha: opacity * .7));
        }
        break;
      case NebulaMaterial.crimson:
        for (var i = 0; i < 5; i++) {
          final x = i * 26.0 - 23;
          final shard = Path()..moveTo(x, 20)..lineTo(x + 30, 48)..lineTo(x + 12, 80);
          canvas.drawPath(shard, i.isEven ? lightInk : ink);
        }
        canvas.drawCircle(const Offset(73, 30), 15, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = bright.withValues(alpha: opacity * .42));
        canvas.drawCircle(const Offset(73, 30), 8, Paint()..color = accent.withValues(alpha: opacity * .16));
        final drop = Path()..moveTo(77, 55)..cubicTo(70, 65, 68, 68, 68, 73)..cubicTo(68, 83, 84, 83, 84, 73)..cubicTo(84, 68, 81, 62, 77, 55)..close();
        canvas.drawPath(drop, Paint()..shader = LinearGradient(colors: [bright.withValues(alpha: opacity * .7), deep.withValues(alpha: opacity * .85)]).createShader(const Rect.fromLTWH(68, 55, 16, 28)));
        canvas.drawPath(drop, Paint()..style = PaintingStyle.stroke..strokeWidth = .8..color = bright.withValues(alpha: opacity * .65));
        break;
      case NebulaMaterial.neon:
        for (var i = -2; i < 8; i++) {
          canvas.drawLine(Offset(i * 22.0, 0), Offset(i * 22.0 + 48, 100), i.isEven ? lightInk : ink);
          canvas.drawLine(Offset(0, i * 22.0 + 12), Offset(100, i * 22.0 - 12), ink);
        }
        for (final point in const [Offset(22, 24), Offset(67, 41), Offset(43, 75), Offset(82, 84)]) {
          canvas.drawCircle(point, 4.5, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = bright.withValues(alpha: opacity * .68));
          canvas.drawCircle(point, 1.4, Paint()..color = accent.withValues(alpha: opacity * .92));
        }
        break;
      case NebulaMaterial.emerald:
        canvas.drawPath(Path()..moveTo(50, 7)..cubicTo(86, 31, 78, 70, 50, 93)..cubicTo(22, 70, 14, 31, 50, 7)..close(), lightInk);
        canvas.drawPath(Path()..moveTo(50, 14)..cubicTo(48, 42, 52, 64, 50, 87)..moveTo(50, 38)..lineTo(29, 26)..moveTo(50, 52)..lineTo(72, 38)..moveTo(50, 67)..lineTo(31, 56)..moveTo(50, 78)..lineTo(68, 64), ink);
        canvas.drawPath(Path()..moveTo(50, 18)..lineTo(68, 31)..lineTo(57, 52)..close(), Paint()..color = bright.withValues(alpha: opacity * .14));
        break;
      case NebulaMaterial.aurora:
        for (var i = 0; i < 4; i++) {
          final y = 20.0 + i * 19;
          final path = Path()..moveTo(-8, y + 8)..cubicTo(16, y - 25, 28, y + 25, 51, y)..cubicTo(73, y - 23, 86, y + 25, 108, y - 5);
          canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round
            ..strokeWidth = i == 0 ? 3.5 : 1.25
            ..color = (i.isEven ? bright : accent).withValues(alpha: opacity * (i == 0 ? .46 : .33))
            ..maskFilter = i == 0 ? ui.MaskFilter.blur(ui.BlurStyle.normal, 2.5) : null);
          canvas.drawPath(path, i.isEven ? lightInk : ink);
        }
        break;
      case NebulaMaterial.sapphire:
        final gem = Path()..moveTo(50, 7)..lineTo(89, 35)..lineTo(75, 79)..lineTo(50, 94)..lineTo(25, 79)..lineTo(11, 35)..close();
        canvas.drawPath(gem, Paint()..color = accent.withValues(alpha: opacity * .10));
        canvas.drawPath(gem, lightInk);
        canvas.drawPath(Path()..moveTo(11, 35)..lineTo(50, 48)..lineTo(89, 35)..moveTo(25, 79)..lineTo(50, 48)..lineTo(75, 79)..moveTo(50, 7)..lineTo(50, 48), ink);
        canvas.drawPath(Path()..moveTo(50, 9)..lineTo(80, 34)..lineTo(50, 44)..close(), Paint()..color = bright.withValues(alpha: opacity * .20));
        canvas.drawPath(Path()..moveTo(50, 48)..lineTo(25, 79)..lineTo(50, 88)..close(), Paint()..color = deep.withValues(alpha: opacity * .22));
        break;
      case NebulaMaterial.amber:
        for (var row = -1; row < 4; row++) {
          for (var col = -1; col < 4; col++) {
            final x = col * 30.0 + (row.isEven ? 0 : 15);
            final y = row * 26.0;
            final cell = Path()..moveTo(x + 15, y)..lineTo(x + 30, y + 8)..lineTo(x + 30, y + 24)..lineTo(x + 15, y + 32)..lineTo(x, y + 24)..lineTo(x, y + 8)..close();
            canvas.drawPath(cell, ink);
          }
        }
        canvas.drawCircle(const Offset(34, 37), 10, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = bright.withValues(alpha: opacity * .55));
        canvas.drawCircle(const Offset(34, 37), 4, Paint()..color = bright.withValues(alpha: opacity * .20));
        canvas.drawCircle(const Offset(70, 68), 3, Paint()..color = bright.withValues(alpha: opacity * .8));
        break;
      case NebulaMaterial.onyx:
        for (final radius in const [18.0, 28.0, 39.0, 47.0]) {
          canvas.drawCircle(const Offset(50, 50), radius, Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = radius == 28 ? 1.9 : .8
            ..color = (radius == 28 ? bright : edge).withValues(alpha: opacity * (radius == 28 ? .56 : .35)));
        }
        canvas.drawLine(const Offset(8, 25), const Offset(92, 25), ink);
        canvas.drawLine(const Offset(8, 76), const Offset(92, 76), ink);
        canvas.drawCircle(const Offset(50, 50), 5, Paint()..color = Colors.black.withValues(alpha: opacity * .8));
        break;
      case NebulaMaterial.pearl:
        for (var i = 0; i < 7; i++) {
          canvas.drawArc(Rect.fromCircle(center: const Offset(50, 55), radius: 13 + i * 6.1), pi * 1.03, pi * .93, false, i.isEven ? lightInk : ink);
        }
        canvas.drawCircle(const Offset(69, 27), 17, Paint()..shader = RadialGradient(
          center: const Alignment(-.35, -.45),
          colors: [Colors.white.withValues(alpha: opacity * .65), bright.withValues(alpha: opacity * .55), deep.withValues(alpha: opacity * .2)],
        ).createShader(const Rect.fromLTWH(52, 10, 34, 34)));
        canvas.drawCircle(const Offset(69, 27), 17, Paint()..style = PaintingStyle.stroke..strokeWidth = .7..color = bright.withValues(alpha: opacity * .7));
        break;
      case NebulaMaterial.ivory:
        canvas.drawPath(Path()..moveTo(12, 78)..lineTo(12, 41)..quadraticBezierTo(50, -4, 88, 41)..lineTo(88, 78), lightInk);
        canvas.drawPath(Path()..moveTo(22, 78)..lineTo(22, 44)..quadraticBezierTo(50, 12, 78, 44)..lineTo(78, 78), ink);
        canvas.drawPath(Path()..moveTo(32, 78)..quadraticBezierTo(34, 43, 50, 60)..quadraticBezierTo(66, 43, 68, 78), ink);
        canvas.drawLine(const Offset(8, 84), const Offset(92, 84), lightInk);
        for (final x in const [20.0, 80.0]) {
          canvas.drawCircle(Offset(x, 31), 2.1, Paint()..color = bright.withValues(alpha: opacity * .82));
        }
        break;
      case NebulaMaterial.imperial:
        final shield = Path()..moveTo(50, 6)..lineTo(89, 21)..lineTo(83, 59)..lineTo(50, 93)..lineTo(17, 59)..lineTo(11, 21)..close();
        canvas.drawPath(shield, Paint()..color = deep.withValues(alpha: opacity * .18));
        canvas.drawPath(shield, lightInk);
        canvas.drawPath(Path()..moveTo(50, 18)..lineTo(50, 79)..moveTo(27, 33)..lineTo(50, 44)..lineTo(73, 33)..moveTo(34, 59)..lineTo(50, 70)..lineTo(66, 59), ink);
        for (final point in const [Offset(20, 25), Offset(80, 25), Offset(50, 81)]) {
          canvas.drawCircle(point, 3.2, Paint()..color = bright.withValues(alpha: opacity * .8));
          canvas.drawCircle(point, 5.5, Paint()..style = PaintingStyle.stroke..strokeWidth = .7..color = accent.withValues(alpha: opacity * .5));
        }
        break;
      case NebulaMaterial.ruby:
      case NebulaMaterial.nightDemon:
      case NebulaMaterial.godly:
        break;
    }

    // Specular hotspot, two fine bevels, and a dark lower edge make the surface read as glass/metal.
    canvas.drawRect(rect, Paint()
      ..blendMode = BlendMode.screen
      ..shader = RadialGradient(
        center: Alignment(-.92, -1),
        radius: 1.05,
        colors: [bright.withValues(alpha: opacity * .17), Colors.transparent],
      ).createShader(rect));
    canvas.drawLine(const Offset(1, 1), const Offset(99, 1), Paint()..strokeWidth = .8..color = bright.withValues(alpha: opacity * .58));
    canvas.drawLine(const Offset(1, 1), const Offset(1, 99), Paint()..strokeWidth = .8..color = bright.withValues(alpha: opacity * .31));
    canvas.drawLine(const Offset(1, 99), const Offset(99, 99), Paint()..strokeWidth = .8..color = Colors.black.withValues(alpha: opacity * .38));
    canvas.restore();

    canvas.drawRRect(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bright.withValues(alpha: edge.a * opacity),
            edge.withValues(alpha: edge.a * opacity),
            accent.withValues(alpha: opacity * .6),
          ],
        ).createShader(rect),
    );
    return recorder.endRecording();
  }
}

// Bat-Glass 2.0 material: a cut red diamond (ruby crystal).
// Irregular triangular facets (jittered grid, seeded so the cut is stable), each lit according to a
// pseudo normal against a light from the top left, a translucent body so that the content behind
// shows through, bright bevelled edges, a table highlight and a darker pavilion at the bottom.
// Static (no animation) so it costs almost nothing; `glint` (0..1) optionally sweeps a light across the facets.
class DiamondDecoration extends Decoration {
  final double glint;
  final double opacity;

  const DiamondDecoration({this.glint = -1, this.opacity = .86});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _CrystalPainter(glint, opacity);

  @override
  bool operator ==(Object other) => other is DiamondDecoration && other.glint == glint && other.opacity == opacity;

  @override
  int get hashCode => Object.hash(glint, opacity);
}

class _CrystalPainter extends BoxPainter {
  final double glint, opacity;

  _CrystalPainter(this.glint, this.opacity);

  static const _cell = 46.0;
  static const _body = [Color(0xFFFF4A66), Color(0xFFD81B3F), Color(0xFF8E0E2B), Color(0xFF4A0414)];

  // shared by all painters, so that animating the glint does not cut the crystal again at every frame
  static final Map<Size, List<_Facet>> _cache = {};
  List<_Facet> _facets = const [];

  void _build(Size size) {
    final cached = _cache.remove(size);
    if (cached != null) {
      _cache[size] = cached;
      _facets = cached;
      return;
    }
    final cols = (size.width / _cell).ceil() + 1;
    final rows = (size.height / _cell).ceil() + 1;
    final cw = size.width / (cols - 1 == 0 ? 1 : cols - 1);
    final ch = size.height / (rows - 1 == 0 ? 1 : rows - 1);
    final rnd = Random(7);
    // jittered lattice; border points stay on the border so the crystal fills the rect
    final pts = List.generate(rows, (r) {
      return List.generate(cols, (c) {
        var x = c * cw, y = r * ch;
        if (c > 0 && c < cols - 1) x += (rnd.nextDouble() - .5) * cw * .7;
        if (r > 0 && r < rows - 1) y += (rnd.nextDouble() - .5) * ch * .7;
        return Offset(x, y);
      });
    });
    final facets = <_Facet>[];
    for (var r = 0; r < rows - 1; r++) {
      for (var c = 0; c < cols - 1; c++) {
        final a = pts[r][c], b = pts[r][c + 1], d = pts[r + 1][c], e = pts[r + 1][c + 1];
        final flip = rnd.nextBool();
        final tris = flip ? [[a, b, e], [a, e, d]] : [[a, b, d], [b, e, d]];
        for (final t in tris) {
          // pseudo normal: random tilt, giving each facet its own reflection
          facets.add(_Facet(t, rnd.nextDouble() * 2 - 1, rnd.nextDouble() * 2 - 1));
        }
      }
    }
    _facets = facets;
    _cache[size] = facets;
    while (_cache.length > 12) {
      _cache.remove(_cache.keys.first);
    }
  }

  // the static crystal is recorded once per size and replayed, so animating the glint only costs one gradient per frame
  static final Map<(Size, double), ui.Picture> _pictures = {};

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null || size.isEmpty) return;
    final key = (size, opacity);
    // Keep recently used sizes hot; evict one old picture instead of rebuilding
    // every crystal when a grid changes between its common tile dimensions.
    final cached = _pictures.remove(key);
    final picture = cached ?? _record(size);
    _pictures[key] = picture;
    while (_pictures.length > 12) {
      _pictures.remove(_pictures.keys.first)?.dispose();
    }

    canvas.save();
    canvas.clipRect(offset & size);
    canvas.translate(offset.dx, offset.dy);
    canvas.drawPicture(picture);
    if (glint >= 0) {
      // soft diagonal band of light sweeping across the stone
      final pos = glint * 1.5 - .25;
      final band = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [Color(0x00FFFFFF), Color(0x55FFFFFF), Color(0x00FFFFFF)],
            stops: [(pos - .14).clamp(0.0, 1.0), pos.clamp(0.0, 1.0), (pos + .14).clamp(0.0, 1.0)],
          ).createShader(band),
      );
    }
    canvas.restore();
  }

  ui.Picture _record(Size size) {
    _build(size);
    final recorder = ui.PictureRecorder();
    _draw(Canvas(recorder), size);
    return recorder.endRecording();
  }

  void _draw(Canvas canvas, Size size) {
    final local = Offset.zero & size;
    // translucent body, brighter at the top left, deep at the bottom right
    canvas.drawRect(
      local,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [for (final c in _body) c.withValues(alpha: opacity)],
          stops: const [0, .35, .72, 1],
        ).createShader(local),
    );

    final fill = Paint()..style = PaintingStyle.fill;
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7
      ..strokeJoin = StrokeJoin.round;
    for (final f in _facets) {
      final path = Path()
        ..moveTo(f.p[0].dx, f.p[0].dy)
        ..lineTo(f.p[1].dx, f.p[1].dy)
        ..lineTo(f.p[2].dx, f.p[2].dy)
        ..close();
      // light from the top left: facets facing it are lit, the others fall into shade
      final lit = (-f.nx * .6 - f.ny * .8);
      final k = lit;
      if (k > 0) {
        fill.color = Colors.white.withValues(alpha: (k * .20).clamp(0, .55));
      } else {
        fill.color = const Color(0xFF200008).withValues(alpha: (-k * .30).clamp(0, .45));
      }
      canvas.drawPath(path, fill);
      edge.color = Colors.white.withValues(alpha: .10 + (lit > 0 ? lit * .22 : 0));
      canvas.drawPath(path, edge);
    }

    // table highlight: a bright soft band near the top, like the flat top face of the stone
    final table = Rect.fromLTWH(0, 0, size.width, size.height * .42);
    canvas.drawRect(
      table,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x55FFFFFF), Color(0x00FFFFFF)],
        ).createShader(table),
    );
    // pavilion: darker bottom, to give depth
    final pavilion = Rect.fromLTWH(0, size.height * .55, size.width, size.height * .45);
    canvas.drawRect(
      pavilion,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0x55200008)],
        ).createShader(pavilion),
    );
    // specular corner light
    canvas.drawRect(
      local,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment.topLeft,
          radius: .9,
          colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
        ).createShader(local),
    );
    // bevelled rim: bright on top/left, dark on bottom/right
    final rim = Paint()..strokeWidth = 1.2;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), rim..color = const Color(0xAAFFFFFF));
    canvas.drawLine(Offset.zero, Offset(0, size.height), rim..color = const Color(0x66FFFFFF));
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), rim..color = const Color(0x66000000));
  }
}

class _Facet {
  final List<Offset> p;
  final double nx, ny;
  late final Offset centroid = Offset((p[0].dx + p[1].dx + p[2].dx) / 3, (p[0].dy + p[1].dy + p[2].dy) / 3);

  _Facet(this.p, this.nx, this.ny);
}

// the glass material of the theme, with a light glint sweeping across it every few seconds
// (the cracks of the demon glass flare up instead)
class AnimatedCrystal extends StatefulWidget {
  final bool animate;
  final double opacity;
  final NebulaMaterial material;
  final Widget child;

  const AnimatedCrystal({super.key, required this.animate, this.opacity = .86, this.material = NebulaMaterial.ruby, required this.child});

  @override
  State<AnimatedCrystal> createState() => _AnimatedCrystalState();
}

class _AnimatedCrystalState extends State<AnimatedCrystal> with SingleTickerProviderStateMixin {
  // the glint is only visible during the first part of the cycle, the rest of the cycle is a static rest
  static const _cycle = Duration(seconds: 7);
  static const _glintEnd = .45;
  static const _rest = Duration(milliseconds: 3850);

  late final AnimationController _controller = AnimationController(vsync: this, duration: _cycle);
  Timer? _restTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTick);
    if (widget.animate) _startGlint();
  }

  void _startGlint() {
    _restTimer?.cancel();
    _restTimer = null;
    _controller.forward(from: 0);
  }

  void _onTick() {
    if (_controller.value < _glintEnd) return;
    // the glint is over: pause instead of rebuilding the static crystal for the rest of the cycle
    _controller.stop(canceled: false);
    // resume at the same point of the 7s cycle, so the total period is unchanged
    _restTimer?.cancel();
    _restTimer = Timer(_rest, () {
      _restTimer = null;
      if (mounted) _startGlint();
    });
  }

  @override
  void didUpdateWidget(covariant AnimatedCrystal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate == oldWidget.animate) return;
    if (widget.animate) {
      _startGlint();
    } else {
      _restTimer?.cancel();
      _restTimer = null;
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) return DecoratedBox(decoration: nebulaMaterialDecoration(widget.material, opacity: widget.opacity), child: widget.child);
    // only the crystal layer repaints while the glint moves; the content on top stays untouched
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              // the glint crosses during the first part of the cycle, then the stone rests
              builder: (context, _) => DecoratedBox(
                decoration: nebulaMaterialDecoration(
                  widget.material,
                  phase: _controller.value < _glintEnd ? _controller.value / _glintEnd : -1,
                  opacity: widget.opacity,
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}
