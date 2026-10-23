import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui' show BlurStyle, MaskFilter, Path, StrokeCap;
import 'package:flutter/material.dart';
import 'package:aves/theme/nebula/nebula_theme.dart';

// Nebula Engine — Fase 2: efectos visuales propios por tema.
//
// Cada tema de Fase 2 define su propio `NebulaEffect`: un `CustomPainter` que se
// repinta con un único `AnimationController` (sin rebuilds por frame) y se para
// en modo rendimiento o con movimiento reducido.
//
// Los efectos se pintan sobre el fondo galáctico de la pestaña Nebula cuando el
// tema activo es el correspondiente, dando a cada tema su propia identidad visual.

/// Efecto visual de un tema Nebula (Fase 2).
///
/// [animate] indica si la animación debe avanzar (false en modo rendimiento /
/// movimiento reducido).
///
/// Un tema solo necesita implementar [painter]; [duration] y [reverse] ajustan
/// el ritmo de la animación, y el host compartido se encarga del
/// `AnimationController` (sin rebuilds de estado por frame).
abstract class NebulaEffect extends StatelessWidget {
  final bool animate;

  const NebulaEffect({super.key, required this.animate});

  /// Construye el pintor para este efecto.
  CustomPainter painter(double t);

  /// Duración de un ciclo completo de la animación.
  Duration get duration => const Duration(seconds: 12);

  /// Si el ciclo se reproduce de ida y vuelta.
  bool get reverse => true;

  @override
  Widget build(BuildContext context) => _NebulaEffectHost(
    animate: animate,
    duration: duration,
    reverse: reverse,
    painterBuilder: painter,
  );
}

/// Host compartido: mantiene el [AnimationController] y repinta con
/// [AnimatedBuilder] sin reconstruir el árbol de widgets en cada frame.
class _NebulaEffectHost extends StatefulWidget {
  final bool animate;
  final Duration duration;
  final bool reverse;
  final CustomPainter Function(double t) painterBuilder;

  const _NebulaEffectHost({
    required this.animate,
    required this.duration,
    required this.reverse,
    required this.painterBuilder,
  });

  @override
  State<_NebulaEffectHost> createState() => _NebulaEffectHostState();
}

class _NebulaEffectHostState extends State<_NebulaEffectHost> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat(reverse: widget.reverse);
  }

  @override
  void didUpdateWidget(covariant _NebulaEffectHost old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: widget.reverse);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(painter: widget.painterBuilder(_controller.value)),
    );
  }
}

/// Pintor base que repinta desde un [AnimationController] sin rebuilds de widget.
abstract class NebulaEffectPainter extends CustomPainter {
  final double t;

  const NebulaEffectPainter(this.t);

  @override
  bool shouldRepaint(covariant NebulaEffectPainter old) => old.t != t;
}

// ============================================================================
// Forge Glass — molten orange cosmic forge
// ============================================================================

/// Forge Glass: flujo de lava naranja sobre fondo índigo, con destellos
/// dorados que se desplazan lentamente como metal fundido.
class ForgeGlassEffect extends NebulaEffect {
  const ForgeGlassEffect({super.key, required super.animate});

  @override
  Widget build(BuildContext context) {
    return _ForgeGlassPainterWidget(animate: animate);
  }

  @override
  CustomPainter painter(double t) => _ForgeGlassPainter(t);
}

class _ForgeGlassPainterWidget extends StatefulWidget {
  final bool animate;
  const _ForgeGlassPainterWidget({required this.animate});

  @override
  State<_ForgeGlassPainterWidget> createState() => _ForgeGlassPainterState();
}

class _ForgeGlassPainterState extends State<_ForgeGlassPainterWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 12));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _ForgeGlassPainterWidget old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_controller.isAnimating) _controller.repeat(reverse: true);
    if (!widget.animate && _controller.isAnimating) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(painter: _ForgeGlassPainter(_controller.value)),
    );
  }
}

class _ForgeGlassPainter extends NebulaEffectPainter {
  const _ForgeGlassPainter(super.t);

  static const _colors = [
    Color(0x33FF7A18), // molten orange glow
    Color(0x1AFFB300), // gold
    Color(0x0DFF4500), // orange red
    Color(0x33FF7A18),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide;

    // Slowly rotating molten swirls
    final paint = Paint()
      ..shader = SweepGradient(
        colors: _colors,
        stops: const [0, .33, .66, 1],
        transform: GradientRotation(t * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: r));

    canvas.drawCircle(center, r, paint);

    // Brighter core pulse
    final pulse = .5 + .5 * math.sin(t * 2 * math.pi);
    canvas.drawCircle(
      center,
      r * (.25 + .15 * pulse),
      Paint()
        ..color = Color(0xFF000000).withValues(alpha: .35)
        ..blendMode = BlendMode.screen,
    );
  }
}

// ============================================================================
// Hermetic Glass — emerald alchemy
// ============================================================================

/// Hermetic Glass: círculos concéntricos esmeralda/violeta que giran como
/// glifos alquímicos, con anillos brillantes que se desplazan.
class HermeticGlassEffect extends NebulaEffect {
  const HermeticGlassEffect({super.key, required super.animate});

  @override
  Widget build(BuildContext context) {
    return _HermeticGlassPainterWidget(animate: animate);
  }

  @override
  CustomPainter painter(double t) => _HermeticGlassPainter(t);
}

class _HermeticGlassPainterWidget extends StatefulWidget {
  final bool animate;
  const _HermeticGlassPainterWidget({required this.animate});

  @override
  State<_HermeticGlassPainterWidget> createState() => _HermeticGlassPainterState();
}

class _HermeticGlassPainterState extends State<_HermeticGlassPainterWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 16));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _HermeticGlassPainterWidget old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_controller.isAnimating) _controller.repeat();
    if (!widget.animate && _controller.isAnimating) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(painter: _HermeticGlassPainter(_controller.value)),
    );
  }
}

class _HermeticGlassPainter extends NebulaEffectPainter {
  const _HermeticGlassPainter(super.t);

  static const _ringColors = [
    Color(0x2200C853), // emerald
    Color(0x119B7BFF), // violet
    Color(0x2200C853),
    Color(0x119B7BFF),
    Color(0x2200C853),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // Rotating alchemical rings
    for (var i = 0; i < _ringColors.length; i++) {
      final phase = t * (2 * math.pi) + i * (2 * math.pi / _ringColors.length);
      final radius = r * (.22 + .16 * i);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = SweepGradient(
            colors: [_ringColors[i], _ringColors[(i + 1) % _ringColors.length]],
            transform: GradientRotation(phase),
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * .04),
      );
    }

    // Central glowing sigil
    final glow = .6 + .4 * math.sin(t * 2 * math.pi);
    canvas.drawCircle(
      center,
      r * .18 * glow,
      Paint()
        ..color = Color(0xFF35E0A1).withValues(alpha: .5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8),
    );
  }
}

// ============================================================================
// Eclipse Glass — midnight blue with electric cyan
// ============================================================================

class EclipseGlassEffect extends NebulaEffect {
  const EclipseGlassEffect({super.key, required super.animate});

  @override
  Widget build(BuildContext context) {
    return _EclipseGlassPainterWidget(animate: animate);
  }

  @override
  CustomPainter painter(double t) => _EclipseGlassPainter(t);
}

class _EclipseGlassPainterWidget extends StatefulWidget {
  final bool animate;
  const _EclipseGlassPainterWidget({required this.animate});

  @override
  State<_EclipseGlassPainterWidget> createState() => _EclipseGlassPainterState();
}

class _EclipseGlassPainterState extends State<_EclipseGlassPainterWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 20));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _EclipseGlassPainterWidget old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_controller.isAnimating) _controller.repeat();
    if (!widget.animate && _controller.isAnimating) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(painter: _EclipseGlassPainter(_controller.value)),
    );
  }
}

class _EclipseGlassPainter extends NebulaEffectPainter {
  const _EclipseGlassPainter(super.t);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .5, size.height * .43);
    final r = size.shortestSide;
    final rect = Offset.zero & size;
    final coronaRadius = r * .22;
    canvas.drawRect(rect, Paint()..shader = RadialGradient(
      center: Alignment.center, radius: 1.05,
      colors: const [Color(0x220D47A1), Color(0x08051935), Colors.transparent],
      stops: const [0, .55, 1],
    ).createShader(rect));
    final coronaRect = Rect.fromCircle(center: center, radius: coronaRadius * 1.45);
    canvas.drawCircle(center, coronaRadius * 1.25, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = coronaRadius * .34
      ..shader = SweepGradient(
        colors: const [Color(0x0000D9FF), Color(0x5500D9FF), Color(0xAA9AF5FF), Color(0x4400B8F5), Color(0x0000D9FF)],
        stops: const [0, .19, .34, .7, 1],
        transform: GradientRotation(t * 2 * math.pi),
      ).createShader(coronaRect)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, coronaRadius * .08));
    final transit = math.sin(t * 2 * math.pi) * r * .14;
    final discCenter = center + Offset(transit, 0);
    canvas.drawCircle(discCenter, coronaRadius, Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFF02040B), Color(0xFF04091A), Color(0xFF071026)],
        stops: const [0, .72, 1],
      ).createShader(Rect.fromCircle(center: discCenter, radius: coronaRadius)));
    canvas.drawCircle(discCenter, coronaRadius, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .0025
      ..color = const Color(0x669AF5FF));
    for (var i = 0; i < 7; i++) {
      final angle = i * 2.399963;
      final dist = r * (.34 + .025 * (i % 3));
      final point = center + Offset(math.cos(angle) * dist, math.sin(angle) * dist);
      canvas.drawCircle(point, r * .0028, Paint()..color = const Color(0x669AF5FF));
    }
  }
}

// ============================================================================
// Solar Flare Glass — molten orange on black with gold
// ============================================================================

class SolarFlareGlassEffect extends NebulaEffect {
  const SolarFlareGlassEffect({super.key, required super.animate});

  @override
  Widget build(BuildContext context) {
    return _SolarFlareGlassPainterWidget(animate: animate);
  }

  @override
  CustomPainter painter(double t) => _SolarFlareGlassPainter(t);
}

class _SolarFlareGlassPainterWidget extends StatefulWidget {
  final bool animate;
  const _SolarFlareGlassPainterWidget({required this.animate});

  @override
  State<_SolarFlareGlassPainterWidget> createState() => _SolarFlareGlassPainterState();
}

class _SolarFlareGlassPainterState extends State<_SolarFlareGlassPainterWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 11));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _SolarFlareGlassPainterWidget old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_controller.isAnimating) _controller.repeat();
    if (!widget.animate && _controller.isAnimating) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(painter: _SolarFlareGlassPainter(_controller.value)),
    );
  }
}

class _SolarFlareGlassPainter extends NebulaEffectPainter {
  const _SolarFlareGlassPainter(super.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = Offset(size.width * .5, size.height * .43);
    final r = size.shortestSide;
    final sunRadius = r * .205;
    final pulse = .5 + .5 * math.sin(t * 2 * math.pi);
    final coronaRadius = sunRadius * (1.20 + .035 * pulse);

    // A deep, almost-black sky lets the eclipse corona act as the only light source.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.02,
          colors: const [
            Color(0x332D0A02),
            Color(0x16200703),
            Color(0x00000000),
          ],
          stops: const [0, .48, 1],
        ).createShader(rect),
    );

    // Broad reflected corona and the fine white-hot ring.
    for (var i = 0; i < 3; i++) {
      final radius = coronaRadius * (1.02 + i * .17);
      final glowRect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = sunRadius * (i == 0 ? .28 : .075)
          ..shader = SweepGradient(
            colors: const [
              Color(0x00FF5A24),
              Color(0x66FF6B20),
              Color(0xAAFFE6A1),
              Color(0xCCFF9D24),
              Color(0x44FF4A18),
              Color(0x00FF5A24),
            ],
            stops: const [0, .16, .29, .47, .76, 1],
            transform: GradientRotation(t * 2 * math.pi + i * .42),
          ).createShader(glowRect)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sunRadius * (i == 0 ? .16 : .07)),
      );
    }

    // Uneven plasma tongues make the corona look solar, not like a perfect neon ring.
    for (var i = 0; i < 32; i++) {
      final angle = i * 2 * math.pi / 32;
      final wave = .5 + .5 * math.sin(i * 2.17 + t * 2 * math.pi);
      final inner = sunRadius * (1.17 + .06 * wave);
      final outer = sunRadius * (1.38 + .22 * wave + (i % 5 == 0 ? .16 : 0));
      final start = center + Offset(math.cos(angle) * inner, math.sin(angle) * inner);
      final end = center + Offset(math.cos(angle) * outer, math.sin(angle) * outer);
      final hot = i % 4 == 0;
      canvas.drawLine(
        start,
        end,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = hot ? r * .0042 : r * .0018
          ..color = (hot ? const Color(0xFFFFE8A0) : const Color(0xFFFF6A24))
              .withValues(alpha: (hot ? .55 : .29) + .12 * pulse),
      );
    }

    // Sparse prominences curve away from the limb like magnetic loops.
    for (var i = 0; i < 5; i++) {
      final angle = -.9 + i * .47 + .035 * math.sin(t * 2 * math.pi);
      final inner = center + Offset(math.cos(angle) * sunRadius * 1.08, math.sin(angle) * sunRadius * 1.08);
      final peak = center + Offset(math.cos(angle + .15) * sunRadius * (1.54 + .08 * pulse), math.sin(angle + .15) * sunRadius * (1.54 + .08 * pulse));
      final end = center + Offset(math.cos(angle + .34) * sunRadius * 1.12, math.sin(angle + .34) * sunRadius * 1.12);
      final loop = Path()..moveTo(inner.dx, inner.dy)..quadraticBezierTo(peak.dx, peak.dy, end.dx, end.dy);
      canvas.drawPath(loop, Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * .0024
        ..color = const Color(0x99FFB33C).withValues(alpha: .42 + .2 * pulse));
    }

    // Black lunar disc with subtle reflected rim and a tiny gravitationally bent highlight.
    canvas.drawCircle(
      center,
      sunRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.38, -.42),
          colors: const [Color(0xFF120704), Color(0xFF050202), Color(0xFF000000)],
          stops: const [0, .48, 1],
        ).createShader(Rect.fromCircle(center: center, radius: sunRadius)),
    );
    canvas.drawCircle(
      center,
      sunRadius * 1.015,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .0025
        ..color = const Color(0xCCFFE6A1).withValues(alpha: .54 + .18 * pulse),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: sunRadius * 1.035),
      -math.pi * .92,
      math.pi * .64,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .005
        ..color = const Color(0xCCFFF4C2).withValues(alpha: .78),
    );

    // Minimal star-like glints and distant ember points, placed deterministically.
    for (var i = 0; i < 11; i++) {
      final angle = i * 2.399963;
      final distance = r * (.34 + .045 * (i % 4));
      final p = center + Offset(math.cos(angle + t * .14) * distance, math.sin(angle + t * .14) * distance);
      final twinkle = .35 + .65 * (.5 + .5 * math.sin(t * 4 * math.pi + i * 1.7));
      final radius = r * (.0015 + .0012 * twinkle);
      canvas.drawCircle(p, radius * 3.5, Paint()
        ..color = const Color(0xFFFFA33A).withValues(alpha: .18 * twinkle)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .004));
      canvas.drawCircle(p, radius, Paint()..color = const Color(0xFFFFE6A1).withValues(alpha: .55 * twinkle));
    }
  }
}

// ============================================================================
// Void Glass — graphite black with neon green
// ============================================================================

class VoidGlassEffect extends NebulaEffect {
  const VoidGlassEffect({super.key, required super.animate});

  @override
  Widget build(BuildContext context) {
    return _VoidGlassPainterWidget(animate: animate);
  }

  @override
  CustomPainter painter(double t) => _VoidGlassPainter(t);
}

class _VoidGlassPainterWidget extends StatefulWidget {
  final bool animate;
  const _VoidGlassPainterWidget({required this.animate});

  @override
  State<_VoidGlassPainterWidget> createState() => _VoidGlassPainterState();
}

class _VoidGlassPainterState extends State<_VoidGlassPainterWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 16));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _VoidGlassPainterWidget old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_controller.isAnimating) _controller.repeat();
    if (!widget.animate && _controller.isAnimating) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(painter: _VoidGlassPainter(_controller.value)),
    );
  }
}

class _VoidGlassPainter extends NebulaEffectPainter {
  const _VoidGlassPainter(super.t);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final focus = Offset(w * .5, h * .42);
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = RadialGradient(
      center: const Alignment(0, -.1), radius: 1.1,
      colors: const [Color(0x160E2818), Color(0x06070A08), Colors.transparent],
    ).createShader(rect));
    final line = Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = const Color(0x44AEFF35);
    for (var i = -7; i <= 7; i++) {
      final x = w * (.5 + i * .075);
      canvas.drawLine(focus, Offset(x, h * 1.08), line);
    }
    for (var i = 0; i < 9; i++) {
      final depth = ((i / 9.0 - t) % 1 + 1) % 1;
      final eased = depth * depth;
      final y = focus.dy + (h - focus.dy) * eased;
      final halfWidth = w * (.025 + .58 * depth);
      final alpha = .12 + .28 * (1 - depth);
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = depth < .16 ? 1.7 : .85
        ..color = const Color(0xFFAEFF35).withValues(alpha: alpha);
      final waveHeight = h * (.003 + .009 * depth);
      canvas.drawRect(Rect.fromCenter(center: Offset(focus.dx, y), width: halfWidth * 2, height: waveHeight < 1.0 ? 1.0 : waveHeight), p);
    }
    final reticle = Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = const Color(0x668EFF00);
    canvas.drawRect(Rect.fromCenter(center: focus, width: w * .035, height: w * .035), reticle);
  }
}

// ============================================================================
// Crimson Glass — burgundy black with dark red
// ============================================================================

class CrimsonGlassEffect extends NebulaEffect {
  const CrimsonGlassEffect({super.key, required super.animate});

  @override
  Widget build(BuildContext context) {
    return _CrimsonGlassPainterWidget(animate: animate);
  }

  @override
  CustomPainter painter(double t) => _CrimsonGlassPainter(t);
}

class _CrimsonGlassPainterWidget extends StatefulWidget {
  final bool animate;
  const _CrimsonGlassPainterWidget({required this.animate});

  @override
  State<_CrimsonGlassPainterWidget> createState() => _CrimsonGlassPainterState();
}

class _CrimsonGlassPainterState extends State<_CrimsonGlassPainterWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 8));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _CrimsonGlassPainterWidget old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_controller.isAnimating) _controller.repeat();
    if (!widget.animate && _controller.isAnimating) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(painter: _CrimsonGlassPainter(_controller.value)),
    );
  }
}

class _CrimsonGlassPainter extends NebulaEffectPainter {
  const _CrimsonGlassPainter(super.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide;

    // Slow pulsing burgundy orb
    final pulse = .5 + .5 * math.sin(t * 2 * math.pi);
    canvas.drawCircle(
      center,
      r * (.2 + .1 * pulse),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color(0x66AD1457),
            Color(0x22880E4F),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r * (.2 + .1 * pulse))),
    );
  }
}

// ============================================================================
// Neon Glass — hot pink and electric blue
// ============================================================================

class NeonGlassEffect extends NebulaEffect {
  const NeonGlassEffect({super.key, required super.animate});

  @override
  Widget build(BuildContext context) {
    return _NeonGlassPainterWidget(animate: animate);
  }

  @override
  CustomPainter painter(double t) => _NeonGlassPainter(t);
}

class _NeonGlassPainterWidget extends StatefulWidget {
  final bool animate;
  const _NeonGlassPainterWidget({required this.animate});

  @override
  State<_NeonGlassPainterWidget> createState() => _NeonGlassPainterState();
}

class _NeonGlassPainterState extends State<_NeonGlassPainterWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 11));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _NeonGlassPainterWidget old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_controller.isAnimating) _controller.repeat();
    if (!widget.animate && _controller.isAnimating) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(painter: _NeonGlassPainter(_controller.value)),
    );
  }
}

class _NeonGlassPainter extends NebulaEffectPainter {
  const _NeonGlassPainter(super.t);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .5, size.height * .46);
    final r = size.shortestSide;
    final rect = Offset.zero & size;
    const magenta = Color(0x66FF2BD6);
    const cyan = Color(0x6624EFFF);
    canvas.drawCircle(center, r * (.43 + .018 * math.sin(t * 2 * math.pi)), Paint()
      ..style = PaintingStyle.stroke..strokeWidth = r * .012
      ..shader = const SweepGradient(colors: [magenta, cyan, magenta]).createShader(Rect.fromCircle(center: center, radius: r * .43))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .006));
    final innerCenter = center + Offset(r * .035, -r * .02);
    canvas.drawCircle(innerCenter, r * .29, Paint()..style = PaintingStyle.stroke..strokeWidth = r * .006
      ..shader = const SweepGradient(colors: [cyan, Color(0x44FFFFFF), magenta, cyan]).createShader(Rect.fromCircle(center: innerCenter, radius: r * .29)));
    final y = size.height * (.18 + .62 * t);
    final scanHeight = r * .002 < 1 ? 1.0 : r * .002;
    canvas.drawRect(Rect.fromLTWH(0, y, size.width, scanHeight), Paint()
      ..shader = LinearGradient(colors: const [Colors.transparent, Color(0x44FF2BD6), Color(0x4424EFFF), Colors.transparent]).createShader(rect));
  }
}

// ============================================================================
// Emerald Glass — deep forest emerald with gold veins
// ============================================================================

class EmeraldGlassEffect extends NebulaEffect {
  const EmeraldGlassEffect({super.key, required super.animate});

  @override
  Widget build(BuildContext context) {
    return _EmeraldGlassPainterWidget(animate: animate);
  }

  @override
  CustomPainter painter(double t) => _EmeraldGlassPainter(t);
}

class _EmeraldGlassPainterWidget extends StatefulWidget {
  final bool animate;
  const _EmeraldGlassPainterWidget({required this.animate});

  @override
  State<_EmeraldGlassPainterWidget> createState() => _EmeraldGlassPainterState();
}

class _EmeraldGlassPainterState extends State<_EmeraldGlassPainterWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 19));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _EmeraldGlassPainterWidget old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_controller.isAnimating) _controller.repeat();
    if (!widget.animate && _controller.isAnimating) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(painter: _EmeraldGlassPainter(_controller.value)),
    );
  }
}

class _EmeraldGlassPainter extends NebulaEffectPainter {
  const _EmeraldGlassPainter(super.t);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final veins = <Path>[
      Path()..moveTo(w*.08,h*1.02)..cubicTo(w*.24,h*.78,w*.34,h*.66,w*.5,h*.42)..cubicTo(w*.60,h*.29,w*.78,h*.19,w*.90,-h*.04),
      Path()..moveTo(w*.24,h*.83)..cubicTo(w*.17,h*.68,w*.16,h*.53,w*.06,h*.43),
      Path()..moveTo(w*.32,h*.68)..cubicTo(w*.39,h*.58,w*.40,h*.47,w*.34,h*.35),
      Path()..moveTo(w*.49,h*.43)..cubicTo(w*.60,h*.46,w*.67,h*.55,w*.70,h*.68),
      Path()..moveTo(w*.62,h*.29)..cubicTo(w*.74,h*.30,w*.81,h*.38,w*.95,h*.36),
      Path()..moveTo(w*.39,h*.57)..cubicTo(w*.31,h*.48,w*.25,h*.44,w*.20,h*.29),
      Path()..moveTo(w*.72,h*.55)..cubicTo(w*.79,h*.63,w*.83,h*.71,w*.84,h*.86),
    ];
    for (var i = 0; i < veins.length; i++) {
      canvas.drawPath(veins[i], Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round
        ..strokeWidth = w * (i == 0 ? .006 : .003)..color = const Color(0xFF26C77A).withValues(alpha: i == 0 ? .28 : .18));
    }
    final metrics = veins.first.computeMetrics();
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final progress = Curves.easeInOutCubic.transform(t);
      canvas.drawPath(metric.extractPath(0, metric.length * progress), Paint()..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round..strokeWidth = w * .004..color = const Color(0x66D8B45B));
      final tangent = metric.getTangentForOffset(metric.length * progress);
      if (tangent != null) {
        canvas.drawCircle(tangent.position, w * .009, Paint()..color = const Color(0x44D8B45B));
        canvas.drawCircle(tangent.position, w * .003, Paint()..color = const Color(0x99D8B45B));
      }
    }
  }
}

// ============================================================================
// Aurora Glass — polar green and ice blue northern lights
// ============================================================================

/// Aurora Glass: cintas de luz polar verde/cian/azul que ondulan como una
/// aurora boreal sobre negro absoluto.
class AuroraGlassEffect extends NebulaEffect {
  const AuroraGlassEffect({super.key, required super.animate});

  @override
  Duration get duration => const Duration(seconds: 18);

  @override
  CustomPainter painter(double t) => _AuroraGlassPainter(t);
}

class _AuroraGlassPainter extends NebulaEffectPainter {
  const _AuroraGlassPainter(super.t);

  static const _ribbons = [
    [Color(0x6639FF9C), Color(0x0019E0C4)],
    [Color(0x553B82F6), Color(0x0022D3EE)],
    [Color(0x4439FF9C), Color(0x00A78BFA)],
    [Color(0x3322D3EE), Color(0x0039FF9C)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);

    // polar glow at the horizon
    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, .55),
        radius: 1.1,
        colors: [
          Color(0x3322D3EE),
          Color(0x1139FF9C),
          Colors.transparent,
        ],
        stops: const [0, .45, 1],
      ).createShader(rect);
    canvas.drawRect(rect, glow);

    // dancing ribbons
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * .05);

    for (var i = 0; i < _ribbons.length; i++) {
      final phase = t * 2 * math.pi + i * 1.7;
      final dx = math.sin(phase) * w * .1;
      final path = Path()
        ..moveTo(-w * .15 + dx, h * (1.1 - i * .06))
        ..cubicTo(
          w * .25 + dx,
          h * (.62 + .12 * math.sin(phase)),
          w * .62 - dx,
          h * (.22 + .14 * math.cos(phase)),
          w * 1.15 + dx,
          -h * .1,
        );
      paint
        ..strokeWidth = w * (.2 - i * .035)
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: _ribbons[i],
        ).createShader(rect);
      canvas.drawPath(path, paint);
    }

    // ice sparkles in the sky
    final sparkle = Paint()..color = Color(0xFFFFFFFF).withValues(alpha: .5);
    for (var i = 0; i < 9; i++) {
      final a = i * 2.399963;
      final dist = size.shortestSide * (.18 + .1 * (i % 4));
      final center = size.center(Offset.zero);
      final twinkle = .3 + .7 * (.5 + .5 * math.sin(t * 4 * math.pi + i));
      canvas.drawCircle(
        center + Offset(math.cos(a + t) * dist, math.sin(a + t) * dist),
        w * .0025 * twinkle,
        sparkle,
      );
    }
  }
}

// ============================================================================
// Sapphire Glass — deep royal sapphire with brilliant cyan glints
// ============================================================================

/// Sapphire Glass: zafiro azul profundo con destellos cian que titilan como
/// estrellas sobre terciopelo.
class SapphireGlassEffect extends NebulaEffect {
  const SapphireGlassEffect({super.key, required super.animate});

  @override
  Duration get duration => const Duration(seconds: 14);

  @override
  CustomPainter painter(double t) => _SapphireGlassPainter(t);
}

class _SapphireGlassPainter extends NebulaEffectPainter {
  const _SapphireGlassPainter(super.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide;

    // breathing royal core
    final breath = .5 + .5 * math.sin(t * 2 * math.pi);
    final coreRadius = r * (.5 + .06 * breath);
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color(0x66244BFF),
            Color(0x1A0B1E6B),
            Colors.transparent,
          ],
          stops: const [0, .5, 1],
        ).createShader(Rect.fromCircle(center: center, radius: coreRadius)),
    );

    // brilliant cyan glints, each on its own phase
    for (var i = 0; i < 16; i++) {
      final angle = i * 2.399963 + t * .5;
      final distance = r * (.1 + .04 * (i % 5));
      final twinkle = .5 + .5 * math.sin(t * 6 * math.pi + i * 1.7);
      final glintCenter = center + Offset(math.cos(angle) * distance, math.sin(angle) * distance);
      final glintRadius = r * (.003 + .007 * twinkle);

      canvas.drawCircle(
        glintCenter,
        glintRadius * 3,
        Paint()
          ..color = Color(0xFF22D3EE).withValues(alpha: .18 * twinkle)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glintRadius * 2),
      );
      canvas.drawCircle(
        glintCenter,
        glintRadius,
        Paint()..color = Color(0xFFE0F7FF).withValues(alpha: .85 * twinkle),
      );
    }
  }
}

// ============================================================================
// Amber Glass — warm fossil amber with honey and gold
// ============================================================================

/// Amber Glass: ámbar fósil cálido, con un núcleo de miel que respira y anillos
/// dorados que se expanden lentamente.
class AmberGlassEffect extends NebulaEffect {
  const AmberGlassEffect({super.key, required super.animate});

  @override
  Duration get duration => const Duration(seconds: 16);

  @override
  CustomPainter painter(double t) => _AmberGlassPainter(t);
}

class _AmberGlassPainter extends NebulaEffectPainter {
  const _AmberGlassPainter(super.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide;

    // honey core
    final pulse = .5 + .5 * math.sin(t * 2 * math.pi);
    final coreRadius = r * (.32 + .05 * pulse);
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color(0x88FFC107),
            Color(0x44FF7A18),
            Colors.transparent,
          ],
          stops: const [0, .55, 1],
        ).createShader(Rect.fromCircle(center: center, radius: coreRadius)),
    );

    // expanding honey rings
    for (var i = 0; i < 3; i++) {
      final progress = (t + i / 3) % 1;
      final radius = r * (.16 + .52 * progress);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * .012
          ..color = Color(0xFFFFC107).withValues(alpha: (1 - progress) * .3)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .015),
      );
    }

    // golden specks like trapped bubbles
    for (var i = 0; i < 10; i++) {
      final angle = i * 2.399963;
      final distance = r * (.08 + .05 * (i % 4));
      final drift = .4 + .6 * (.5 + .5 * math.sin(t * 4 * math.pi + i));
      canvas.drawCircle(
        center + Offset(math.cos(angle) * distance, math.sin(angle) * distance - r * .04 * drift),
        r * .006 * drift,
        Paint()..color = Color(0xFFFFE082).withValues(alpha: .5 * drift),
      );
    }
  }
}

// ============================================================================
// Onyx Glass — pure black with graphite shimmer
// ============================================================================

/// Onyx Glass: negro puro y minimalista, recorrido por un brillo de grafito que
/// barre la pantalla en diagonal.
class OnyxGlassEffect extends NebulaEffect {
  const OnyxGlassEffect({super.key, required super.animate});

  @override
  Duration get duration => const Duration(seconds: 15);

  // continuous sweep: reversing it would look like a bounce
  @override
  bool get reverse => false;

  @override
  CustomPainter painter(double t) => _OnyxGlassPainter(t);
}

class _OnyxGlassPainter extends NebulaEffectPainter {
  const _OnyxGlassPainter(super.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shift = -2.5 + 5 * t;

    // graphite sheen travelling across the black
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(shift - 1.2, -1),
          end: Alignment(shift + 1.2, 1),
          colors: const [
            Color(0x00000000),
            Color(0x0DFFFFFF),
            Color(0x1FFFFFFF),
            Color(0x0DFFFFFF),
            Color(0x00000000),
          ],
          stops: const [0, .34, .5, .66, 1],
        ).createShader(rect),
    );

    // soft vignette keeps the monochrome look deep
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [Color(0x00000000), Color(0x88000000)],
          stops: const [.55, 1],
        ).createShader(rect),
    );
  }
}

// ============================================================================
// Pearl Glass — soft pearl white with iridescence
// ============================================================================

/// Pearl Glass: nácar luminoso, con iridiscencias pastel girando muy despacio y
/// un halo blanco que respira.
class PearlGlassEffect extends NebulaEffect {
  const PearlGlassEffect({super.key, required super.animate});

  @override
  Duration get duration => const Duration(seconds: 20);

  // always spinning the same way avoids a visible "rewind"
  @override
  bool get reverse => false;

  @override
  CustomPainter painter(double t) => _PearlGlassPainter(t);
}

class _PearlGlassPainter extends NebulaEffectPainter {
  const _PearlGlassPainter(super.t);

  static const _iridescence = [
    Color(0x33FFD1DC), // shell pink
    Color(0x33E0F7FA), // ice
    Color(0x33EDE7F6), // lavender
    Color(0x33FFF8E1), // champagne
    Color(0x33B2EBF2), // aqua
    Color(0x33FFD1DC),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide;

    // slow iridescent shell
    final radius = r * .75;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = SweepGradient(
          colors: _iridescence,
          stops: const [0, .2, .4, .6, .8, 1],
          transform: GradientRotation(t * 2 * math.pi),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .05),
    );

    // breathing pearl halo
    final halo = .5 + .5 * math.sin(t * 2 * math.pi);
    canvas.drawCircle(
      center,
      r * (.22 + .06 * halo),
      Paint()
        ..color = Color(0xFFFFFFFF).withValues(alpha: .16 + .1 * halo)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .12),
    );
  }
}

// ============================================================================
// Ivory Glass — warm ivory cream with champagne gold veins
// ============================================================================

/// Ivory Glass: marfil cálido con vetas de oro champán que se mecen lentamente.
class IvoryGlassEffect extends NebulaEffect {
  const IvoryGlassEffect({super.key, required super.animate});

  @override
  Duration get duration => const Duration(seconds: 19);

  @override
  CustomPainter painter(double t) => _IvoryGlassPainter(t);
}

class _IvoryGlassPainter extends NebulaEffectPainter {
  const _IvoryGlassPainter(super.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);

    // warm ivory wash
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -.2),
          radius: 1.2,
          colors: [
            Color(0x14FFF3E0),
            Color(0x08FFE0B2),
            Colors.transparent,
          ],
          stops: const [0, .5, 1],
        ).createShader(rect),
    );

    // champagne gold veins
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * .004
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * .003);

    for (var i = 0; i < 4; i++) {
      final phase = t * 2 * math.pi + i * 1.3;
      final sway = math.sin(phase) * w * .04;
      final baseX = w * (i * .28);
      final path = Path()
        ..moveTo(baseX + sway, -h * .05)
        ..cubicTo(
          baseX + w * .12 - sway,
          h * .3,
          baseX - w * .1 + sway,
          h * .7,
          baseX + w * .06 + sway,
          h * 1.05,
        );
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0x00FFE082),
          Color(0x99FFD54F),
          Color(0x00FFE082),
        ],
        stops: const [0, .5, 1],
        transform: GradientRotation(math.sin(phase) * .18),
      ).createShader(rect);
      canvas.drawPath(path, paint);
    }
  }
}

// ============================================================================
// Night Demon — purple hellfire (Obsidian Glass)
// ============================================================================

/// Night Demon: brasas violeta que suben desde un resplandor de fuego que respira
/// en la base, sobre un círculo de invocación casi invisible que gira muy despacio.
class NightDemonEffect extends NebulaEffect {
  const NightDemonEffect({super.key, required super.animate});

  @override
  Duration get duration => const Duration(seconds: 16);

  // seamless loop: it must not play backwards
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

  // seamless loop: it must not play backwards
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
// Imperial Glass — gunmetal steel with brass rivets and aquila gold
// ============================================================================

/// Imperial Glass: acero pavonado, remaches de latón, pergamino y oro águila.
/// Efecto industrial: barrido de luz sobre metal rayado, con destellos de latón.
class ImperialGlassEffect extends NebulaEffect {
  const ImperialGlassEffect({super.key, required super.animate});

  @override
  Duration get duration => const Duration(seconds: 18);

  // continuous sweep like a forge inspection lamp
  @override
  bool get reverse => false;

  @override
  CustomPainter painter(double t) => _ImperialGlassPainter(t);
}

class _ImperialGlassPainter extends NebulaEffectPainter {
  const _ImperialGlassPainter(super.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);
    final center = size.center(Offset.zero);
    final r = size.shortestSide;

    // gunmetal base with subtle scratches
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, .1),
          radius: 1.1,
          colors: [
            Color(0xFF2A2A2A),
            Color(0xFF181818),
            Color(0xFF0C0C0C),
          ],
          stops: const [0, .6, 1],
        ).createShader(rect),
    );

    // diagonal scratch texture (static noise approximation)
    final scratchPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .5
      ..color = Color(0x11FFFFFF);
    for (var i = 0; i < 12; i++) {
      final y = -h + (i * h / 6) + (t * h * .3 % (h / 6));
      canvas.drawLine(Offset(-w, y), Offset(w * 2, y + w * .6), scratchPaint);
    }

    // sweeping inspection lamp (brass gold)
    final shift = -1.2 + 2.4 * t;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(shift - .6, -1),
          end: Alignment(shift + .6, 1),
          colors: const [
            Color(0x00D4A72A),
            Color(0x33D4A72A),
            Color(0x66D4A72A),
            Color(0x33D4A72A),
            Color(0x00D4A72A),
          ],
          stops: const [0, .25, .5, .75, 1],
        ).createShader(rect),
    );

    // rivet glints at the corners
    final rivetPaint = Paint()..color = Color(0xFFD4A72A);
    final rivetR = w * .018;
    for (final corner in [
      Offset(rivetR * 3, rivetR * 3),
      Offset(w - rivetR * 3, rivetR * 3),
      Offset(rivetR * 3, h - rivetR * 3),
      Offset(w - rivetR * 3, h - rivetR * 3),
    ]) {
      final twinkle = .5 + .5 * math.sin(t * 4 * math.pi + corner.dx * .01);
      canvas.drawCircle(corner, rivetR * twinkle, rivetPaint);
      canvas.drawCircle(corner, rivetR * .6, Paint()..color = Color(0xFFFFF8E7).withValues(alpha: .8 * twinkle));
    }

    // central aquila pulse (very subtle)
    final aquilaPulse = .5 + .5 * math.sin(t * 2 * math.pi);
    canvas.drawCircle(
      center,
      r * (.12 + .02 * aquilaPulse),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color(0x00D4A72A),
            Color(0x11D4A72A),
            Color(0x00D4A72A),
          ],
          stops: const [0, .5, 1],
        ).createShader(Rect.fromCircle(center: center, radius: r * .15)),
    );
  }
}

// ============================================================================
// Factory
// ============================================================================

/// Crea el efecto visual para un tema dado, o null si el tema no tiene efecto
/// propio (Fase 1 o temas sin efecto implementado).
NebulaEffect? nebulaEffectFor(NebulaTheme theme, {required bool animate}) => switch (theme) {
  NebulaTheme.obsidianGlass => NightDemonEffect(animate: animate),
  NebulaTheme.aureateGlass => GodlyEffect(animate: animate),
  NebulaTheme.forgeGlass => ForgeGlassEffect(animate: animate),
  NebulaTheme.hermeticGlass => HermeticGlassEffect(animate: animate),
  NebulaTheme.eclipseGlass => EclipseGlassEffect(animate: animate),
  NebulaTheme.solarFlareGlass => SolarFlareGlassEffect(animate: animate),
  NebulaTheme.voidGlass => VoidGlassEffect(animate: animate),
  NebulaTheme.crimsonGlass => CrimsonGlassEffect(animate: animate),
  NebulaTheme.neonGlass => NeonGlassEffect(animate: animate),
  NebulaTheme.emeraldGlass => EmeraldGlassEffect(animate: animate),
  NebulaTheme.auroraGlass => AuroraGlassEffect(animate: animate),
  NebulaTheme.sapphireGlass => SapphireGlassEffect(animate: animate),
  NebulaTheme.amberGlass => AmberGlassEffect(animate: animate),
  NebulaTheme.onyxGlass => OnyxGlassEffect(animate: animate),
  NebulaTheme.pearlGlass => PearlGlassEffect(animate: animate),
  NebulaTheme.ivoryGlass => IvoryGlassEffect(animate: animate),
  NebulaTheme.imperialGlass => ImperialGlassEffect(animate: animate),
  _ => null,
};
