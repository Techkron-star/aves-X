import 'dart:math' as math;
import 'dart:ui' show BlurStyle, MaskFilter, Path, StrokeCap;
import 'package:flutter/material.dart';
import 'package:aves/theme/nebula/nebula_theme.dart';

// Nebula Engine — visual soul layer.
// Each theme is built from a small number of deterministic vector primitives,
// gradients and glows. The important rule is that the animation describes a
// material or a world; it is never decorative noise.

abstract class NebulaEffect extends StatelessWidget {
  final bool animate;
  const NebulaEffect({super.key, required this.animate});
  CustomPainter painter(double t);
  Duration get duration => const Duration(seconds: 14);
  bool get reverse => false;

  @override
  Widget build(BuildContext context) => _NebulaEffectHost(
    animate: animate,
    duration: duration,
    reverse: reverse,
    painterBuilder: painter,
  );
}

class _NebulaEffectHost extends StatefulWidget {
  final bool animate;
  final Duration duration;
  final bool reverse;
  final CustomPainter Function(double) painterBuilder;
  const _NebulaEffectHost({required this.animate, required this.duration, required this.reverse, required this.painterBuilder});
  @override
  State<_NebulaEffectHost> createState() => _NebulaEffectHostState();
}

class _NebulaEffectHostState extends State<_NebulaEffectHost> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration);
  @override
  void initState() { super.initState(); if (widget.animate) _controller.repeat(reverse: widget.reverse); }
  @override
  void didUpdateWidget(covariant _NebulaEffectHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) _controller.repeat(reverse: widget.reverse);
    if (!widget.animate && _controller.isAnimating) _controller.stop();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (_, __) => RepaintBoundary(child: CustomPaint(
      painter: widget.painterBuilder(_controller.value),
      isComplex: true,
      willChange: widget.animate,
    )),
  );
}

abstract class NebulaEffectPainter extends CustomPainter {
  final double t;
  const NebulaEffectPainter(this.t);
  @override
  bool shouldRepaint(covariant NebulaEffectPainter old) => old.t != t;
}

class _SoulEffect extends NebulaEffect {
  final Duration cycle;
  final bool pingPong;
  final NebulaEffectPainter Function(double) builder;
  const _SoulEffect({required super.animate, required this.cycle, this.pingPong = false, required this.builder});
  @override Duration get duration => cycle;
  @override bool get reverse => pingPong;
  @override CustomPainter painter(double t) => builder(t);
}

class _ObsidianPainter extends NebulaEffectPainter {
  const _ObsidianPainter(super.t);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height, m = s.shortestSide;
    final center = Offset(w * .52, h * .46);
    final r = m * .31;
    final pulse = .5 + .5 * math.sin(t * math.pi * 2);

    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(.08, -.18),
          radius: 1.05,
          colors: const [
            Color(0x332D1252),
            Color(0x18150825),
            Colors.transparent,
          ],
          stops: const [0, .48, 1],
        ).createShader(Offset.zero & s),
    );

    // A fractured volcanic-glass monolith: broad facets first, razor edges last.
    final silhouette = Path()
      ..moveTo(center.dx - r * .28, center.dy - r)
      ..lineTo(center.dx + r * .54, center.dy - r * .72)
      ..lineTo(center.dx + r, center.dy - r * .06)
      ..lineTo(center.dx + r * .62, center.dy + r * .78)
      ..lineTo(center.dx - r * .12, center.dy + r)
      ..lineTo(center.dx - r, center.dy + r * .22)
      ..lineTo(center.dx - r * .76, center.dy - r * .55)
      ..close();
    c.drawPath(
      silhouette,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF392052),
            Color(0xFF100B1A),
            Color(0xFF25103B),
            Color(0xFF050308),
          ],
          stops: [0, .34, .7, 1],
        ).createShader(Rect.fromCircle(center: center, radius: r * 1.5)),
    );

    final facets = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.bevel
      ..strokeWidth = 1.1
      ..color = const Color(0x887F51B4);
    final facetPaths = <Path>[
      Path()..moveTo(center.dx - r * .28, center.dy - r)..lineTo(center.dx - r * .08, center.dy + r * .05)..lineTo(center.dx - r, center.dy + r * .22),
      Path()..moveTo(center.dx - r * .08, center.dy + r * .05)..lineTo(center.dx + r * .54, center.dy - r * .72)..lineTo(center.dx + r * .28, center.dy + r * .14)..close(),
      Path()..moveTo(center.dx + r * .28, center.dy + r * .14)..lineTo(center.dx + r, center.dy - r * .06)..lineTo(center.dx + r * .62, center.dy + r * .78),
      Path()..moveTo(center.dx - r * .08, center.dy + r * .05)..lineTo(center.dx + r * .62, center.dy + r * .78)..lineTo(center.dx - r * .12, center.dy + r),
    ];
    for (final path in facetPaths) {
      c.drawPath(path, facets);
    }

    final crackGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 5
      ..color = Color(0x449B5DE5).withValues(alpha: .18 + pulse * .13)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    final crack = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.35
      ..color = Color(0xFFBE91FF).withValues(alpha: .65 + pulse * .28);
    final fissures = <Path>[
      Path()..moveTo(center.dx - r * .08, center.dy + r * .05)..lineTo(center.dx + r * .02, center.dy - r * .18)..lineTo(center.dx - r * .1, center.dy - r * .34),
      Path()..moveTo(center.dx + r * .02, center.dy - r * .18)..lineTo(center.dx + r * .29, center.dy - r * .1)..lineTo(center.dx + r * .45, center.dy - r * .27),
      Path()..moveTo(center.dx + r * .02, center.dy - r * .18)..lineTo(center.dx + r * .15, center.dy + r * .26)..lineTo(center.dx + r * .42, center.dy + r * .42),
      Path()..moveTo(center.dx + r * .15, center.dy + r * .26)..lineTo(center.dx - r * .04, center.dy + r * .45),
      Path()..moveTo(center.dx - r * .1, center.dy - r * .34)..lineTo(center.dx - r * .31, center.dy - r * .47),
    ];
    for (final path in fissures) {
      c.drawPath(path, crackGlow);
      c.drawPath(path, crack);
    }

    // A sparse orbit of cold motes; positions are deterministic and motion is slow.
    for (var i = 0; i < 11; i++) {
      final a = t * math.pi * 2 + i * 2.399963;
      final orbit = r * (.98 + (i % 3) * .22);
      final p = Offset(
        center.dx + math.cos(a) * orbit,
        center.dy + math.sin(a * .82) * orbit * .78,
      );
      final alpha = .3 + .55 * (.5 + .5 * math.sin(a * 1.7));
      c.drawCircle(p, i % 4 == 0 ? 2.0 : 1.1, Paint()..color = const Color(0xFFCAA5FF).withValues(alpha: alpha));
    }
  }
}

class _AureatePainter extends NebulaEffectPainter {
  const _AureatePainter(super.t);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height, m = s.shortestSide;
    final center = Offset(w * .5, h * .45);
    final r = m * .27;
    final angle = t * math.pi * 2;
    final pulse = .5 + .5 * math.sin(angle);

    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -.12),
          radius: 1.12,
          colors: const [
            Color(0x33B8860B),
            Color(0x1C5B3A08),
            Colors.transparent,
          ],
          stops: const [0, .52, 1],
        ).createShader(Offset.zero & s),
    );

    // Antique-gold astrolabe / reliquary: engraved rings, sun rays and a raised seal.
    final rayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeWidth = 1.2
      ..color = const Color(0x55F5D77E);
    for (var i = 0; i < 24; i++) {
      final a = i * math.pi / 12 + angle * .025;
      final inner = i.isEven ? r * 1.12 : r * 1.2;
      final outer = r * (i.isEven ? 1.43 : 1.32);
      c.drawLine(
        center + Offset(math.cos(a) * inner, math.sin(a) * inner),
        center + Offset(math.cos(a) * outer, math.sin(a) * outer),
        rayPaint,
      );
    }

    final outerRect = Rect.fromCircle(center: center, radius: r * 1.08);
    c.drawCircle(center, r * 1.08, Paint()..color = const Color(0x443D2808));
    c.drawCircle(
      center,
      r * 1.08,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0x99C69A35),
    );
    c.drawCircle(
      center,
      r * .94,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x88FFE8A0),
    );
    c.drawArc(
      outerRect,
      angle * .18,
      math.pi * 1.18,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = Color(0xFFFFE8A0).withValues(alpha: .55 + pulse * .35),
    );
    c.drawArc(
      outerRect,
      math.pi + angle * .18,
      math.pi * .42,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFFD4AF37),
    );

    final seal = Path()
      ..moveTo(center.dx, center.dy - r * .72)
      ..lineTo(center.dx + r * .58, center.dy - r * .34)
      ..lineTo(center.dx + r * .48, center.dy + r * .38)
      ..lineTo(center.dx, center.dy + r * .72)
      ..lineTo(center.dx - r * .48, center.dy + r * .38)
      ..lineTo(center.dx - r * .58, center.dy - r * .34)
      ..close();
    c.drawPath(
      seal,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE9A3),
            Color(0xFF9B6A12),
            Color(0xFF2A1A06),
            Color(0xFFD5A52B),
          ],
          stops: [0, .3, .68, 1],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
    c.drawPath(
      seal,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFFFE9A3),
    );

    final engraving = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xCCFFF0BD);
    c.drawLine(center + Offset(0, -r * .47), center + Offset(0, r * .47), engraving);
    c.drawLine(center + Offset(-r * .36, -r * .05), center + Offset(r * .36, -r * .05), engraving);
    c.drawCircle(center, r * .16, Paint()..color = const Color(0xFFFFE9A3));
    c.drawCircle(
      center,
      r * (.17 + pulse * .025),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = const Color(0x99FFF2C0),
    );

    // Tiny brass inlays around the medallion, not a constant particle storm.
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6 - angle * .035;
      final p = center + Offset(math.cos(a) * r * 1.52, math.sin(a) * r * 1.52);
      c.drawCircle(p, i.isEven ? 1.8 : 1.1, Paint()..color = const Color(0xCCF5D77E));
    }
  }
}

class _ForgePainter extends NebulaEffectPainter {
  const _ForgePainter(super.t);
  @override void paint(Canvas c, Size s) {
    final w=s.width,h=s.height,m=math.min(w,h),p=.5+.5*math.sin(t*2*math.pi);
    final bg=Paint()..shader=RadialGradient(colors: const [Color(0x664D1B0A),Color(0x33160B20),Colors.transparent]).createShader(Rect.fromCircle(center: Offset(w*.5,h*.72),radius:m*.9));
    c.drawRect(Offset.zero& s,bg);
    final plate=Paint()..style=PaintingStyle.stroke..strokeWidth=m*.018..color=const Color(0x447A6A63);
    for(var i=0;i<3;i++){ final y=h*(.28+i*.2); c.drawLine(Offset(w*.08,y),Offset(w*.92,y),plate); }
    final glow=Paint()..style=PaintingStyle.stroke..strokeCap=StrokeCap.round..strokeWidth=m*(.045+.012*p)..color=const Color(0x44FF6D00)..maskFilter=const MaskFilter.blur(BlurStyle.normal,9);
    final hot=Paint()..style=PaintingStyle.stroke..strokeCap=StrokeCap.round..strokeWidth=m*.009..color=const Color(0xFFFFA11A);
    for(var i=0;i<4;i++){
      final x=w*(.16+i*.22); final path=Path()..moveTo(x,h*.94)..cubicTo(x-m*.08,h*.7,x+m*.1,h*.54,x-m*.015,h*.16);
      c.drawPath(path,glow); c.drawPath(path,hot);
    }
    final rnd=math.Random(41); final dot=Paint();
    for(var i=0;i<28;i++){final q=(t*(1+rnd.nextInt(3))+(i*.071))%1; final x=(rnd.nextDouble()*w+math.sin(q*8+i)*10); final y=h*(.9-q*.78); final a=math.sin(math.pi*q); dot.color=const Color(0xFFFFC247).withValues(alpha:a*.8); c.drawCircle(Offset(x,y),.7+rnd.nextDouble()*1.5,dot);}
  }
}

class _HermeticPainter extends NebulaEffectPainter {
  const _HermeticPainter(super.t);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height, m = s.shortestSide;
    final center = Offset(w * .5, h * .49);
    final r = m * .235;
    final phase = t * math.pi * 2;
    final pulse = .5 + .5 * math.sin(phase);

    c.drawRect(Offset.zero & s, Paint()..shader = const RadialGradient(
      center: Alignment(0, -.05), radius: 1.05,
      colors: [Color(0xFF07120F), Color(0xFF0B0B1B), Color(0xFF03050A)],
      stops: [0, .58, 1],
    ).createShader(Offset.zero & s));
    c.drawCircle(center, r * 1.85, Paint()
      ..color = const Color(0x1835D8A0)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24));

    // Fine orbit traces and a vertical measuring axis establish an instrument, not a generic seal.
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(phase * .025);
    for (var i = 0; i < 3; i++) {
      final rr = r * (1.08 + i * .20);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: rr * 2.0, height: rr * (1.36 + i * .12)),
        Paint()..style = PaintingStyle.stroke..strokeWidth = .8
          ..color = i == 1 ? const Color(0x664CDBA0) : const Color(0x334B8F7D));
    }
    c.restore();

    // Broken alchemical rings have different radii and rotation; lit segments move independently.
    for (var i = 0; i < 5; i++) {
      final rr = r * (.63 + i * .19);
      final rot = phase * (i.isEven ? .045 : -.032) + i * .91;
      final rect = Rect.fromCircle(center: center, radius: rr);
      c.drawArc(rect, rot, math.pi * (i.isEven ? 1.38 : .72), false,
        Paint()..style = PaintingStyle.stroke..strokeWidth = i == 2 ? 1.5 : .85
          ..color = i.isEven ? const Color(0x6645D9A1) : const Color(0x557F70C9));
      c.drawArc(rect, rot + math.pi * 1.12, math.pi * .19, false,
        Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round
          ..strokeWidth = 3.0..color = const Color(0x5535D8A0)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      c.drawArc(rect, rot + math.pi * 1.12, math.pi * .19, false,
        Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round
          ..strokeWidth = 1.2..color = const Color(0xFFD5FFE8));
    }

    // A fourfold apparatus: diamond frame, opposing triangles, and a central dark prism.
    final diamond = Path()
      ..moveTo(center.dx, center.dy - r * .98)
      ..lineTo(center.dx + r * .62, center.dy)
      ..lineTo(center.dx, center.dy + r * .98)
      ..lineTo(center.dx - r * .62, center.dy)..close();
    final triangle = Path()
      ..moveTo(center.dx, center.dy - r * .66)
      ..lineTo(center.dx + r * .56, center.dy + r * .31)
      ..lineTo(center.dx - r * .56, center.dy + r * .31)..close();
    final inverted = Path()
      ..moveTo(center.dx, center.dy + r * .66)
      ..lineTo(center.dx + r * .56, center.dy - r * .31)
      ..lineTo(center.dx - r * .56, center.dy - r * .31)..close();
    final frameGlow = Paint()..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.bevel
      ..strokeWidth = 5..color = Color(0xFF35D8A0).withValues(alpha: .09 + pulse * .10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    final frameInk = Paint()..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.bevel
      ..strokeWidth = 1.05..color = const Color(0xAA9FEAC4);
    for (final path in [diamond, triangle, inverted]) {
      c.drawPath(path, frameGlow);
      c.drawPath(path, frameInk);
    }

    // Engraved ticks are grouped like calibrated markings, with four longer cardinal cuts.
    for (var i = 0; i < 32; i++) {
      final a = i * math.pi / 16 - phase * .018;
      final major = i % 4 == 0;
      final inner = r * (major ? 1.17 : 1.22);
      final outer = r * (major ? 1.39 : 1.30);
      c.drawLine(center + Offset(math.cos(a) * inner, math.sin(a) * inner),
        center + Offset(math.cos(a) * outer, math.sin(a) * outer),
        Paint()..strokeWidth = major ? 1.4 : .7
          ..color = major ? const Color(0xAA68E5B2) : const Color(0x5574A998));
    }

    // Four hanging keys orbit the frame, each with a moving spark at its tip.
    for (var i = 0; i < 4; i++) {
      final a = phase * .035 + i * math.pi / 2 + .28;
      final p = center + Offset(math.cos(a) * r * 1.02, math.sin(a) * r * 1.02);
      final key = Path()
        ..moveTo(p.dx, p.dy)
        ..lineTo(p.dx + math.cos(a) * r * .17, p.dy + math.sin(a) * r * .17)
        ..lineTo(p.dx + math.cos(a + .28) * r * .23, p.dy + math.sin(a + .28) * r * .23);
      c.drawPath(key, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4
        ..color = const Color(0xAA9D83D9));
      c.drawCircle(p, 3.2, Paint()..color = const Color(0x5535D8A0)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      c.drawCircle(p, 1.15, Paint()..color = const Color(0xFFE2FFF0));
    }

    // The philosopher's stone is a faceted, dark crystal with a breathing emerald seam.
    final stone = Path()
      ..moveTo(center.dx, center.dy - r * .32)
      ..lineTo(center.dx + r * .23, center.dy - r * .08)
      ..lineTo(center.dx + r * .18, center.dy + r * .24)
      ..lineTo(center.dx, center.dy + r * .36)
      ..lineTo(center.dx - r * .2, center.dy + r * .19)
      ..lineTo(center.dx - r * .24, center.dy - r * .1)..close();
    c.drawPath(stone, Paint()..shader = const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF315C4C), Color(0xFF0B1716), Color(0xFF563C78), Color(0xFF07100D)],
      stops: [0, .34, .68, 1],
    ).createShader(Rect.fromCenter(center: center, width: r * .6, height: r * .8)));
    final seam = Path()..moveTo(center.dx, center.dy - r * .25)
      ..lineTo(center.dx - r * .06, center.dy + r * .02)
      ..lineTo(center.dx + r * .03, center.dy + r * .29);
    c.drawPath(seam, Paint()..style = PaintingStyle.stroke..strokeWidth = 6
      ..color = Color(0xFF35D8A0).withValues(alpha: .10 + pulse * .18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    c.drawPath(seam, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.25
      ..color = Color(0xFFB8FFE0).withValues(alpha: .48 + pulse * .45));

    // Small orbiting motes move on two different paths, like energy caught in the apparatus.
    for (var i = 0; i < 12; i++) {
      final a = phase * (i.isEven ? .09 : -.06) + i * 2.399963;
      final d = r * (1.48 + (i % 3) * .10);
      final p = center + Offset(math.cos(a) * d, math.sin(a * .83) * d * .8);
      c.drawCircle(p, i % 4 == 0 ? 1.55 : .8,
        Paint()..color = (i.isEven ? const Color(0xFF75F0B9) : const Color(0xFFB6A2F7))
          .withValues(alpha: .3 + .55 * (.5 + .5 * math.sin(phase + i))));
    }
  }
}
class _EclipsePainter extends NebulaEffectPainter {
  const _EclipsePainter(super.t);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height, m = s.shortestSide;
    final center = Offset(w * .51, h * .46);
    final r = m * .225;
    final phase = t * math.pi * 2;
    final pulse = .5 + .5 * math.sin(phase);
    final eclipseShift = Offset(r * (.20 + .025 * math.sin(phase)), -r * .035);

    // The shadow is an event crossing the atmosphere, not a ring around a badge.
    c.drawRect(Offset.zero & s, Paint()..shader = const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF030B17), Color(0xFF071B2A), Color(0xFF030611)],
      stops: [0, .52, 1],
    ).createShader(Offset.zero & s));
    c.drawCircle(center + Offset(-r * .18, -r * .05), r * 2.05,
      Paint()..shader = RadialGradient(colors: [
        const Color(0x0037DFFF),
        Color(0x1837DFFF).withValues(alpha: .08 + pulse * .08),
        Colors.transparent,
      ], stops: const [0, .56, 1]).createShader(Rect.fromCircle(center: center, radius: r * 2.05)));

    // A tilted, broken atmospheric band gives the silhouette a directional sweep.
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(-.23 + .025 * math.sin(phase));
    final bandRect = Rect.fromCenter(center: Offset.zero, width: r * 4.5, height: r * 2.3);
    c.drawOval(bandRect, Paint()..style = PaintingStyle.stroke..strokeWidth = r * .36
      ..color = const Color(0x1439CFF8)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
    c.drawArc(bandRect, math.pi * 1.08 + phase * .025, math.pi * .67, false,
      Paint()..style = PaintingStyle.stroke..strokeWidth = r * .13
        ..shader = const SweepGradient(colors: [
          Colors.transparent, Color(0x0039CFF8), Color(0xAA47DFFF),
          Color(0xFFDBFCFF), Color(0x5539CFF8), Colors.transparent,
        ], stops: [0, .12, .36, .48, .67, 1]).createShader(bandRect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    c.restore();

    // Irregular corona filaments flare only along the exposed crescent.
    for (var i = 0; i < 13; i++) {
      final a = -math.pi * .92 + i * math.pi * 1.66 / 12;
      final inner = center + Offset(math.cos(a) * r * 1.02, math.sin(a) * r * 1.02);
      final outer = center + Offset(math.cos(a) * r * (1.20 + .11 * math.sin(phase + i * .8)),
          math.sin(a) * r * (1.20 + .11 * math.sin(phase + i * .8)));
      final bend = center + Offset(math.cos(a + .11) * r * 1.42, math.sin(a + .11) * r * 1.42);
      final filament = Path()..moveTo(inner.dx, inner.dy)..quadraticBezierTo(bend.dx, bend.dy, outer.dx, outer.dy);
      c.drawPath(filament, Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round
        ..strokeWidth = 3.5..color = const Color(0x4439DFFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      c.drawPath(filament, Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round
        ..strokeWidth = .8..color = const Color(0xCCBDF8FF));
    }

    // The occulting body is deliberately offset: its crescent is the subject.
    final bodyRect = Rect.fromCircle(center: center, radius: r);
    c.drawCircle(center, r * 1.025, Paint()..color = const Color(0xFF0A2635));
    c.drawCircle(center, r, Paint()..shader = const RadialGradient(
      center: Alignment(-.42, -.38), radius: 1.15,
      colors: [Color(0xFF172C3B), Color(0xFF050B14), Color(0xFF010309)],
      stops: [0, .52, 1],
    ).createShader(bodyRect));
    c.drawCircle(center + eclipseShift, r * .99, Paint()..color = const Color(0xFF01040A));

    // A thin, cold edge follows the actual crescent gap, with a travelling hot spot.
    final crescent = Path()
      ..moveTo(center.dx + r * .18, center.dy - r * .98)
      ..cubicTo(center.dx + r * .94, center.dy - r * .62,
          center.dx + r * .98, center.dy + r * .56, center.dx + r * .24, center.dy + r * .96);
    c.drawPath(crescent, Paint()..style = PaintingStyle.stroke..strokeWidth = 7
      ..color = Color(0x3339DFFF).withValues(alpha: .15 + pulse * .18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    c.drawPath(crescent, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5
      ..color = const Color(0xFFBDF8FF));
    final hot = center + Offset(math.cos(phase * .3) * r * .92, math.sin(phase * .3) * r * .72);
    c.drawCircle(hot, 4.5, Paint()..color = const Color(0x7739DFFF)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    c.drawCircle(hot, 1.5, Paint()..color = const Color(0xFFF0FFFF));

    // Cracks are embedded in the dark mass; the glow travels through branches.
    final cracks = <Path>[
      Path()..moveTo(center.dx-r*.62,center.dy-r*.18)..lineTo(center.dx-r*.28,center.dy-r*.03)..lineTo(center.dx-r*.12,center.dy-r*.32)..lineTo(center.dx+r*.16,center.dy-r*.22),
      Path()..moveTo(center.dx-r*.28,center.dy-r*.03)..lineTo(center.dx-r*.36,center.dy+r*.29)..lineTo(center.dx-r*.08,center.dy+r*.46),
      Path()..moveTo(center.dx-r*.12,center.dy-r*.32)..lineTo(center.dx+r*.02,center.dy-r*.56),
      Path()..moveTo(center.dx+r*.16,center.dy-r*.22)..lineTo(center.dx+r*.38,center.dy-r*.02)..lineTo(center.dx+r*.31,center.dy+r*.26),
    ];
    for (var i = 0; i < cracks.length; i++) {
      final alpha = .10 + .24 * (.5 + .5 * math.sin(phase - i * .7));
      c.drawPath(cracks[i], Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round..strokeWidth = 6
        ..color = Color(0xFF31DFFF).withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      c.drawPath(cracks[i], Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round..strokeWidth = 1.1
        ..color = Color(0xFFD9FBFF).withValues(alpha: .35 + .55 * (.5 + .5 * math.sin(phase - i * .7))));
    }

    // Dust lanes drift tangentially; no random work is performed per frame.
    for (var i = 0; i < 18; i++) {
      final a = phase * .045 + i * 2.399963;
      final d = r * (1.55 + (i % 4) * .13);
      final p = center + Offset(math.cos(a) * d * 1.35, math.sin(a * .82) * d * .62);
      c.drawCircle(p, i % 5 == 0 ? 1.7 : .8,
        Paint()..color = const Color(0xAA8DEEFF).withValues(alpha: .35 + .5 * (.5 + .5 * math.sin(phase + i))));
    }
  }
}
class _SolarPainter extends NebulaEffectPainter {
  const _SolarPainter(super.t);
  @override void paint(Canvas c,Size s){final w=s.width,h=s.height,pulse=.5+.5*math.sin(t*2*math.pi);
    c.drawRect(Offset.zero&s,Paint()..shader=RadialGradient(center:Alignment(0,-.9),radius:1.2,colors:[Color(0x33FFF3C4).withValues(alpha:.5+.2*pulse),Color(0x22FF6D00),Colors.transparent]).createShader(Offset.zero&s));
    final rnd=math.Random(9);final cloud=Paint();for(var i=0;i<10;i++){final q=(t+rnd.nextDouble())%1;final x=rnd.nextDouble()*w+math.sin(q*6+i)*18;final y=h*(1.08-q*1.1);final rr=s.shortestSide*(.09+rnd.nextDouble()*.12);cloud.shader=RadialGradient(colors:[const Color(0x55FFB300),const Color(0x00FF6D00)]).createShader(Rect.fromCircle(center:Offset(x,y),radius:rr));c.drawCircle(Offset(x,y),rr,cloud);}
    final arc=Paint()..style=PaintingStyle.stroke..strokeCap=StrokeCap.round;for(var i=0;i<3;i++){final q=(t+i/3)%1,g=math.sin(math.pi*q);final x=w*(.2+i*.3);final path=Path()..moveTo(x-w*.1,h)..cubicTo(x-w*.06,h-h*.55*g,x+w*.06,h-h*.55*g,x+w*.1,h);arc..strokeWidth=7..color=const Color(0x66FF6D00)..maskFilter=const MaskFilter.blur(BlurStyle.normal,5);c.drawPath(path,arc);arc..strokeWidth=1.5..color=const Color(0xDDFFF3C4)..maskFilter=null;c.drawPath(path,arc);}
  }
}

class _VoidPainter extends NebulaEffectPainter {
  const _VoidPainter(super.t);
  @override void paint(Canvas c,Size s){final cx=s.width*.5,cy=s.height*.5,r=s.shortestSide*.18;final p=Paint()..style=PaintingStyle.stroke..strokeWidth=.8..color=const Color(0x553DFF88);
    for(var i=-8;i<=8;i++){final x=s.width*.5+i*s.width*.055; c.drawLine(Offset(cx+(x-cx)*.22,cy-r),Offset(x,s.height),p);}
    for(var i=0;i<11;i++){final y=cy+r+i*i*s.height*.018;final q=Path()..moveTo(0,y)..quadraticBezierTo(cx,cy+r+i*s.height*.015,s.width,y);c.drawPath(q,p);}
    c.drawCircle(Offset(cx,cy),r*1.8,Paint()..color=const Color(0x553DFF88)..maskFilter=const MaskFilter.blur(BlurStyle.normal,18));
    c.drawCircle(Offset(cx,cy),r,Paint()..shader=RadialGradient(colors:const[Color(0xFF020A06),Color(0xFF000000)]).createShader(Rect.fromCircle(center:Offset(cx,cy),radius:r)));
    final a=t*2*math.pi;for(var i=0;i<16;i++){final q=a+i*.8;final d=r*1.3+math.sin(q*2)*r*.3;c.drawCircle(Offset(cx+math.cos(q)*d,cy+math.sin(q)*d),1.2,Paint()..color=const Color(0xAA5DFF9B));}
  }
}

class _CrimsonPainter extends NebulaEffectPainter {
  const _CrimsonPainter(super.t);
  @override void paint(Canvas c,Size s){final o=Offset(s.width*.5,s.height*.5),r=s.shortestSide*.26,p=.5+.5*math.sin(t*2*math.pi);
    final path=Path()..moveTo(o.dx,o.dy-r)..lineTo(o.dx+r*.78,o.dy-r*.45)..lineTo(o.dx+r,o.dy+r*.42)..lineTo(o.dx+r*.2,o.dy+r)..lineTo(o.dx-r*.65,o.dy+r*.8)..lineTo(o.dx-r,o.dy)..lineTo(o.dx-r*.55,o.dy-r*.7)..close();
    c.drawPath(path,Paint()..shader=LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:const[Color(0xFF7E102A),Color(0xFF23040D),Color(0xFFB51D45)]).createShader(Rect.fromCircle(center:o,radius:r)));
    final crack=Paint()..style=PaintingStyle.stroke..strokeWidth=1.8..color=const Color(0xCCFF365E);final q=Path()..moveTo(o.dx-r*.72,o.dy-r*.25)..lineTo(o.dx-r*.12,o.dy-r*.05)..lineTo(o.dx+r*.18,o.dy+r*.42)..lineTo(o.dx+r*.65,o.dy+r*.2);c.drawPath(q,crack);
    c.drawCircle(o,r*(.18+.035*p),Paint()..color=const Color(0x55FF1744)..maskFilter=const MaskFilter.blur(BlurStyle.normal,12));
  }
}

class _NeonPainter extends NebulaEffectPainter {
  const _NeonPainter(super.t);
  @override void paint(Canvas c,Size s){final a=t*2*math.pi,w=s.width,h=s.height;final glow=Paint()..style=PaintingStyle.stroke..strokeCap=StrokeCap.round..strokeWidth=10..maskFilter=const MaskFilter.blur(BlurStyle.normal,10);final line=Paint()..style=PaintingStyle.stroke..strokeCap=StrokeCap.round..strokeWidth=2.2;
    for(var i=0;i<4;i++){final y=h*(.22+i*.18)+math.sin(a+i)*8;final path=Path()..moveTo(w*.08,y)..cubicTo(w*.28,y-20,w*.42,y+24,w*.62,y)..cubicTo(w*.78,y-24,w*.82,y+18,w*.94,y-4);glow.color=(i.isEven?const Color(0x7740D9FF):const Color(0x77FF2BC2));c.drawPath(path,glow);line.color=i.isEven?const Color(0xFF4FE7FF):const Color(0xFFFF4DCE);c.drawPath(path,line);}
    c.drawRect(Offset(w*.06,h*.82)&Size(w*.88,h*.012),Paint()..color=const Color(0x4479E8FF));
  }
}

class _EmeraldPainter extends NebulaEffectPainter {
  const _EmeraldPainter(super.t);
  @override void paint(Canvas c,Size s){final o=Offset(s.width*.5,s.height*.52),r=s.shortestSide*.3,a=t*2*math.pi;
    final rock=Path()..moveTo(o.dx-r*.2,o.dy-r)..lineTo(o.dx+r*.7,o.dy-r*.5)..lineTo(o.dx+r,o.dy+r*.35)..lineTo(o.dx+r*.2,o.dy+r)..lineTo(o.dx-r*.7,o.dy+r*.75)..lineTo(o.dx-r,o.dy-r*.05)..close();c.drawPath(rock,Paint()..shader=LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:const[Color(0xFF0E5D43),Color(0xFF031B13),Color(0xFF1B8B5E)]).createShader(Rect.fromCircle(center:o,radius:r)));
    final vein=Paint()..style=PaintingStyle.stroke..strokeWidth=1.8..color=const Color(0xCCDBB84A);for(var i=0;i<6;i++){final q=i*.9;final path=Path()..moveTo(o.dx-r*.8+math.sin(q)*r*.2,o.dy+r*.55)..cubicTo(o.dx-r*.35,o.dy+r*.1,o.dx+r*.05,o.dy-r*.25,o.dx+r*.7*math.cos(q+a),o.dy-r*.65);c.drawPath(path,vein);}
    c.drawCircle(o,r*.75,Paint()..style=PaintingStyle.stroke..strokeWidth=1..color=const Color(0x334DE3A1));
  }
}

class _AuroraPainter extends NebulaEffectPainter {
  const _AuroraPainter(super.t);
  @override void paint(Canvas c,Size s){final w=s.width,h=s.height,a=t*2*math.pi;for(var i=0;i<6;i++){final x=w*(.08+i*.17);final path=Path()..moveTo(x,h)..cubicTo(x+w*.08,h*.65,x-w*.1,h*.35,x+w*.02,h*.05);final p=Paint()..style=PaintingStyle.stroke..strokeWidth=w*.10..strokeCap=StrokeCap.round..color=(i.isEven?const Color(0x2238F0B0):const Color(0x2238BFFF));p.maskFilter=const MaskFilter.blur(BlurStyle.normal,16);c.save();c.translate(math.sin(a+i)*10,0);c.drawPath(path,p);c.restore();}
    final dust=Paint();final rnd=math.Random(12);for(var i=0;i<22;i++){final x=rnd.nextDouble()*w;final y=h*(.1+rnd.nextDouble()*.8);dust.color=const Color(0x667CE8D0).withValues(alpha:.15+.15*math.sin(a+i));c.drawCircle(Offset(x,y),.8,dust);}
  }
}

class _SapphirePainter extends NebulaEffectPainter {
  const _SapphirePainter(super.t);
  @override void paint(Canvas c,Size s){final o=Offset(s.width*.5,s.height*.5),r=s.shortestSide*.29,a=t*2*math.pi;final outer=Path()..moveTo(o.dx,o.dy-r)..lineTo(o.dx+r*.72,o.dy-r*.28)..lineTo(o.dx+r*.92,o.dy+r*.45)..lineTo(o.dx+r*.15,o.dy+r)..lineTo(o.dx-r*.72,o.dy+r*.62)..lineTo(o.dx-r*.95,o.dy-r*.18)..close();c.drawPath(outer,Paint()..shader=LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:const[Color(0xFF123E8E),Color(0xFF03102D),Color(0xFF1C63D0)]).createShader(Rect.fromCircle(center:o,radius:r)));
    final facet=Paint()..style=PaintingStyle.stroke..strokeWidth=1.1..color=const Color(0x779AF5FF);for(var i=0;i<5;i++){final q=a+i*1.256;final pt=o+Offset(math.cos(q)*r*.82,math.sin(q)*r*.82);c.drawLine(o,pt,facet);}c.drawPath(outer,facet);
    final ray=Paint()..style=PaintingStyle.stroke..strokeWidth=2..color=const Color(0xAA9AF5FF);final q=a; c.drawLine(o+Offset(math.cos(q)*r*.35,math.sin(q)*r*.35),o+Offset(math.cos(q)*r*.95,math.sin(q)*r*.95),ray);
  }
}

class _AmberPainter extends NebulaEffectPainter {
  const _AmberPainter(super.t);
  @override void paint(Canvas c,Size s){final o=Offset(s.width*.5,s.height*.5),r=s.shortestSide*.3,a=t*2*math.pi;final blob=Path()..moveTo(o.dx-r*.5,o.dy-r*.75)..cubicTo(o.dx+r*.65,o.dy-r*.9,o.dx+r*.85,o.dy+r*.3,o.dx+r*.25,o.dy+r*.85)..cubicTo(o.dx-r*.55,o.dy+r*.8,o.dx-r*.8,o.dy-r*.1,o.dx-r*.5,o.dy-r*.75)..close();c.drawPath(blob,Paint()..shader=RadialGradient(colors:const[Color(0xFFFFD46A),Color(0xFFB95B0A),Color(0xFF5C2503)]).createShader(Rect.fromCircle(center:o,radius:r*1.2)));
    final fossil=Paint()..style=PaintingStyle.stroke..strokeWidth=1.3..color=const Color(0x66804412);final fp=Path()..moveTo(o.dx-r*.4,o.dy+r*.35)..cubicTo(o.dx-r*.1,o.dy,o.dx+r*.1,o.dy-r*.3,o.dx+r*.42,o.dy-r*.52);c.drawPath(fp,fossil);for(var i=0;i<5;i++){final q=a+i*.9;c.drawCircle(o+Offset(math.cos(q)*r*.45,math.sin(q)*r*.45),1.4,Paint()..color=const Color(0x88FFF0A3));}
    c.drawCircle(o+Offset(math.cos(a)*r*.35,math.sin(a)*r*.35),r*.15,Paint()..color=const Color(0x44FFF3B0)..maskFilter=const MaskFilter.blur(BlurStyle.normal,8));
  }
}

class _OnyxPainter extends NebulaEffectPainter {
  const _OnyxPainter(super.t);
  @override void paint(Canvas c,Size s){final o=Offset(s.width*.5,s.height*.52),r=s.shortestSide*.31,a=t*2*math.pi;final shape=Path()..moveTo(o.dx-r*.72,o.dy-r*.55)..lineTo(o.dx+r*.45,o.dy-r*.78)..lineTo(o.dx+r*.9,o.dy+r*.35)..lineTo(o.dx+r*.1,o.dy+r*.78)..lineTo(o.dx-r*.78,o.dy+r*.42)..close();c.drawPath(shape,Paint()..shader=LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:const[Color(0xFF08090B),Color(0xFF1A1B1F),Color(0xFF030405)]).createShader(Rect.fromCircle(center:o,radius:r)));
    final hi=Paint()..style=PaintingStyle.stroke..strokeWidth=2.4..color=const Color(0x667F858D);final x=o.dx+math.sin(a)*r*.8;c.drawLine(Offset(x-r*.55,o.dy-r*.75),Offset(x+r*.3,o.dy+r*.65),hi);c.drawPath(shape,Paint()..style=PaintingStyle.stroke..strokeWidth=1..color=const Color(0x55666B73));
  }
}

class _PearlPainter extends NebulaEffectPainter {
  const _PearlPainter(super.t);
  @override void paint(Canvas c,Size s){final o=Offset(s.width*.5,s.height*.5),r=s.shortestSide*.32,a=t*2*math.pi;final pearl=Paint()..shader=SweepGradient(colors:const[Color(0xFFEFFAFF),Color(0xFFF0D9F4),Color(0xFFD9F5F0),Color(0xFFFFE7D0),Color(0xFFEFFAFF)],transform:GradientRotation(a)).createShader(Rect.fromCircle(center:o,radius:r));c.drawCircle(o,r,pearl);c.drawCircle(o,r,Paint()..style=PaintingStyle.stroke..strokeWidth=2..color=const Color(0x66FFFFFF));for(var i=0;i<7;i++){final q=a+i*.897;final d=r*(.35+i*.055);c.drawArc(Rect.fromCircle(center:o,radius:d),q,.8, false,Paint()..style=PaintingStyle.stroke..strokeWidth=1.2..color=Color(0x55FFFFFF).withValues(alpha:.35));}}
}

class _IvoryPainter extends NebulaEffectPainter {
  const _IvoryPainter(super.t);
  @override void paint(Canvas c,Size s){final o=Offset(s.width*.5,s.height*.5),r=s.shortestSide*.34,a=t*2*math.pi;c.drawCircle(o,r,Paint()..shader=RadialGradient(colors:const[Color(0xFFFFFBEE),Color(0xFFE9DCC1),Color(0xFF8B7657)]).createShader(Rect.fromCircle(center:o,radius:r)));final fil=Paint()..style=PaintingStyle.stroke..strokeWidth=1..color=const Color(0x665E4A2E);for(var i=0;i<8;i++){final q=i*math.pi/4+a*.15;final p=Path()..moveTo(o.dx+math.cos(q)*r*.22,o.dy+math.sin(q)*r*.22)..cubicTo(o.dx+math.cos(q+.4)*r*.5,o.dy+math.sin(q+.4)*r*.5,o.dx+math.cos(q+.8)*r*.7,o.dy+math.sin(q+.8)*r*.7,o.dx+math.cos(q+1.2)*r*.88,o.dy+math.sin(q+1.2)*r*.88);c.drawPath(p,fil);}c.drawCircle(o,r*.68,Paint()..style=PaintingStyle.stroke..strokeWidth=1..color=const Color(0x44D8B96B));}
}

class _ImperialPainter extends NebulaEffectPainter {
  const _ImperialPainter(super.t);
  void gear(Canvas c,Offset o,double r,double rot){final p=Paint()..style=PaintingStyle.stroke..strokeWidth=r*.08..color=const Color(0x669D8A68);c.save();c.translate(o.dx,o.dy);c.rotate(rot);for(var i=0;i<10;i++){final a=i*math.pi/5; c.drawLine(Offset(math.cos(a)*r*.72,math.sin(a)*r*.72),Offset(math.cos(a)*r,math.sin(a)*r),p);}c.drawCircle(Offset.zero,r*.68,p);c.restore();}
  @override void paint(Canvas c,Size s){final o=Offset(s.width*.5,s.height*.55),m=s.shortestSide;gear(c,o-Offset(m*.18,0),m*.13,t*2*math.pi);gear(c,o+Offset(m*.17,m*.05),m*.18,-t*2*math.pi*1.1);c.drawRect(Offset.zero&s,Paint()..shader=LinearGradient(colors:const[Color(0x221A1814),Color(0x00000000)]).createShader(Offset.zero&s));final riv=Paint()..color=const Color(0xFFD4A72A);for(var i=0;i<8;i++){final a=i*math.pi/4;c.drawCircle(o+Offset(math.cos(a)*m*.37,math.sin(a)*m*.3),2.2,riv);}}
}

class _AbyssPainter extends NebulaEffectPainter {
  const _AbyssPainter(super.t);
  @override void paint(Canvas c,Size s){final w=s.width,h=s.height,a=t*2*math.pi; c.drawRect(Offset.zero&s,Paint()..shader=LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:const[Color(0x2200C7D9),Color(0x08102C43),Color(0x33000112)]).createShader(Offset.zero&s));
    for(var i=0;i<4;i++){final x=w*(.15+i*.24)+math.sin(a+i)*8;final p=Path()..moveTo(x-w*.04,0)..lineTo(x+w*.04,0)..lineTo(x+w*.16,h)..lineTo(x-w*.16,h)..close();c.drawPath(p,Paint()..color=const Color(0x1124E6E0));}
    for(var i=0;i<5;i++){final q=(t+i*.2)%1;final x=w*(.12+i*.19)+math.sin(q*math.pi*2+i)*18;final y=h*(.35+q*.55);final r=s.shortestSide*.035;final p=Paint()..color=const Color(0x8836F5E6)..maskFilter=const MaskFilter.blur(BlurStyle.normal,7);c.drawOval(Rect.fromCenter(center:Offset(x,y),width:r*2.2,height:r*1.2),p);for(var j=0;j<3;j++){final path=Path()..moveTo(x-r+j*r*.5,y+r*.45)..quadraticBezierTo(x-r+j*r*.5+math.sin(q*7+j)*8,y+r*1.6,x-r+j*r*.5,y+r*2.5);c.drawPath(path,Paint()..style=PaintingStyle.stroke..strokeWidth=1..color=const Color(0x664FEFE2));}}
    final rnd=math.Random(55);for(var i=0;i<28;i++){final x=rnd.nextDouble()*w,y=h*(.25+rnd.nextDouble()*.7);c.drawCircle(Offset(x,y),.7,Paint()..color=const Color(0x889AF9EF));}
  }
}

class _SakuraPainter extends NebulaEffectPainter {
  const _SakuraPainter(super.t);
  @override void paint(Canvas c,Size s){final w=s.width,h=s.height,a=t*2*math.pi;final moon=Offset(w*.72,h*.22),mr=s.shortestSide*.11;c.drawCircle(moon,mr,Paint()..shader=RadialGradient(colors:const[Color(0xFFFBEEDB),Color(0x55FBEEDB),Colors.transparent]).createShader(Rect.fromCircle(center:moon,radius:mr*2.5)));c.drawCircle(moon,mr,Paint()..color=const Color(0xDDF7EBD9));
    c.drawRect(Offset(0,h*.72)&Size(w,h*.28),Paint()..shader=LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:const[Color(0x335E5260),Color(0x00000000)]).createShader(Rect.fromLTWH(0,h*.6,w,h*.4)));
    final rnd=math.Random(73);for(var i=0;i<34;i++){final q=(t*(.45+rnd.nextDouble())+i*.083)%1;final x=(rnd.nextDouble()*w+math.sin(q*6+i)*18)%w;final y=h*(.1+q*.95);final rot=math.sin(q*5+i);c.save();c.translate(x,y);c.rotate(rot);c.drawOval(Rect.fromCenter(center:Offset.zero,width:5,height:2.8),Paint()..color=(i.isEven?const Color(0xD9F29AB0):const Color(0xC9D85B72)));c.restore();}
  }
}

NebulaEffect? nebulaEffectFor(NebulaTheme theme, {required bool animate}) {
  switch(theme){
    // Keep the Aves default and the established Nosferatu Glass treatment intact.
    // Obsidian and Aureate now have their own richer, deterministic material studies.
    case NebulaTheme.aves:
    case NebulaTheme.nosferatuGlass:
      return null;
    case NebulaTheme.obsidianGlass:
      return _SoulEffect(animate: animate, cycle: const Duration(seconds: 28), builder: (t) => _ObsidianPainter(t), pingPong: true);
    case NebulaTheme.aureateGlass:
      return _SoulEffect(animate: animate, cycle: const Duration(seconds: 32), builder: (t) => _AureatePainter(t), pingPong: true);
    case NebulaTheme.forgeGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:12),builder:(t)=>_ForgePainter(t),pingPong:true);
    case NebulaTheme.hermeticGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:18),builder:(t)=>_HermeticPainter(t));
    case NebulaTheme.eclipseGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:22),builder:(t)=>_EclipsePainter(t));
    case NebulaTheme.solarFlareGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:14),builder:(t)=>_SolarPainter(t));
    case NebulaTheme.voidGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:20),builder:(t)=>_VoidPainter(t));
    case NebulaTheme.crimsonGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:16),builder:(t)=>_CrimsonPainter(t),pingPong:true);
    case NebulaTheme.neonGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:11),builder:(t)=>_NeonPainter(t));
    case NebulaTheme.emeraldGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:19),builder:(t)=>_EmeraldPainter(t));
    case NebulaTheme.auroraGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:24),builder:(t)=>_AuroraPainter(t),pingPong:true);
    case NebulaTheme.sapphireGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:17),builder:(t)=>_SapphirePainter(t));
    case NebulaTheme.amberGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:21),builder:(t)=>_AmberPainter(t));
    case NebulaTheme.onyxGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:26),builder:(t)=>_OnyxPainter(t));
    case NebulaTheme.pearlGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:23),builder:(t)=>_PearlPainter(t));
    case NebulaTheme.ivoryGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:25),builder:(t)=>_IvoryPainter(t));
    case NebulaTheme.imperialGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:18),builder:(t)=>_ImperialPainter(t));
    case NebulaTheme.abyssalGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:20),builder:(t)=>_AbyssPainter(t));
    case NebulaTheme.sakuraGlass:
      return _SoulEffect(animate:animate,cycle:const Duration(seconds:17),builder:(t)=>_SakuraPainter(t));
  }
}
