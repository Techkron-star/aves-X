import 'dart:math' as math;
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
  Duration get duration => const Duration(seconds: 10);

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
  Duration get duration => const Duration(seconds: 22);

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
// Obsidian Glass — blood-ruby crystal over near-black surfaces
// ============================================================================

/// Obsidian Glass: cristales de rubí sangriento sobre negro profundo,
/// con pulsos lentos y vetas que respiran como venas.
class ObsidianGlassEffect extends NebulaEffect {
  const ObsidianGlassEffect({super.key, required super.animate});

  @override
  Duration get duration => const Duration(seconds: 15);

  @override
  CustomPainter painter(double t) => _ObsidianGlassPainter(t);
}

class _ObsidianGlassPainter extends NebulaEffectPainter {
  const _ObsidianGlassPainter(super.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide;

    // deep crimson core pulse
    final pulse = .5 + .5 * math.sin(t * 2 * math.pi);
    final coreRadius = r * (.35 + .08 * pulse);
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color(0x88E0183E),
            Color(0x448B0016),
            Colors.transparent,
          ],
          stops: const [0, .55, 1],
        ).createShader(Rect.fromCircle(center: center, radius: coreRadius)),
    );

    // breathing ruby veins
    for (var i = 0; i < 5; i++) {
      final angle = i * 2.513274;
      final phase = t * 2 * math.pi + i * 1.2;
      final length = r * (.25 + .06 * math.sin(phase));
      final width = r * (.008 + .003 * math.sin(phase * 2));
      final veinPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width
        ..shader = LinearGradient(
          begin: Alignment.center,
          end: Alignment(angle, 0),
          colors: [
            Color(0x00E0183E),
            Color(0xCCE0183E),
            Color(0x00E0183E),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: length));
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..quadraticBezierTo(
            center.dx + math.cos(angle) * length * .5,
            center.dy + math.sin(angle) * length * .5,
            center.dx + math.cos(angle) * length,
            center.dy + math.sin(angle) * length,
          ),
        veinPaint,
      );
    }

    // subtle ruby dust motes
    for (var i = 0; i < 8; i++) {
      final a = i * 2.399963 + t * .3;
      final dist = r * (.3 + .15 * math.sin(t * 3 * math.pi + i));
      final twinkle = .4 + .6 * (.5 + .5 * math.sin(t * 5 * math.pi + i * 1.3));
      canvas.drawCircle(
        center + Offset(math.cos(a) * dist, math.sin(a) * dist),
        r * .002 * twinkle,
        Paint()..color = Color(0xFFFF6B8A).withValues(alpha: .6 * twinkle),
      );
    }
  }
}

// ============================================================================
// Aureate Glass — gold crystal
// ============================================================================

/// Aureate Glass: oro puro y cristal, con un núcleo que late y filamentos
/// dorados que se estiran y contraen como hilos de luz.
class AureateGlassEffect extends NebulaEffect {
  const AureateGlassEffect({super.key, required super.animate});

  @override
  Duration get duration => const Duration(seconds: 18);

  @override
  CustomPainter painter(double t) => _AureateGlassPainter(t);
}

class _AureateGlassPainter extends NebulaEffectPainter {
  const _AureateGlassPainter(super.t);

  static const _goldStops = [
    Color(0xFFFFF8E1),
    Color(0xFFFFECB3),
    Color(0xFFFFD54F),
    Color(0xFFFFC107),
    Color(0xFFF9A825),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide;

    // radiant gold core
    final pulse = .5 + .5 * math.sin(t * 2 * math.pi);
    final coreRadius = r * (.4 + .06 * pulse);
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color(0xCCFFF8E1),
            Color(0x66FFD54F),
            Color(0x22FFC107),
            Colors.transparent,
          ],
          stops: const [0, .3, .65, 1],
        ).createShader(Rect.fromCircle(center: center, radius: coreRadius)),
    );

    // gold filaments stretching and retracting
    final filamentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .02);

    for (var i = 0; i < 12; i++) {
      final baseAngle = i * 2.617994;
      final phase = t * math.pi + i * .8;
      final length = r * (.25 + .4 * (.5 + .5 * math.sin(phase)));
      final width = r * (.004 + .008 * (.5 + .5 * math.sin(phase * 1.5)));
      filamentPaint.strokeWidth = width;
      filamentPaint.shader = LinearGradient(
        begin: Alignment.center,
        end: Alignment(baseAngle, 0),
        colors: _goldStops,
      ).createShader(Rect.fromCircle(center: center, radius: length));
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..quadraticBezierTo(
            center.dx + math.cos(baseAngle + .2 * math.sin(phase)) * length * .5,
            center.dy + math.sin(baseAngle + .2 * math.sin(phase)) * length * .5,
            center.dx + math.cos(baseAngle) * length,
            center.dy + math.sin(baseAngle) * length,
          ),
        filamentPaint,
      );
    }

    // golden sparkles
    for (var i = 0; i < 10; i++) {
      final a = i * 2.399963 + t * .4;
      final dist = r * (.2 + .35 * (.5 + .5 * math.sin(t * 2.5 * math.pi + i)));
      final twinkle = .3 + .7 * (.5 + .5 * math.sin(t * 6 * math.pi + i * 1.1));
      canvas.drawCircle(
        center + Offset(math.cos(a) * dist, math.sin(a) * dist),
        r * .003 * twinkle,
        Paint()..color = Color(0xFFFFF8E1).withValues(alpha: .9 * twinkle),
      );
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
  Duration get duration => const Duration(seconds: 12);

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
  NebulaTheme.obsidianGlass => ObsidianGlassEffect(animate: animate),
  NebulaTheme.aureateGlass => AureateGlassEffect(animate: animate),
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
