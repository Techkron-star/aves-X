import 'dart:math' as math;

import 'package:aves/theme/nebula/nebula_material.dart';
import 'package:flutter/material.dart';

/// Surface roles are intentionally component-specific. A theme should feel related
/// across the app without stamping the same central motif onto every rectangle.
enum NebulaComponentSurfaceRole {
  navigationBar,
  drawerHeader,
  searchBar,
  appLockBackdrop,
  lockdownBackdrop,
  appLockCard,
  lockdownCard,
  securityInput,
}

/// Semantic state changes alter the energy and emphasis of a component surface.
enum NebulaComponentSurfaceState {
  idle,
  selected,
  focused,
  warning,
  success,
  disabled,
}

/// Adds a lightweight, procedural accent layer to an existing component.
///
/// This first migration slice targets Eclipse and Hermetic only. Obsidian,
/// Imperial, Nosferatu and the other established materials keep their current
/// renderers until their own role recipes are migrated and visually reviewed.
/// No bitmap is used: each role draws different vector geometry at its actual size.
class NebulaComponentSurfaceAccent extends StatefulWidget {
  final NebulaMaterialStyle? style;
  final NebulaComponentSurfaceRole role;
  final NebulaComponentSurfaceState state;
  final bool animate;
  final Color? alertColor;
  final double? focalPosition;
  final BorderRadius borderRadius;
  final Widget child;

  const NebulaComponentSurfaceAccent({
    super.key,
    required this.style,
    required this.role,
    required this.child,
    this.state = NebulaComponentSurfaceState.idle,
    this.animate = true,
    this.alertColor,
    this.focalPosition,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  State<NebulaComponentSurfaceAccent> createState() => _NebulaComponentSurfaceAccentState();
}

class _NebulaComponentSurfaceAccentState extends State<NebulaComponentSurfaceAccent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration(widget.role),
    value: .28,
  );

  static Duration _duration(NebulaComponentSurfaceRole role) => switch (role) {
        NebulaComponentSurfaceRole.navigationBar => const Duration(seconds: 9),
        NebulaComponentSurfaceRole.drawerHeader => const Duration(seconds: 13),
        NebulaComponentSurfaceRole.searchBar => const Duration(seconds: 5),
        NebulaComponentSurfaceRole.appLockBackdrop => const Duration(seconds: 12),
        NebulaComponentSurfaceRole.lockdownBackdrop => const Duration(seconds: 5),
        NebulaComponentSurfaceRole.appLockCard => const Duration(seconds: 9),
        NebulaComponentSurfaceRole.lockdownCard => const Duration(seconds: 4),
        NebulaComponentSurfaceRole.securityInput => const Duration(seconds: 3),
      };

  bool get _supported {
    final material = widget.style?.material;
    return material == NebulaMaterial.eclipse || material == NebulaMaterial.hermetic;
  }

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant NebulaComponentSurfaceAccent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role) {
      _controller.duration = _duration(widget.role);
      _controller.value = .28;
    }
    _syncAnimation();
  }

  void _syncAnimation() {
    final shouldAnimate = _supported &&
        widget.animate &&
        widget.state != NebulaComponentSurfaceState.disabled;
    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldAnimate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = widget.state == NebulaComponentSurfaceState.warning ? .5 : .28;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Avoid extra tickers and layers for themes whose specialized art is not part
    // of this migration slice.
    if (!_supported) return widget.child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _NebulaComponentSurfacePainter(
                    style: widget.style!,
                    role: widget.role,
                    state: widget.state,
                    progress: _controller.value,
                    alertColor: widget.alertColor,
                    focalPosition: (widget.focalPosition ?? .5).clamp(0.0, 1.0).toDouble(),
                    borderRadius: widget.borderRadius,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NebulaComponentSurfacePainter extends CustomPainter {
  final NebulaMaterialStyle style;
  final NebulaComponentSurfaceRole role;
  final NebulaComponentSurfaceState state;
  final double progress;
  final Color? alertColor;
  final double focalPosition;
  final BorderRadius borderRadius;

  const _NebulaComponentSurfacePainter({
    required this.style,
    required this.role,
    required this.state,
    required this.progress,
    required this.alertColor,
    required this.focalPosition,
    required this.borderRadius,
  });

  bool get _hermetic => style.material == NebulaMaterial.hermetic;
  bool get _eclipse => style.material == NebulaMaterial.eclipse;
  bool get _urgent => state == NebulaComponentSurfaceState.warning;
  bool get _active =>
      state == NebulaComponentSurfaceState.selected ||
      state == NebulaComponentSurfaceState.focused ||
      _urgent;
  double get _pulse => .5 + .5 * math.sin(progress * math.pi * 2);
  Color get _accent => _urgent ? (alertColor ?? style.accent) : style.accent;
  Color get _light => _urgent ? (alertColor ?? style.liquidHighlight) : style.liquidHighlight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.clipRRect(borderRadius.toRRect(Offset.zero & size));

    switch (role) {
      case NebulaComponentSurfaceRole.navigationBar:
        _paintNavigation(canvas, size);
      case NebulaComponentSurfaceRole.drawerHeader:
        _paintDrawerHeader(canvas, size);
      case NebulaComponentSurfaceRole.searchBar:
        _paintSearchBar(canvas, size);
      case NebulaComponentSurfaceRole.appLockBackdrop:
        _paintAppLockBackdrop(canvas, size);
      case NebulaComponentSurfaceRole.lockdownBackdrop:
        _paintLockdownBackdrop(canvas, size);
      case NebulaComponentSurfaceRole.appLockCard:
        _paintLockCard(canvas, size);
      case NebulaComponentSurfaceRole.lockdownCard:
        _paintLockdownCard(canvas, size);
      case NebulaComponentSurfaceRole.securityInput:
        _paintSecurityInput(canvas, size);
    }
    canvas.restore();
  }

  void _paintNavigation(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final x = w * focalPosition;
    final y = h * .12;
    _line(canvas, Offset(w * .035, y), Offset(w * .965, y), _accent, .22, 1);
    _line(canvas, Offset(w * .08, h * .94), Offset(w * .92, h * .94), _accent, .12, .7);

    // The selected item gets an orbit/marker, not a generic pill-shaped glass stamp.
    final r = (h * .28).clamp(5.0, 18.0).toDouble();
    if (_eclipse) {
      final rect = Rect.fromCircle(center: Offset(x, y + 2), radius: r);
      _arc(canvas, rect, -math.pi * .85 + progress * .1, math.pi * 1.22,
          _light, _active ? .78 : .42, 1.3, glow: _active ? 4 : 0);
      final angle = -math.pi * .85 + progress * math.pi * 1.22;
      _dot(canvas, Offset(x + math.cos(angle) * r, y + 2 + math.sin(angle) * r),
          _light, _active ? 1.8 : 1.2, glow: _active ? 5 : 0);
    } else {
      for (var i = -2; i <= 2; i++) {
        final tickX = x + i * r * .42;
        final tickHeight = i == 0 ? h * .28 : h * .13;
        _line(canvas, Offset(tickX, y - tickHeight / 2),
            Offset(tickX, y + tickHeight / 2), _light,
            i == 0 ? .78 : .34, i == 0 ? 1.25 : .8);
      }
      final diamond = Path()
        ..moveTo(x, y - r * .46)
        ..lineTo(x + r * .34, y)
        ..lineTo(x, y + r * .46)
        ..lineTo(x - r * .34, y)
        ..close();
      _path(canvas, diamond, _light, _active ? .78 : .38, 1, glow: _active ? 3.5 : 0);
    }
    final travelX = w * (.06 + .88 * progress);
    _dot(canvas, Offset(travelX, h * .94), _light, _active ? 1.5 : .9, glow: _active ? 3 : 0);
  }

  void _paintDrawerHeader(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final ink = _accent;
    _line(canvas, Offset(w * .04, h * .08), Offset(w * .54, h * .08), ink, .26, .8);
    _line(canvas, Offset(w * .04, h * .08), Offset(w * .04, h * .34), ink, .24, .8);
    _line(canvas, Offset(w * .66, h * .92), Offset(w * .96, h * .92), ink, .2, .8);
    final r = (math.min(w, h) * .21).clamp(12.0, 38.0).toDouble();

    if (_eclipse) {
      // A crescent lives in the header's outer corner, away from the app mark/title.
      final center = Offset(w * .91, h * .25);
      _arc(canvas, Rect.fromCircle(center: center, radius: r),
          -math.pi * .72, math.pi * 1.36, _light, .52, 1.0, glow: 3);
      final a = -math.pi * .72 + progress * math.pi * 1.36;
      _dot(canvas, center + Offset(math.cos(a) * r, math.sin(a) * r),
          _light, 1.7, glow: 5);
      _line(canvas, Offset(w * .71, h * .06), Offset(w * .96, h * .06), _light, .25, .7);
    } else {
      final center = Offset(w * .88, h * .29);
      for (var i = 0; i < 3; i++) {
        final r2 = r * (.35 + i * .23);
        final path = Path()
          ..moveTo(center.dx, center.dy - r2)
          ..lineTo(center.dx + r2 * .78, center.dy + r2 * .48)
          ..lineTo(center.dx - r2 * .78, center.dy + r2 * .48)
          ..close();
        _path(canvas, path, i == 1 ? _light : ink, i == 1 ? .48 : .22, .8);
      }
      for (var i = 0; i < 5; i++) {
        final x = w * .72 + i * w * .045;
        _line(canvas, Offset(x, h * .8), Offset(x, h * (.8 - (i.isEven ? .08 : .04))), _light, .3, .7);
      }
    }
  }

  void _paintSearchBar(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final emphasis = _active ? .72 + .2 * _pulse : .3;
    _line(canvas, Offset(w * .035, h * .08), Offset(w * .965, h * .08), _accent, .2, .7);
    _line(canvas, Offset(w * .08, h * .94), Offset(w * .92, h * .94), _accent, _active ? .34 : .16, .8);
    final scanX = w * (.08 + .84 * progress);
    _line(canvas, Offset(scanX - w * .045, h * .1), Offset(scanX + w * .045, h * .1),
        _light, emphasis, 1.4, glow: _active ? 4.5 : 2);
    _dot(canvas, Offset(scanX, h * .1), _light, _active ? 1.8 : 1.1, glow: _active ? 5 : 2);

    if (_eclipse) {
      final center = Offset(w * .94, h * .49);
      final r = (h * .25).clamp(5.0, 14.0).toDouble();
      _arc(canvas, Rect.fromCircle(center: center, radius: r),
          -math.pi * .78, math.pi * 1.38, _light, _active ? .86 : .42, 1.1,
          glow: _active ? 4 : 0);
      _dot(canvas, center + Offset(math.cos(progress * math.pi * 1.38) * r,
          math.sin(progress * math.pi * 1.38) * r), _light, 1.3, glow: 3);
    } else {
      final x0 = w * .055;
      for (var i = 0; i < 4; i++) {
        final x = x0 + i * 5.0;
        _line(canvas, Offset(x, h * .36), Offset(x, h * .63), _light,
            .26 + (i == 3 ? .25 : 0), .75);
      }
      final x = w * .94;
      final y = h * .5;
      final diamond = Path()
        ..moveTo(x, y - 4)
        ..lineTo(x + 4, y)
        ..lineTo(x, y + 4)
        ..lineTo(x - 4, y)
        ..close();
      _path(canvas, diamond, _light, _active ? .85 : .5, 1, glow: _active ? 3 : 0);
    }
  }

  void _paintAppLockBackdrop(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final m = math.min(w, h);
    final pulse = .5 + .5 * math.sin(progress * math.pi * 2);
    // Wide, quiet orbital cuts live at the perimeter; the central lock card stays clear.
    _line(canvas, Offset(w * .025, h * .12), Offset(w * .18, h * .12),
        _accent, .12 + pulse * .05, .8);
    _line(canvas, Offset(w * .82, h * .88), Offset(w * .975, h * .88),
        _accent, .12 + pulse * .05, .8);
    if (_eclipse) {
      final topCenter = Offset(w * .13, h * .16);
      final topRadius = m * .095;
      _arc(canvas, Rect.fromCircle(center: topCenter, radius: topRadius),
          -math.pi * .15 + progress * .04, math.pi * 1.05,
          _light, .2 + pulse * .1, 1.05, glow: 5);
      final lowerCenter = Offset(w * .88, h * .83);
      final lowerRadius = m * .13;
      _arc(canvas, Rect.fromCircle(center: lowerCenter, radius: lowerRadius),
          math.pi * .12, math.pi * .66, _accent, .14 + pulse * .06, .9);
      final a = -math.pi * .15 + progress * .04 + math.pi * 1.05;
      _dot(canvas, topCenter + Offset(math.cos(a) * topRadius, math.sin(a) * topRadius),
          _light, 1.5, glow: 4);
    } else {
      // Hermetic uses a measured vertical axis and off-centre orbital ellipses,
      // rather than putting the full alchemical seal behind every security screen.
      final x = w * .91;
      _line(canvas, Offset(x, h * .12), Offset(x, h * .29), _light, .25 + pulse * .1, .8);
      _line(canvas, Offset(x - m * .035, h * .2), Offset(x + m * .035, h * .2), _light, .28, .8);
      for (var i = 0; i < 3; i++) {
        final r = m * (.035 + i * .017);
        final rect = Rect.fromCenter(center: Offset(w * .08, h * .84), width: r * 2, height: r * 1.5);
        _arc(canvas, rect, math.pi * .15 + progress * .025, math.pi * 1.25,
            i == 1 ? _light : _accent, .18 + pulse * .07, .8);
      }
    }
  }

  void _paintLockdownBackdrop(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final m = math.min(w, h);
    final pulse = .5 + .5 * math.sin(progress * math.pi * 2);
    final inset = m * .018;
    final length = m * .06;
    final alpha = _urgent ? .18 + pulse * .16 : .12;
    final frame = Path()
      ..moveTo(inset, inset + length)..lineTo(inset, inset)..lineTo(inset + length, inset)
      ..moveTo(w - inset - length * .45, inset)..lineTo(w - inset, inset)..lineTo(w - inset, inset + length)
      ..moveTo(inset, h - inset - length * .4)..lineTo(inset, h - inset)..lineTo(inset + length * .8, h - inset)
      ..moveTo(w - inset - length, h - inset)..lineTo(w - inset, h - inset)..lineTo(w - inset, h - inset - length * .5);
    _path(canvas, frame, _accent, alpha, 1.1, glow: _urgent ? 5 : 1.5);
    _line(canvas, Offset(w * .08, h * .045), Offset(w * .29, h * .045),
        _light, alpha * 1.5, 1, glow: _urgent ? 4 : 0);
    _line(canvas, Offset(w * .71, h * .955), Offset(w * .92, h * .955),
        _accent, alpha, .8);

    if (_eclipse) {
      // Two broken terminators oppose each other, signalling a forced interruption.
      final r = m * .065;
      _arc(canvas, Rect.fromCircle(center: Offset(w * .12, h * .13), radius: r),
          -math.pi * .25, math.pi * .56, _light, alpha * 1.6, 1, glow: _urgent ? 4 : 0);
      _arc(canvas, Rect.fromCircle(center: Offset(w * .88, h * .87), radius: r),
          math.pi * .75, math.pi * .56, _light, alpha * 1.6, 1, glow: _urgent ? 4 : 0);
    } else {
      // Hermetic's lockdown becomes an asymmetric calibration frame, not a seal.
      final x = w * .89, y = h * .13, tick = m * .018;
      for (var i = 0; i < 4; i++) {
        _line(canvas, Offset(x - i * tick * 1.4, y - tick),
            Offset(x - i * tick * 1.4, y + tick), _light, alpha * (1 - i * .13), .8);
      }
      _line(canvas, Offset(w * .11, h * .88), Offset(w * .16, h * .83), _light, alpha * 1.4, .9);
      _line(canvas, Offset(w * .16, h * .88), Offset(w * .21, h * .83), _accent, alpha, .9);
    }
    final movingX = w * (.08 + .84 * progress);
    _dot(canvas, Offset(movingX, inset), _light, _urgent ? 1.8 : 1.1, glow: _urgent ? 5 : 1.5);
  }

  void _paintLockCard(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final len = math.min(w, h) * .075;
    final inset = math.min(w, h) * .025;
    final corner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeWidth = 1.2
      ..color = _accent.withValues(alpha: _accent.a * (_active ? .68 : .34));
    final path = Path()
      ..moveTo(inset, inset + len)..lineTo(inset, inset)..lineTo(inset + len, inset)
      ..moveTo(w - inset - len, inset)..lineTo(w - inset, inset)..lineTo(w - inset, inset + len)
      ..moveTo(inset, h - inset - len)..lineTo(inset, h - inset)..lineTo(inset + len, h - inset)
      ..moveTo(w - inset - len, h - inset)..lineTo(w - inset, h - inset)..lineTo(w - inset, h - inset - len);
    _path(canvas, path, _light, _active ? .78 : .42, 1.1, glow: _active ? 4.5 : 0);

    // Keep the center unobstructed for the lock emblem. The identity mark sits high/right.
    final r = (math.min(w, h) * .045).clamp(10.0, 22.0).toDouble();
    final center = Offset(w * .91, h * .12);
    if (_eclipse) {
      _arc(canvas, Rect.fromCircle(center: center, radius: r),
          -math.pi * .88 + progress * .12, math.pi * .96, _light, .46 + _pulse * .2, 1.0, glow: 2.8);
      _dot(canvas, center + Offset(math.cos(progress * math.pi * .96 - math.pi * .88) * r,
          math.sin(progress * math.pi * .96 - math.pi * .88) * r), _light, 1.4, glow: 3.5);
    } else {
      final d = Path()
        ..moveTo(center.dx, center.dy - r)
        ..lineTo(center.dx + r * .72, center.dy)
        ..lineTo(center.dx, center.dy + r)
        ..lineTo(center.dx - r * .72, center.dy)
        ..close();
      _path(canvas, d, _light, .35 + _pulse * .28, .9);
      _line(canvas, Offset(center.dx, center.dy - r * .6),
          Offset(center.dx, center.dy + r * .6), _light, .48, .8);
    }
    canvas.drawPath(path, corner);
  }

  void _paintLockdownCard(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final alertStrength = _urgent ? .6 + _pulse * .3 : .32;
    final length = math.min(w, h) * .09;
    final inset = math.min(w, h) * .025;
    final frame = Path()
      ..moveTo(inset, inset + length)..lineTo(inset, inset)..lineTo(inset + length * .7, inset)
      ..moveTo(w - inset - length * .35, inset)..lineTo(w - inset, inset)..lineTo(w - inset, inset + length)
      ..moveTo(inset, h - inset - length * .35)..lineTo(inset, h - inset)..lineTo(inset + length, h - inset)
      ..moveTo(w - inset - length, h - inset)..lineTo(w - inset, h - inset)..lineTo(w - inset, h - inset - length * .6);
    _path(canvas, frame, _accent, alertStrength, 1.35, glow: _urgent ? 6 : 2);
    _line(canvas, Offset(w * .14, h * .055), Offset(w * .38, h * .055),
        _light, _urgent ? .58 + _pulse * .22 : .23, 1, glow: _urgent ? 4 : 0);
    _line(canvas, Offset(w * .62, h * .945), Offset(w * .86, h * .945),
        _accent, _urgent ? .48 + _pulse * .2 : .18, .8);

    if (_eclipse) {
      // Lockdown uses opposing, broken arcs rather than the normal lock-screen crescent.
      final r = (math.min(w, h) * .035).clamp(9.0, 18.0).toDouble();
      _arc(canvas, Rect.fromCircle(center: Offset(w * .13, h * .12), radius: r),
          -math.pi * .2, math.pi * .62, _light, alertStrength, 1.1, glow: _urgent ? 4 : 0);
      _arc(canvas, Rect.fromCircle(center: Offset(w * .87, h * .88), radius: r),
          math.pi * .8, math.pi * .62, _light, alertStrength, 1.1, glow: _urgent ? 4 : 0);
    } else {
      final center = Offset(w * .87, h * .13);
      for (var i = 0; i < 3; i++) {
        final x = center.dx - i * 6.0;
        _line(canvas, Offset(x, center.dy - 6), Offset(x, center.dy + 6),
            _light, alertStrength * (1 - i * .18), i == 0 ? 1.1 : .7);
      }
      _line(canvas, Offset(w * .13, h * .87), Offset(w * .23, h * .77),
          _light, alertStrength, 1, glow: _urgent ? 3 : 0);
    }
    final movingX = w * (.16 + .68 * progress);
    _dot(canvas, Offset(movingX, inset), _light, _urgent ? 1.8 : 1.1, glow: _urgent ? 5 : 1.5);
  }

  void _paintSecurityInput(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final len = math.min(w, h) * .22;
    final inset = 2.0;
    final emphasis = switch (state) {
      NebulaComponentSurfaceState.focused => .84,
      NebulaComponentSurfaceState.warning => .9,
      NebulaComponentSurfaceState.selected => .68,
      NebulaComponentSurfaceState.success => .72,
      NebulaComponentSurfaceState.disabled => .18,
      NebulaComponentSurfaceState.idle => .34,
    };
    final corners = Path()
      ..moveTo(inset, inset + len)..lineTo(inset, inset)..lineTo(inset + len, inset)
      ..moveTo(w - inset - len, inset)..lineTo(w - inset, inset)..lineTo(w - inset, inset + len)
      ..moveTo(inset, h - inset - len)..lineTo(inset, h - inset)..lineTo(inset + len, h - inset)
      ..moveTo(w - inset - len, h - inset)..lineTo(w - inset, h - inset)..lineTo(w - inset, h - inset - len);
    _path(canvas, corners, _light, emphasis, 1, glow: _active ? 4 : 0);
    final x = w * (.1 + .8 * progress);
    _line(canvas, Offset(x - 9, inset + .5), Offset(x + 9, inset + .5),
        _light, emphasis, 1.25, glow: _active ? 4 : 1.5);
    if (_hermetic) {
      for (var i = 0; i < 3; i++) {
        final tickH = h * (.12 + i * .025);
        _line(canvas, Offset(w * .045 + i * 4, h * .5 - tickH / 2),
            Offset(w * .045 + i * 4, h * .5 + tickH / 2), _accent, emphasis * .7, .8);
      }
    } else {
      final r = (h * .16).clamp(3.0, 8.0).toDouble();
      _arc(canvas, Rect.fromCircle(center: Offset(w * .96, h * .5), radius: r),
          -math.pi * .5 + progress * math.pi, math.pi, _light, emphasis, .9);
    }
  }

  void _line(Canvas canvas, Offset a, Offset b, Color color, double opacity, double width, {double glow = 0}) {
    if (glow > 0) {
      canvas.drawLine(
        a,
        b,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width + glow * .45
          ..color = color.withValues(alpha: (color.a * opacity * .22).clamp(0.0, 1.0).toDouble())
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow),
      );
    }
    canvas.drawLine(
      a,
      b,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width
        ..color = color.withValues(alpha: (color.a * opacity).clamp(0.0, 1.0).toDouble()),
    );
  }

  void _path(Canvas canvas, Path path, Color color, double opacity, double width, {double glow = 0}) {
    if (glow > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = width + glow * .45
          ..color = color.withValues(alpha: (color.a * opacity * .22).clamp(0.0, 1.0).toDouble())
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = width
        ..color = color.withValues(alpha: (color.a * opacity).clamp(0.0, 1.0).toDouble()),
    );
  }

  void _arc(Canvas canvas, Rect rect, double start, double sweep, Color color,
      double opacity, double width, {double glow = 0}) {
    if (glow > 0) {
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width + glow * .45
          ..color = color.withValues(alpha: (color.a * opacity * .22).clamp(0.0, 1.0).toDouble())
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow),
      );
    }
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width
        ..color = color.withValues(alpha: (color.a * opacity).clamp(0.0, 1.0).toDouble()),
    );
  }

  void _dot(Canvas canvas, Offset center, Color color, double radius, {double glow = 0}) {
    if (glow > 0) {
      canvas.drawCircle(center, radius + glow * .45,
          Paint()..color = color.withValues(alpha: (color.a * .22).clamp(0.0, 1.0).toDouble())
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow));
    }
    canvas.drawCircle(center, radius, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _NebulaComponentSurfacePainter oldDelegate) =>
      oldDelegate.style.material != style.material ||
      oldDelegate.role != role ||
      oldDelegate.state != state ||
      oldDelegate.progress != progress ||
      oldDelegate.alertColor != alertColor ||
      oldDelegate.focalPosition != focalPosition ||
      oldDelegate.borderRadius != borderRadius;
}
