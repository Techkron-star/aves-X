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
      final style = nebulaMaterials.values.firstWhere((style) => style.material == material);
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

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null || size.isEmpty) return;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(size.width / 100, size.height / 100);

    const rect = Rect.fromLTWH(0, 0, 100, 100);
    final radius = switch (style.material) {
      NebulaMaterial.hermetic || NebulaMaterial.voidGlass || NebulaMaterial.imperial => 4.0,
      NebulaMaterial.pearl || NebulaMaterial.aurora => 20.0,
      NebulaMaterial.solarFlare => 13.0,
      NebulaMaterial.forge || NebulaMaterial.neon || NebulaMaterial.sapphire => 8.0,
      _ => 12.0,
    };
    final shape = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            style.surface.withValues(alpha: opacity),
            style.liquidDeep.withValues(alpha: opacity * .62),
            style.surface.withValues(alpha: opacity),
          ],
          stops: const [0, .58, 1],
        ).createShader(rect),
    );

    canvas.save();
    canvas.clipRRect(shape);
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.6
      ..color = style.accent.withValues(alpha: opacity * .34);
    final lightInk = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.0
      ..color = style.liquidHighlight.withValues(alpha: opacity * .52);

    switch (style.material) {
      case NebulaMaterial.forge:
        canvas.drawPath(Path()..moveTo(-5, 73)..cubicTo(18, 46, 29, 79, 48, 42)..cubicTo(63, 14, 78, 43, 105, 13), lightInk);
        canvas.drawPath(Path()..moveTo(-5, 88)..cubicTo(24, 65, 40, 94, 63, 57)..cubicTo(77, 35, 91, 62, 105, 44), ink);
        break;
      case NebulaMaterial.hermetic:
        canvas.drawCircle(const Offset(50, 50), 35, ink);
        canvas.drawPath(Path()..moveTo(50, 14)..lineTo(84, 77)..lineTo(16, 77)..close(), lightInk);
        canvas.drawCircle(const Offset(50, 50), 6, ink);
        break;
      case NebulaMaterial.eclipse:
        canvas.drawCircle(const Offset(53, 47), 34, lightInk);
        canvas.drawCircle(const Offset(67, 34), 28, Paint()..color = style.surface.withValues(alpha: opacity));
        canvas.drawArc(Rect.fromCircle(center: const Offset(50, 50), radius: 42), -.85, 2.3, false, ink);
        break;
      case NebulaMaterial.solarFlare:
        for (var i = 0; i < 16; i++) {
          final angle = i * pi / 8;
          canvas.drawLine(
            Offset(50 + cos(angle) * 30, 50 + sin(angle) * 30),
            Offset(50 + cos(angle) * 47, 50 + sin(angle) * 47),
            i.isEven ? lightInk : ink,
          );
        }
        canvas.drawCircle(const Offset(50, 50), 23, ink);
        break;
      case NebulaMaterial.voidGlass:
        for (final radius in const [24.0, 34.0, 44.0]) {
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
        break;
      case NebulaMaterial.crimson:
        for (var i = 0; i < 4; i++) {
          final x = i * 28.0 - 16;
          canvas.drawPath(Path()..moveTo(x, 22)..lineTo(x + 30, 50)..lineTo(x + 10, 78), i.isEven ? lightInk : ink);
        }
        break;
      case NebulaMaterial.neon:
        for (var i = -2; i < 8; i++) {
          canvas.drawLine(Offset(i * 22.0, 0), Offset(i * 22.0 + 48, 100), i.isEven ? lightInk : ink);
          canvas.drawLine(Offset(0, i * 22.0 + 12), Offset(100, i * 22.0 - 12), ink);
        }
        break;
      case NebulaMaterial.emerald:
        canvas.drawPath(Path()..moveTo(50, 9)..cubicTo(86, 31, 78, 70, 50, 91)..cubicTo(22, 70, 14, 31, 50, 9)..close(), lightInk);
        canvas.drawPath(Path()..moveTo(50, 17)..cubicTo(48, 42, 52, 63, 50, 84)..moveTo(50, 39)..lineTo(31, 28)..moveTo(50, 54)..lineTo(70, 40)..moveTo(50, 68)..lineTo(34, 58), ink);
        break;
      case NebulaMaterial.aurora:
        canvas.drawPath(Path()..moveTo(-6, 29)..cubicTo(16, 5, 29, 55, 50, 29)..cubicTo(70, 3, 82, 55, 106, 24), lightInk);
        canvas.drawPath(Path()..moveTo(-6, 49)..cubicTo(18, 25, 33, 73, 52, 49)..cubicTo(73, 23, 85, 73, 106, 44), ink);
        canvas.drawPath(Path()..moveTo(-6, 69)..cubicTo(15, 47, 31, 91, 53, 69)..cubicTo(75, 45, 88, 91, 106, 64), lightInk);
        break;
      case NebulaMaterial.sapphire:
        canvas.drawPath(Path()..moveTo(50, 8)..lineTo(91, 39)..lineTo(72, 83)..lineTo(50, 94)..lineTo(28, 83)..lineTo(9, 39)..close(), lightInk);
        canvas.drawPath(Path()..moveTo(9, 39)..lineTo(50, 51)..lineTo(91, 39)..moveTo(28, 83)..lineTo(50, 51)..lineTo(72, 83), ink);
        break;
      case NebulaMaterial.amber:
        for (var row = -1; row < 4; row++) {
          for (var col = -1; col < 4; col++) {
            final x = col * 30.0 + (row.isEven ? 0 : 15);
            final y = row * 26.0;
            canvas.drawPath(Path()..moveTo(x + 15, y)..lineTo(x + 30, y + 8)..lineTo(x + 30, y + 24)..lineTo(x + 15, y + 32)..lineTo(x, y + 24)..lineTo(x, y + 8)..close(), ink);
          }
        }
        break;
      case NebulaMaterial.onyx:
        for (final radius in const [20.0, 31.0, 43.0]) {
          final ring = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = radius == 31 ? 2.3 : 1.2
            ..color = radius == 31 ? style.liquidHighlight.withValues(alpha: opacity * .52) : ink.color;
          canvas.drawCircle(const Offset(50, 50), radius, ring);
        }
        break;
      case NebulaMaterial.pearl:
        for (var i = 0; i < 6; i++) {
          canvas.drawArc(Rect.fromCircle(center: const Offset(50, 52), radius: 12 + i * 7.0), pi * 1.05, pi * .88, false, i.isEven ? lightInk : ink);
        }
        canvas.drawCircle(const Offset(50, 15), 2.5, Paint()..color = style.liquidHighlight.withValues(alpha: opacity * .78));
        break;
      case NebulaMaterial.ivory:
        canvas.drawPath(Path()..moveTo(12, 72)..lineTo(12, 40)..quadraticBezierTo(50, -3, 88, 40)..lineTo(88, 72), lightInk);
        canvas.drawPath(Path()..moveTo(27, 72)..quadraticBezierTo(34, 41, 50, 59)..quadraticBezierTo(66, 41, 73, 72), ink);
        break;
      case NebulaMaterial.imperial:
        canvas.drawPath(Path()..moveTo(50, 7)..lineTo(89, 22)..lineTo(83, 59)..lineTo(50, 91)..lineTo(17, 59)..lineTo(11, 22)..close(), lightInk);
        canvas.drawLine(const Offset(50, 20), const Offset(50, 79), ink);
        for (final point in const [Offset(20, 28), Offset(80, 28), Offset(50, 80)]) {
          canvas.drawCircle(point, 2.5, Paint()..color = style.liquidHighlight.withValues(alpha: opacity * .78));
        }
        break;
      case NebulaMaterial.ruby:
      case NebulaMaterial.nightDemon:
      case NebulaMaterial.godly:
        break;
    }

    if (phase >= 0) {
      final band = Rect.fromLTWH(-30 + phase * 150, -8, 34, 116);
      canvas.drawRect(
        band,
        Paint()..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x00FFFFFF), Color(0x44FFFFFF), Color(0x00FFFFFF)],
          stops: [0, .5, 1],
        ).createShader(band),
      );
    }
    canvas.restore();
    canvas.drawRRect(shape, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = style.edge.withValues(alpha: opacity * .8));
    canvas.restore();
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
    final cached = _cache[size];
    if (cached != null) {
      _facets = cached;
      return;
    }
    if (_cache.length > 8) _cache.clear();
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
    _facets = _cache[size] = facets;
  }

  // the static crystal is recorded once per size and replayed, so animating the glint only costs one gradient per frame
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
    final picture = _pictures[(size, opacity)] ??= _record(size);

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
