import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui' show BlurStyle, MaskFilter, Path, StrokeCap;
import 'package:flutter/material.dart';
import 'package:aves/theme/nebula/nebula_effect.dart';

// Signature effects of the Nebula themes that have their own hand-made animation:
// Night Demon, Godly, Imperial, Solar Flare, Forge, Hermetic, Eclipse, Crimson and Emerald.
// They live in their own file, and `nebulaEffectFor` delegates to them, so that a rewrite of the
// shared effect layer does not erase them. Every loop is seamless (whole cycles per loop, no reverse).

// ============================================================================
// Night Demon — purple hellfire (Obsidian Glass)
// ============================================================================

/// Night Demon: brasas violeta que suben desde un resplandor de fuego que respira
/// en la base, sobre un círculo de invocación casi invisible que gira muy despacio.
class NightDemonEffect extends NebulaEffect {
  const NightDemonEffect({super.key, required super.animate});

  @override
  Duration get duration => const Duration(seconds: 16);

  @override
  bool get reverse => false;

  @override
  CustomPainter painter(double t) => _NightDemonPainter(t);
}

class _NightDemonPainter extends NebulaEffectPainter {
  const _NightDemonPainter(super.t);

  static const _violet = Color(0xFF9B5DE5);
  static const _hot = Color(0xFFE9D5FF);
  static const _embers = 34;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final breath = .5 + .5 * math.sin(t * 2 * math.pi * 2);

    // hellfire breathing at the base
    final base = Rect.fromLTWH(0, h * .55, w, h * .45);
    canvas.drawRect(
      base,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [_violet.withValues(alpha: .16 + .12 * breath), _violet.withValues(alpha: 0)],
        ).createShader(base),
    );

    // faint summoning circle: turning 90 degrees per loop, which the 12 ticks hide (the loop has no seam)
    final c = Offset(w / 2, h * .78);
    final r = math.min(w, h) * .38;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _violet.withValues(alpha: .08 + .05 * breath);
    canvas.drawCircle(c, r, ring);
    canvas.drawCircle(c, r * .82, ring);
    final tick = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = _violet.withValues(alpha: .14);
    for (var i = 0; i < 12; i++) {
      final a = t * math.pi / 2 + i * 2 * math.pi / 12;
      final inner = r * (i.isEven ? .7 : .78);
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * inner,
        c + Offset(math.cos(a), math.sin(a)) * (r * .96),
        tick,
      );
    }

    // embers rising; each one makes a whole number of trips per loop, so the loop has no seam
    final rnd = math.Random(666);
    final paint = Paint();
    for (var i = 0; i < _embers; i++) {
      final x0 = rnd.nextDouble();
      final phase = rnd.nextDouble();
      final sway = rnd.nextDouble() * 2 * math.pi;
      final trips = 1 + rnd.nextInt(3);
      final radius = .8 + rnd.nextDouble() * 2.2;
      final hot = rnd.nextBool();
      final progress = (t * trips + phase) % 1.0;
      final fade = math.sin(math.pi * progress);
      final x = x0 * w + math.sin(progress * 2 * math.pi * 2 + sway) * 14;
      final y = h * (1.02 - progress * 1.04);
      final color = hot ? _hot : _violet;
      paint.color = color.withValues(alpha: .10 * fade);
      canvas.drawCircle(Offset(x, y), radius * 3.2, paint);
      paint.color = color.withValues(alpha: .65 * fade);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
}

// ============================================================================
// Godly — divine light on gold (Aureate Glass)
// ============================================================================

/// Godly: rayos de luz que bajan de un halo y se mecen despacio, con motas de oro
/// que flotan y centellean.
class GodlyEffect extends NebulaEffect {
  const GodlyEffect({super.key, required super.animate});

  @override
  Duration get duration => const Duration(seconds: 18);

  @override
  bool get reverse => false;

  @override
  CustomPainter painter(double t) => _GodlyPainter(t);
}

class _GodlyPainter extends NebulaEffectPainter {
  const _GodlyPainter(super.t);

  static const _gold = Color(0xFFFFE9A3);
  static const _light = Color(0xFFFFF6D5);
  static const _motes = 26;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cycle = math.sin(t * 2 * math.pi);

    // halo above the screen
    final halo = Rect.fromCenter(center: Offset(w / 2, h * .07), width: w * .56, height: h * .05);
    canvas.drawOval(
      halo,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _light.withValues(alpha: .12 + .06 * (.5 + .5 * cycle)),
    );

    // rays fanning out of the halo, swaying slowly; each one fades with the distance
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final origin = Offset(w / 2, -h * .08);
    final reach = math.max(w, h) * 1.5;
    const rays = 11;
    const span = math.pi * .72;
    final ray = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < rays; i++) {
      final a0 = math.pi * .14 + span * i / rays + cycle * .05;
      final a1 = a0 + span / rays * .45;
      final mid = (a0 + a1) / 2;
      final pulse = .5 + .5 * math.sin(t * 2 * math.pi + i * 1.3);
      ray.shader = ui.Gradient.linear(
        origin,
        origin + Offset(math.cos(mid), math.sin(mid)) * (reach * .9),
        [_gold.withValues(alpha: .05 + .07 * pulse), _gold.withValues(alpha: 0)],
      );
      canvas.drawPath(
        Path()
          ..moveTo(origin.dx, origin.dy)
          ..lineTo(origin.dx + math.cos(a0) * reach, origin.dy + math.sin(a0) * reach)
          ..lineTo(origin.dx + math.cos(a1) * reach, origin.dy + math.sin(a1) * reach)
          ..close(),
        ray,
      );
    }
    canvas.restore();

    // gold motes bobbing in the light and twinkling; whole numbers of cycles per loop, so the loop has no seam
    final rnd = math.Random(777);
    final paint = Paint();
    for (var i = 0; i < _motes; i++) {
      final x0 = rnd.nextDouble();
      final y0 = rnd.nextDouble();
      final px = rnd.nextDouble(), py = rnd.nextDouble(), pt = rnd.nextDouble();
      final kx = 1 + rnd.nextInt(2), ky = 1 + rnd.nextInt(3), kt = 1 + rnd.nextInt(3);
      final radius = .8 + rnd.nextDouble() * 2.0;
      final x = x0 * w + math.sin((t * kx + px) * 2 * math.pi) * 10;
      final y = y0 * h + math.sin((t * ky + py) * 2 * math.pi) * 14;
      final twinkle = math.pow(math.sin(math.pi * ((t * kt + pt) % 1.0)), 3).toDouble();
      paint.color = _gold.withValues(alpha: .08 * (.3 + twinkle));
      canvas.drawCircle(Offset(x, y), radius * 3, paint);
      paint.color = _light.withValues(alpha: .15 + .6 * twinkle);
      canvas.drawCircle(Offset(x, y), radius, paint);
      if (radius > 1.9) {
        // the bigger motes flash a small cross
        final arm = radius * 3.2 * twinkle;
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8
          ..color = _light.withValues(alpha: .5 * twinkle);
        canvas.drawLine(Offset(x - arm, y), Offset(x + arm, y), paint);
        canvas.drawLine(Offset(x, y - arm), Offset(x, y + arm), paint);
        paint.style = PaintingStyle.fill;
      }
    }
  }
}

// ============================================================================
// Solar Flare Glass — a burning star
// ============================================================================

/// Solar Flare: la superficie de una estrella. Corona que respira arriba, manchas de plasma
/// que ascienden, prominencias que se elevan y caen, y chispas incandescentes.
class SolarFlareGlassEffect extends NebulaEffect {
  const SolarFlareGlassEffect({super.key, required super.animate});

  @override
  Duration get duration => const Duration(seconds: 14);

  // seamless loop: it must not play backwards
  @override
  bool get reverse => false;

  @override
  CustomPainter painter(double t) => _SolarFlareGlassPainter(t);
}

class _SolarFlareGlassPainter extends NebulaEffectPainter {
  const _SolarFlareGlassPainter(super.t);

  static const _white = Color(0xFFFFF3C4);
  static const _gold = Color(0xFFFFB300);
  static const _orange = Color(0xFFFF6D00);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final beat = .5 + .5 * math.sin(t * 2 * math.pi);

    // corona breathing at the top
    final corona = Rect.fromLTWH(0, 0, w, h * .6);
    canvas.drawRect(
      corona,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * .5, -h * .05),
          h * .6,
          [_white.withValues(alpha: .20 + .10 * beat), _gold.withValues(alpha: .09 + .04 * beat), _gold.withValues(alpha: 0)],
          const [0, .4, 1],
        ),
    );

    // plasma clouds rising and cooling
    final rnd = math.Random(901);
    final blob = Paint();
    for (var i = 0; i < 9; i++) {
      final x0 = rnd.nextDouble();
      final phase = rnd.nextDouble();
      final sway = rnd.nextDouble() * 2 * math.pi;
      final r = (math.min(w, h) * (.12 + rnd.nextDouble() * .14));
      final p = (t + phase) % 1.0;
      final x = x0 * w + math.sin(p * 2 * math.pi + sway) * 22;
      final y = h * (1.15 - p * 1.3);
      final fade = math.sin(math.pi * p);
      blob.shader = ui.Gradient.radial(
        Offset(x, y),
        r,
        [Color.lerp(_gold, _orange, p)!.withValues(alpha: .14 * fade), _orange.withValues(alpha: 0)],
      );
      canvas.drawCircle(Offset(x, y), r, blob);
    }

    // prominences: arcs rising from the bottom edge, looping up and back down
    final arc = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1.0;
      final grow = math.sin(math.pi * p);
      if (grow < .02) continue;
      final cx = w * (.2 + .3 * i) + math.sin(i * 2.1) * 20;
      final span = w * (.08 + .07 * grow);
      final rise = h * (.10 + .30 * grow);
      final path = Path()
        ..moveTo(cx - span, h)
        ..cubicTo(cx - span * .6, h - rise * 1.5, cx + span * .6, h - rise * 1.5, cx + span, h);
      arc
        ..strokeWidth = 9 * grow + 2
        ..color = _orange.withValues(alpha: .20 * grow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(path, arc);
      arc
        ..strokeWidth = 1.6
        ..color = _white.withValues(alpha: .75 * grow)
        ..maskFilter = null;
      canvas.drawPath(path, arc);
    }

    // sparks flying up; whole trips per loop, so the loop has no seam
    final sparks = math.Random(902);
    final dot = Paint();
    for (var i = 0; i < 36; i++) {
      final x0 = sparks.nextDouble();
      final phase = sparks.nextDouble();
      final trips = 1 + sparks.nextInt(3);
      final radius = .6 + sparks.nextDouble() * 1.8;
      final p = (t * trips + phase) % 1.0;
      final fade = math.sin(math.pi * p);
      final x = x0 * w + math.sin(p * 6 + i) * 12;
      final y = h * (1.03 - p * 1.06);
      dot.color = _gold.withValues(alpha: .12 * fade);
      canvas.drawCircle(Offset(x, y), radius * 3.4, dot);
      dot.color = Color.lerp(_white, _orange, p)!.withValues(alpha: .85 * fade);
      canvas.drawCircle(Offset(x, y), radius, dot);
    }
  }
}

// ============================================================================
// Imperial Glass — riveted gunmetal, brass and incense
// ============================================================================

/// Imperial Glass: engranajes de latón que giran despacio, humo de incienso que sube,
/// una lámpara de inspección que barre la placa y brasas doradas.
class ImperialGlassEffect extends NebulaEffect {
  const ImperialGlassEffect({super.key, required super.animate});

  @override
  Duration get duration => const Duration(seconds: 20);

  @override
  bool get reverse => false;

  @override
  CustomPainter painter(double t) => _ImperialGlassPainter(t);
}

class _ImperialGlassPainter extends NebulaEffectPainter {
  const _ImperialGlassPainter(super.t);

  static const _brass = Color(0xFFD4A72A);
  static const _bone = Color(0xFFC9B896);

  Path _gear(Offset c, double outer, double inner, int teeth, double turn) {
    final path = Path();
    for (var i = 0; i < teeth; i++) {
      final a = turn + i * 2 * math.pi / teeth;
      final s = math.pi / teeth * .5;
      final pts = [
        c + Offset(math.cos(a - s * 1.4), math.sin(a - s * 1.4)) * inner,
        c + Offset(math.cos(a - s * .8), math.sin(a - s * .8)) * outer,
        c + Offset(math.cos(a + s * .8), math.sin(a + s * .8)) * outer,
        c + Offset(math.cos(a + s * 1.4), math.sin(a + s * 1.4)) * inner,
      ];
      if (i == 0) {
        path.moveTo(pts[0].dx, pts[0].dy);
      } else {
        path.lineTo(pts[0].dx, pts[0].dy);
      }
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final line = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2;

    // two meshing gears, one tooth of turn per loop (so the loop has no seam)
    const big = 18, small = 12;
    final bigC = Offset(w * .92, h * .86);
    final bigR = math.min(w, h) * .42;
    line.color = _brass.withValues(alpha: .13);
    canvas.drawPath(_gear(bigC, bigR, bigR * .88, big, t * 2 * math.pi / big), line);
    canvas.drawCircle(bigC, bigR * .5, line);
    final smallR = bigR * big / small * .5 * .95;
    final smallC = bigC + Offset(-(bigR * .88 + smallR * .88) * .86, -(bigR * .88 + smallR * .88) * .5);
    line.color = _bone.withValues(alpha: .10);
    canvas.drawPath(_gear(smallC, smallR, smallR * .86, small, -t * 2 * math.pi / small + math.pi / small), line);

    // inspection lamp sweeping the plate
    final env = math.sin(math.pi * t);
    final x = -w * .3 + w * 1.6 * t;
    final band = Path()
      ..moveTo(x, 0)
      ..lineTo(x + w * .28, 0)
      ..lineTo(x + w * .28 - h * .35, h)
      ..lineTo(x - h * .35, h)
      ..close();
    canvas.drawPath(
      band,
      Paint()
        ..shader = ui.Gradient.linear(Offset(x, 0), Offset(x + w * .28, 0), [
          _brass.withValues(alpha: 0),
          _brass.withValues(alpha: .14 * env),
          _brass.withValues(alpha: 0),
        ], const [0, .5, 1]),
    );

    // incense smoke: three columns rising from the bottom, waving with whole cycles per loop
    final smoke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    for (var i = 0; i < 3; i++) {
      final x0 = w * (.18 + i * .3);
      final path = Path()..moveTo(x0, h);
      for (var s = 1; s <= 24; s++) {
        final u = s / 24;
        final dx = math.sin(u * 7 - t * 2 * math.pi * (1 + i % 2) + i) * (6 + 30 * u);
        path.lineTo(x0 + dx, h - u * h * (.5 + .1 * i));
      }
      smoke
        ..strokeWidth = 7 + 4 * i
        ..color = _bone.withValues(alpha: .07);
      canvas.drawPath(path, smoke);
    }

    // brass embers
    final rnd = math.Random(1941);
    final dot = Paint();
    for (var i = 0; i < 16; i++) {
      final x0 = rnd.nextDouble();
      final phase = rnd.nextDouble();
      final trips = 1 + rnd.nextInt(2);
      final p = (t * trips + phase) % 1.0;
      final fade = math.sin(math.pi * p);
      final ex = x0 * w + math.sin(p * 5 + i) * 8;
      final ey = h * (1.02 - p * 1.0);
      dot.color = _brass.withValues(alpha: .10 * fade);
      canvas.drawCircle(Offset(ex, ey), 5, dot);
      dot.color = const Color(0xFFFFE9A3).withValues(alpha: .7 * fade);
      canvas.drawCircle(Offset(ex, ey), 1.3, dot);
    }
  }
}

// ============================================================================
// Forge Glass — the anvil
// ============================================================================

/// Forge Glass: un martillo golpea el yunque tres veces por ciclo; cada golpe lanza un abanico
/// de chispas que caen con gravedad, ilumina el metal fundido y deja brasas flotando.
class ForgeGlassEffect extends NebulaEffect {
  const ForgeGlassEffect({super.key, required super.animate});

  @override
  Duration get duration => const Duration(seconds: 12);

  @override
  bool get reverse => false;

  @override
  CustomPainter painter(double t) => _ForgeGlassPainter(t);
}

class _ForgeGlassPainter extends NebulaEffectPainter {
  const _ForgeGlassPainter(super.t);

  static const _strikes = 3;
  static const _white = Color(0xFFFFF3C4);
  static const _gold = Color(0xFFFFB300);
  static const _orange = Color(0xFFFF6D00);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final anvil = Offset(w * .5, h * .86);

    // heat wash coming from the forge floor, always glowing a little
    final wash = Rect.fromLTWH(0, h * .45, w, h * .55);
    canvas.drawRect(
      wash,
      Paint()..shader = ui.Gradient.linear(Offset(0, h), Offset(0, h * .45), [_orange.withValues(alpha: .20), _orange.withValues(alpha: 0)]),
    );

    // how long ago the last hammer blow was, 0..1 per blow
    final u = (t * _strikes) % 1.0;
    final flash = math.exp(-u * 6);

    // flash of the struck metal
    canvas.drawCircle(
      anvil,
      math.min(w, h) * (.18 + .12 * flash),
      Paint()..shader = ui.Gradient.radial(anvil, math.min(w, h) * (.18 + .12 * flash), [_white.withValues(alpha: .55 * flash), _gold.withValues(alpha: .25 * flash), _gold.withValues(alpha: 0)], const [0, .35, 1]),
    );

    // sparks: a fan thrown upwards, then pulled down by gravity
    final rnd = math.Random(6);
    final spark = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < 26; i++) {
      final angle = -math.pi / 2 + (rnd.nextDouble() - .5) * math.pi * .95;
      final speed = h * (.35 + rnd.nextDouble() * .75);
      final life = .55 + rnd.nextDouble() * .45;
      if (u > life) continue;
      Offset at(double time) => anvil + Offset(math.cos(angle) * speed * time, math.sin(angle) * speed * time + h * 1.5 * time * time);
      final now = at(u), before = at(math.max(0.0, u - .03));
      final fade = math.pow(1 - u / life, 1.4).toDouble();
      spark
        ..strokeWidth = 1.2 + 1.2 * fade
        ..color = Color.lerp(_orange, _white, fade)!.withValues(alpha: .9 * fade);
      canvas.drawLine(before, now, spark);
    }

    // embers drifting up, whole trips per loop
    final dot = Paint();
    final embers = math.Random(66);
    for (var i = 0; i < 18; i++) {
      final x0 = embers.nextDouble();
      final phase = embers.nextDouble();
      final trips = 1 + embers.nextInt(2);
      final p = (t * trips + phase) % 1.0;
      final fade = math.sin(math.pi * p);
      final x = x0 * w + math.sin(p * 6 + i) * 10;
      final y = h * (1.02 - p * .95);
      dot.color = _orange.withValues(alpha: .12 * fade);
      canvas.drawCircle(Offset(x, y), 4.5, dot);
      dot.color = _gold.withValues(alpha: .8 * fade);
      canvas.drawCircle(Offset(x, y), 1.1, dot);
    }
  }
}

// ============================================================================
// Hermetic Glass — the alchemical wheel
// ============================================================================

/// Hermetic Glass: un círculo alquímico que gira por capas, con marcas de grados, un hexagrama
/// y siete planetas en órbita. Todo da vueltas completas por ciclo, así que no tiene costura.
class HermeticGlassEffect extends NebulaEffect {
  const HermeticGlassEffect({super.key, required super.animate});

  @override
  Duration get duration => const Duration(seconds: 36);

  @override
  bool get reverse => false;

  @override
  CustomPainter painter(double t) => _HermeticGlassPainter(t);
}

class _HermeticGlassPainter extends NebulaEffectPainter {
  const _HermeticGlassPainter(super.t);

  static const _green = Color(0xFF38D39A);
  static const _violet = Color(0xFFB388FF);
  static const _gold = Color(0xFFFFE082);

  void _ticks(Canvas canvas, Offset c, double r, int n, double turn, double len, Paint paint) {
    for (var i = 0; i < n; i++) {
      final a = turn + i * 2 * math.pi / n;
      final long = i % 6 == 0;
      final l = long ? len * 1.8 : len;
      canvas.drawLine(c + Offset(math.cos(a), math.sin(a)) * (r - l), c + Offset(math.cos(a), math.sin(a)) * r, paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final c = Offset(w * .5, h * .5);
    final r = math.min(w, h) * .42;
    final tau = 2 * math.pi;
    final line = Paint()..style = PaintingStyle.stroke..strokeWidth = 1;

    canvas.drawCircle(c, r * 1.3, Paint()..shader = ui.Gradient.radial(c, r * 1.3, [_green.withValues(alpha: .10), _green.withValues(alpha: 0)]));

    // three counter-rotating rings with degree marks
    line.color = _green.withValues(alpha: .38);
    canvas.drawCircle(c, r, line);
    _ticks(canvas, c, r, 72, t * tau, 4, line);
    line.color = _violet.withValues(alpha: .34);
    canvas.drawCircle(c, r * .82, line);
    _ticks(canvas, c, r * .82, 48, -t * tau, 3.5, line);
    line.color = _gold.withValues(alpha: .30);
    canvas.drawCircle(c, r * .64, line);
    _ticks(canvas, c, r * .64, 24, t * tau, 3, line);

    // hexagram: two triangles turning against each other
    for (var k = 0; k < 2; k++) {
      final rot = (k == 0 ? 1 : -1) * t * tau / 3 + k * math.pi / 3;
      final path = Path();
      for (var i = 0; i < 3; i++) {
        final a = rot + i * tau / 3 - math.pi / 2;
        final p = c + Offset(math.cos(a), math.sin(a)) * r * .58;
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = (k == 0 ? _green : _violet).withValues(alpha: .55));
    }

    // seven planets, each on its own orbit with a whole number of laps
    const colors = [Color(0xFFFFE082), Color(0xFFB0BEC5), Color(0xFFFF8A80), Color(0xFF80D8FF), Color(0xFFFFAB40), Color(0xFFCE93D8), Color(0xFFA5D6A7)];
    for (var i = 0; i < 7; i++) {
      final orbit = r * (.30 + i * .095);
      final laps = (i % 3 + 1) * (i.isEven ? 1 : -1);
      final a = t * tau * laps + i * 1.1;
      final p = c + Offset(math.cos(a), math.sin(a)) * orbit;
      canvas.drawCircle(p, 5, Paint()..color = colors[i].withValues(alpha: .25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      canvas.drawCircle(p, 1.8, Paint()..color = colors[i].withValues(alpha: .95));
    }
    canvas.drawCircle(c, 3, Paint()..color = _gold.withValues(alpha: .9));
    canvas.drawCircle(c, 12, Paint()..color = _gold.withValues(alpha: .25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
  }
}

// ============================================================================
// Eclipse Glass — totality
// ============================================================================

/// Eclipse Glass: un disco negro con la corona respirando, rayos largos que pulsan y un destello
/// de anillo de diamante que recorre el borde una vez por ciclo.
class EclipseGlassEffect extends NebulaEffect {
  const EclipseGlassEffect({super.key, required super.animate});

  @override
  Duration get duration => const Duration(seconds: 24);

  @override
  bool get reverse => false;

  @override
  CustomPainter painter(double t) => _EclipseGlassPainter(t);
}

class _EclipseGlassPainter extends NebulaEffectPainter {
  const _EclipseGlassPainter(super.t);

  static const _cyan = Color(0xFF9AF5FF);
  static const _blue = Color(0xFF29D9FF);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final tau = 2 * math.pi;
    final c = Offset(w * .5, h * .4);
    final r = math.min(w, h) * .19;
    final breath = .5 + .5 * math.sin(t * tau * 2);

    // stars
    final rnd = math.Random(2024);
    final dot = Paint();
    for (var i = 0; i < 40; i++) {
      final p = Offset(rnd.nextDouble() * w, rnd.nextDouble() * h);
      final kt = 1 + rnd.nextInt(3);
      final tw = math.pow(math.sin(math.pi * ((t * kt + rnd.nextDouble()) % 1.0)), 2).toDouble();
      dot.color = Colors.white.withValues(alpha: .10 + .5 * tw);
      canvas.drawCircle(p, .6 + rnd.nextDouble() * .7, dot);
    }

    // long streamers of the corona
    final ray = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final rays = math.Random(77);
    for (var i = 0; i < 28; i++) {
      final a = i * tau / 28 + rays.nextDouble() * .1;
      final len = r * (1.3 + rays.nextDouble() * 1.7) * (.85 + .15 * math.sin(t * tau * (1 + i % 3) + i));
      final a0 = c + Offset(math.cos(a), math.sin(a)) * r * 1.05;
      final a1 = c + Offset(math.cos(a), math.sin(a)) * (r + len);
      ray
        ..strokeWidth = 1 + (i % 4) * .5
        ..shader = ui.Gradient.linear(a0, a1, [_cyan.withValues(alpha: .35), _blue.withValues(alpha: 0)]);
      canvas.drawLine(a0, a1, ray);
    }
    ray.shader = null;

    // inner corona, breathing
    canvas.drawCircle(
      c,
      r * (1.55 + .1 * breath),
      Paint()..shader = ui.Gradient.radial(c, r * (1.55 + .1 * breath), [_blue.withValues(alpha: 0), _blue.withValues(alpha: .30), _blue.withValues(alpha: 0)], const [.6, .72, 1]),
    );

    // the moon
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF000206));
    canvas.drawCircle(c, r, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = _cyan.withValues(alpha: .55));

    // diamond ring: a bright point sliding round the rim once per loop, with a bloom
    final a = t * tau - math.pi / 2;
    final p = c + Offset(math.cos(a), math.sin(a)) * r;
    canvas.drawCircle(p, r * .5, Paint()..shader = ui.Gradient.radial(p, r * .5, [Colors.white.withValues(alpha: .6), _cyan.withValues(alpha: .18), _cyan.withValues(alpha: 0)], const [0, .3, 1]));
    canvas.drawCircle(p, 2.2, Paint()..color = Colors.white);
    final arm = r * .45;
    canvas.drawLine(p - Offset(arm, 0), p + Offset(arm, 0), Paint()..strokeWidth = .8..color = Colors.white.withValues(alpha: .7));
    canvas.drawLine(p - Offset(0, arm), p + Offset(0, arm), Paint()..strokeWidth = .8..color = Colors.white.withValues(alpha: .7));
  }
}

// ============================================================================
// Crimson Glass — heartbeat
// ============================================================================

/// Crimson Glass: un corazón que late (doce latidos dobles por ciclo) enciende venas rojas desde las
/// esquinas, mientras gotas de sangre resbalan desde arriba.
class CrimsonGlassEffect extends NebulaEffect {
  const CrimsonGlassEffect({super.key, required super.animate});

  @override
  Duration get duration => const Duration(seconds: 16);

  @override
  bool get reverse => false;

  @override
  CustomPainter painter(double t) => _CrimsonGlassPainter(t);
}

class _CrimsonGlassPainter extends NebulaEffectPainter {
  const _CrimsonGlassPainter(super.t);

  static const _red = Color(0xFFFF1744);
  static const _deep = Color(0xFF8E0E2B);
  static const _beats = 12;

  // lub-dub: two close pulses per beat
  double get _pulse {
    final x = (t * _beats) % 1.0;
    double bump(double c, double wd) => math.exp(-math.pow((x - c) / wd, 2).toDouble());
    return math.min(1.0, bump(.08, .045) + .7 * bump(.30, .05));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final pulse = _pulse;

    // the vignette throbs from the edges
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..shader = ui.Gradient.radial(rect.center, math.max(w, h) * .75, [_red.withValues(alpha: 0), _deep.withValues(alpha: .10 + .28 * pulse)], const [.45, 1]),
    );

    // veins: branches growing from the corners, brightening with each beat
    final rnd = math.Random(1313);
    final vein = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    for (var corner = 0; corner < 4; corner++) {
      final origin = Offset(corner % 2 == 0 ? 0 : w, corner < 2 ? 0 : h);
      final inward = math.atan2(h / 2 - origin.dy, w / 2 - origin.dx);
      for (var b = 0; b < 4; b++) {
        var pos = origin;
        var heading = inward + (rnd.nextDouble() - .5) * 1.1;
        final path = Path()..moveTo(pos.dx, pos.dy);
        final steps = 10 + rnd.nextInt(8);
        for (var s = 0; s < steps; s++) {
          heading += (rnd.nextDouble() - .5) * .8;
          pos += Offset(math.cos(heading), math.sin(heading)) * (math.min(w, h) * .05);
          path.lineTo(pos.dx, pos.dy);
        }
        vein
          ..strokeWidth = 4
          ..color = _red.withValues(alpha: .05 + .18 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawPath(path, vein);
        vein
          ..strokeWidth = .9
          ..color = const Color(0xFFFF5C7C).withValues(alpha: .18 + .5 * pulse)
          ..maskFilter = null;
        canvas.drawPath(path, vein);
      }
    }

    // drops sliding down, whole trips per loop
    final drops = math.Random(14);
    final drop = Paint();
    for (var i = 0; i < 9; i++) {
      final x = drops.nextDouble() * w;
      final phase = drops.nextDouble();
      final trips = 1 + drops.nextInt(2);
      final p = (t * trips + phase) % 1.0;
      final y = h * (-.05 + p * 1.1);
      final a = math.min(1.0, math.sin(math.pi * p) * 2.5);
      final r = 1.6 + drops.nextDouble() * 1.6;
      drop.shader = ui.Gradient.linear(Offset(x, y - r * 6), Offset(x, y), [_red.withValues(alpha: 0), _red.withValues(alpha: .55 * a)]);
      canvas.drawRect(Rect.fromLTWH(x - r * .5, y - r * 6, r, r * 6), drop);
      drop.shader = null;
      drop.color = const Color(0xFFFF4D6D).withValues(alpha: .9 * a);
      canvas.drawPath(
        Path()
          ..moveTo(x, y - r * 1.8)
          ..quadraticBezierTo(x + r * 1.3, y, x, y + r)
          ..quadraticBezierTo(x - r * 1.3, y, x, y - r * 1.8)
          ..close(),
        drop,
      );
    }
  }
}

// ============================================================================
// Emerald Glass — crystal grove
// ============================================================================

/// Emerald Glass: un racimo de cristales de esmeralda cuyo brillo recorre las facetas, vetas de oro
/// que laten con un punto de luz viajero y luciérnagas verdes que flotan.
class EmeraldGlassEffect extends NebulaEffect {
  const EmeraldGlassEffect({super.key, required super.animate});

  @override
  Duration get duration => const Duration(seconds: 20);

  @override
  bool get reverse => false;

  @override
  CustomPainter painter(double t) => _EmeraldGlassPainter(t);
}

class _EmeraldGlassPainter extends NebulaEffectPainter {
  const _EmeraldGlassPainter(super.t);

  static const _green = Color(0xFF2EE59D);
  static const _gold = Color(0xFFFFD54F);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final tau = 2 * math.pi;

    // prisms growing from the bottom
    final rnd = math.Random(5);
    final glintX = -.2 * w + 1.4 * w * t;
    for (var i = 0; i < 7; i++) {
      final x = w * (.06 + i * .14) + rnd.nextDouble() * 10;
      final bw = w * (.06 + rnd.nextDouble() * .05);
      final bh = h * (.12 + rnd.nextDouble() * .2);
      final top = h - bh;
      final prism = Path()
        ..moveTo(x, h)
        ..lineTo(x, top + bw * .6)
        ..lineTo(x + bw * .5, top)
        ..lineTo(x + bw, top + bw * .6)
        ..lineTo(x + bw, h)
        ..close();
      canvas.drawPath(prism, Paint()..shader = ui.Gradient.linear(Offset(x, top), Offset(x + bw, h), [_green.withValues(alpha: .30), const Color(0xFF004D36).withValues(alpha: .35)]));
      canvas.drawPath(prism, Paint()..style = PaintingStyle.stroke..strokeWidth = .9..color = _green.withValues(alpha: .5));
      canvas.drawLine(Offset(x + bw * .5, top), Offset(x + bw * .5, h), Paint()..strokeWidth = .6..color = Colors.white.withValues(alpha: .12));
      // the glint crossing the crystals
      final d = (x + bw / 2 - glintX).abs();
      if (d < w * .12) {
        final k = 1 - d / (w * .12);
        canvas.drawPath(prism, Paint()..color = Colors.white.withValues(alpha: .22 * k));
      }
    }

    // gold veins with a travelling spark
    final vein = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 1.2;
    for (var i = 0; i < 3; i++) {
      final y0 = h * (.2 + i * .2);
      final path = Path()
        ..moveTo(0, y0)
        ..cubicTo(w * .25, y0 - h * .08, w * .45, y0 + h * .1, w * .62, y0 - h * .02)
        ..cubicTo(w * .78, y0 - h * .1, w * .9, y0 + h * .05, w, y0 - h * .03);
      vein.color = _gold.withValues(alpha: .22);
      canvas.drawPath(path, vein);
      final metric = path.computeMetrics().first;
      final head = ((t * (1 + i) + i * .3) % 1.0) * metric.length;
      final from = math.max(0.0, head - 70);
      canvas.drawPath(metric.extractPath(from, head), Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 2..shader = null..color = _gold.withValues(alpha: .8));
      final tangent = metric.getTangentForOffset(head);
      if (tangent != null) {
        canvas.drawCircle(tangent.position, 6, Paint()..color = _gold.withValues(alpha: .35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        canvas.drawCircle(tangent.position, 1.6, Paint()..color = const Color(0xFFFFF8E1));
      }
    }

    // fireflies
    final fly = math.Random(55);
    final dot = Paint();
    for (var i = 0; i < 24; i++) {
      final x0 = fly.nextDouble(), y0 = fly.nextDouble();
      final px = fly.nextDouble();
      final kt = 1 + fly.nextInt(3);
      final tw = math.pow(math.sin(math.pi * ((t * kt + px) % 1.0)), 3).toDouble();
      final x = x0 * w + math.sin((t + px) * tau) * 14;
      final y = y0 * h * .85 + math.cos((t * 2 + px) * tau) * 8;
      dot.color = _green.withValues(alpha: .10 * (.3 + tw));
      canvas.drawCircle(Offset(x, y), 5, dot);
      dot.color = const Color(0xFFD8FFE9).withValues(alpha: .2 + .7 * tw);
      canvas.drawCircle(Offset(x, y), 1.2, dot);
    }
  }
}

