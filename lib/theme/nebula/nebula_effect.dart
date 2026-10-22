import 'dart:math' as math;
import 'dart:ui' show BlurStyle, MaskFilter;
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
abstract class NebulaEffect extends StatelessWidget {
  final bool animate;

  const NebulaEffect({super.key, required this.animate});

  /// Construye el pintor para este efecto.
  CustomPainter painter(double t);
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
      AnimationController(vsync: this, duration: const Duration(seconds: 10));

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
      final phase = t + i * (2 * math.pi / _ringColors.length);
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
    final glow = .6 + .4 * math.sin(t * 3 * math.pi);
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
      AnimationController(vsync: this, duration: const Duration(seconds: 14));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _EclipseGlassPainterWidget old) {
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
      builder: (_, __) => CustomPaint(painter: _EclipseGlassPainter(_controller.value)),
    );
  }
}

class _EclipseGlassPainter extends NebulaEffectPainter {
  const _EclipseGlassPainter(super.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide;

    // Slowly drifting cyan nebula over midnight blue
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color(0x4400B0FF),
            Color(0x1A0066CC),
            Color(0x05003366),
            Colors.transparent,
          ],
          stops: const [0, .35, .7, 1],
          transform: GradientRotation(t * math.pi),
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
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
    final center = size.center(Offset.zero);
    final r = size.shortestSide;

    // Solar flare pulses
    final pulse = .5 + .5 * math.sin(t * 4 * math.pi);
    canvas.drawCircle(
      center,
      r * (.3 + .2 * pulse),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color(0x55FFF176),
            Color(0x22FFF176),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r * (.3 + .2 * pulse))),
    );

    // Coronal loops
    canvas.drawCircle(
      center,
      r * .7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Color(0xFF000000).withValues(alpha: .25)
        ..shader = SweepGradient(
          colors: [Color(0x33FFFF76), Color(0x00FFFF76), Color(0x33FFFF76)],
          transform: GradientRotation(t * 2 * math.pi),
        ).createShader(Rect.fromCircle(center: center, radius: r * .7)),
    );
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
      AnimationController(vsync: this, duration: const Duration(seconds: 13));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _VoidGlassPainterWidget old) {
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
      builder: (_, __) => CustomPaint(painter: _VoidGlassPainter(_controller.value)),
    );
  }
}

class _VoidGlassPainter extends NebulaEffectPainter {
  const _VoidGlassPainter(super.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide;

    // Neon green grid-like pulses on graphite
    for (var i = 0; i < 3; i++) {
      final phase = t + i * 2 * math.pi / 3;
      final radius = r * (.15 + .1 * math.sin(phase));
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Color(0xFF00E676).withValues(alpha: .15 + .1 * math.sin(phase * 2))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
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
      AnimationController(vsync: this, duration: const Duration(seconds: 9));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _CrimsonGlassPainterWidget old) {
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
      AnimationController(vsync: this, duration: const Duration(seconds: 8));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _NeonGlassPainterWidget old) {
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
      builder: (_, __) => CustomPaint(painter: _NeonGlassPainter(_controller.value)),
    );
  }
}

class _NeonGlassPainter extends NebulaEffectPainter {
  const _NeonGlassPainter(super.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide;

    // Alternating pink/blue neon rings
    canvas.drawCircle(
      center,
      r * (.5 + .1 * math.sin(t * 2 * math.pi)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..shader = SweepGradient(
          colors: [Color(0x44FF00FF), Color(0x4400FFFF), Color(0x44FF00FF)],
          transform: GradientRotation(t * math.pi),
        ).createShader(Rect.fromCircle(center: center, radius: r * .5)),
    );
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
      AnimationController(vsync: this, duration: const Duration(seconds: 12));

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
    final center = size.center(Offset.zero);
    final r = size.shortestSide;

    // Emerald veins like tree roots, slowly shifting
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color(0x3300C853),
            Color(0x1100897B),
            Color(0x05004D40),
            Colors.transparent,
          ],
          stops: const [0, .4, .75, 1],
          transform: GradientRotation(t * math.pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Gold vein glint
    canvas.drawCircle(
      center,
      r * (.35 + .05 * math.sin(t * 3 * math.pi)),
      Paint()
        ..shader = SweepGradient(
          colors: [Color(0x22FFB300), Color(0x00FFB300), Color(0x22FFB300)],
          transform: GradientRotation(-t * math.pi),
        ).createShader(Rect.fromCircle(center: center, radius: r * .35)),
    );
  }
}

// ============================================================================
// Factory
// ============================================================================

/// Crea el efecto visual para un tema dado, o null si el tema no tiene efecto
/// propio (Fase 1 o temas sin efecto implementado).
NebulaEffect? nebulaEffectFor(NebulaTheme theme, {required bool animate}) => switch (theme) {
  NebulaTheme.forgeGlass => ForgeGlassEffect(animate: animate),
  NebulaTheme.hermeticGlass => HermeticGlassEffect(animate: animate),
  NebulaTheme.eclipseGlass => EclipseGlassEffect(animate: animate),
  NebulaTheme.solarFlareGlass => SolarFlareGlassEffect(animate: animate),
  NebulaTheme.voidGlass => VoidGlassEffect(animate: animate),
  NebulaTheme.crimsonGlass => CrimsonGlassEffect(animate: animate),
  NebulaTheme.neonGlass => NeonGlassEffect(animate: animate),
  NebulaTheme.emeraldGlass => EmeraldGlassEffect(animate: animate),
  NebulaTheme.auroraGlass => null,
  NebulaTheme.sapphireGlass => null,
  NebulaTheme.amberGlass => null,
  NebulaTheme.onyxGlass => null,
  NebulaTheme.pearlGlass => null,
  NebulaTheme.ivoryGlass => null,
  _ => null,
};
