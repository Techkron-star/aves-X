import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

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

// the crystal with a light glint sweeping across it every few seconds
class AnimatedCrystal extends StatefulWidget {
  final bool animate;
  final double opacity;
  final Widget child;

  const AnimatedCrystal({super.key, required this.animate, this.opacity = .86, required this.child});

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
    if (!widget.animate) return DecoratedBox(decoration: DiamondDecoration(opacity: widget.opacity), child: widget.child);
    // only the crystal layer repaints while the glint moves; the content on top stays untouched
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              // the glint crosses during the first part of the cycle, then the stone rests
              builder: (context, _) => DecoratedBox(
                decoration: DiamondDecoration(glint: _controller.value < _glintEnd ? _controller.value / _glintEnd : -1, opacity: widget.opacity),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}
