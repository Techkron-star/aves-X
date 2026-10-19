import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

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

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null || size.isEmpty) return;
    final rect = offset & size;
    _build(size);

    canvas.save();
    canvas.clipRect(rect);
    canvas.translate(offset.dx, offset.dy);
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
    final diag = size.width + size.height;
    for (final f in _facets) {
      final path = Path()
        ..moveTo(f.p[0].dx, f.p[0].dy)
        ..lineTo(f.p[1].dx, f.p[1].dy)
        ..lineTo(f.p[2].dx, f.p[2].dy)
        ..close();
      // light from the top left: facets facing it are lit, the others fall into shade
      final lit = (-f.nx * .6 - f.ny * .8);
      var c = f.centroid;
      var k = lit;
      if (glint >= 0) {
        // moving glint band: facets lighten when the band crosses them
        final pos = glint * 1.6 - .3;
        final d = ((c.dx + c.dy) / diag - pos).abs();
        k += max(0, 1 - d / .12) * 1.4;
      }
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
    canvas.restore();
  }
}

class _Facet {
  final List<Offset> p;
  final double nx, ny;
  late final Offset centroid = Offset((p[0].dx + p[1].dx + p[2].dx) / 3, (p[0].dy + p[1].dy + p[2].dy) / 3);

  _Facet(this.p, this.nx, this.ny);
}

// the crystal with a light glint sweeping across it every few seconds
class AnimatedCrystal extends StatefulWidget {
  final bool animate;
  final Widget child;

  const AnimatedCrystal({super.key, required this.animate, required this.child});

  @override
  State<AnimatedCrystal> createState() => _AnimatedCrystalState();
}

class _AnimatedCrystalState extends State<AnimatedCrystal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 7));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) return DecoratedBox(decoration: const DiamondDecoration(), child: widget.child);
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      // the glint crosses during the first part of the cycle, then the stone rests
      builder: (context, child) => DecoratedBox(
        decoration: DiamondDecoration(glint: _controller.value < .45 ? _controller.value / .45 : -1),
        child: child,
      ),
    );
  }
}
