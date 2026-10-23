import 'dart:math' as math;

import 'package:aves/theme/nebula/nebula_material.dart';
import 'package:flutter/material.dart';

/// Surface roles are intentionally component-specific. A theme should feel related
/// across the app without stamping the same central motif onto every rectangle.
enum NebulaComponentSurfaceRole {
  navigationBar,
  drawerHeader,
  drawerItem,
  searchBar,
  appLockBackdrop,
  lockdownBackdrop,
  itemLockBackdrop,
  itemLockCard,
  itemLockBadge,
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
  AnimationController? _controller;

  double get _restingProgress =>
      widget.state == NebulaComponentSurfaceState.warning ? .5 : .28;

  static Duration _duration(NebulaComponentSurfaceRole role, NebulaMaterial? material) {
    // Eclipse follows orbital light; Hermetic moves more like a slow measuring
    // instrument, except for the sharper warning cadence during lockdown.
    if (material == NebulaMaterial.hermetic) {
      return switch (role) {
        NebulaComponentSurfaceRole.navigationBar => const Duration(seconds: 14),
        NebulaComponentSurfaceRole.drawerHeader => const Duration(seconds: 17),
        NebulaComponentSurfaceRole.drawerItem => const Duration(seconds: 11),
        NebulaComponentSurfaceRole.searchBar => const Duration(seconds: 8),
        NebulaComponentSurfaceRole.appLockBackdrop => const Duration(seconds: 20),
        NebulaComponentSurfaceRole.lockdownBackdrop => const Duration(milliseconds: 3800),
        NebulaComponentSurfaceRole.itemLockBackdrop => const Duration(seconds: 24),
        NebulaComponentSurfaceRole.itemLockCard => const Duration(seconds: 18),
        NebulaComponentSurfaceRole.itemLockBadge => const Duration(seconds: 11),
        NebulaComponentSurfaceRole.appLockCard => const Duration(seconds: 16),
        NebulaComponentSurfaceRole.lockdownCard => const Duration(milliseconds: 3200),
        NebulaComponentSurfaceRole.securityInput => const Duration(milliseconds: 4200),
      };
    }
    return switch (role) {
      NebulaComponentSurfaceRole.navigationBar => const Duration(seconds: 9),
      NebulaComponentSurfaceRole.drawerHeader => const Duration(seconds: 13),
      NebulaComponentSurfaceRole.drawerItem => const Duration(seconds: 7),
      NebulaComponentSurfaceRole.searchBar => const Duration(seconds: 5),
      NebulaComponentSurfaceRole.appLockBackdrop => const Duration(seconds: 12),
      NebulaComponentSurfaceRole.lockdownBackdrop => const Duration(seconds: 5),
      NebulaComponentSurfaceRole.itemLockBackdrop => const Duration(seconds: 15),
      NebulaComponentSurfaceRole.itemLockCard => const Duration(seconds: 8),
      NebulaComponentSurfaceRole.itemLockBadge => const Duration(seconds: 6),
      NebulaComponentSurfaceRole.appLockCard => const Duration(seconds: 9),
      NebulaComponentSurfaceRole.lockdownCard => const Duration(seconds: 4),
      NebulaComponentSurfaceRole.securityInput => const Duration(seconds: 3),
    };
  }

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
    final materialChanged = oldWidget.style?.material != widget.style?.material;
    if (oldWidget.role != widget.role || materialChanged) {
      final controller = _controller;
      if (controller != null) {
        controller.stop();
        controller.duration = _duration(widget.role, widget.style?.material);
        controller.value = _restingProgress;
      }
    }
    _syncAnimation();
  }

  void _syncAnimation() {
    final shouldAnimate = _supported &&
        widget.animate &&
        widget.state != NebulaComponentSurfaceState.disabled;
    final current = _controller;

    if (!shouldAnimate) {
      if (current != null && current.isAnimating) {
        current.stop();
        current.value = _restingProgress;
      }
      return;
    }

    final controller = current ?? AnimationController(
      vsync: this,
      duration: _duration(widget.role, widget.style?.material),
      value: _restingProgress,
    );
    _controller = controller;
    if (!controller.isAnimating) controller.repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Non-target themes and idle components with motion disabled do not allocate
    // a ticker. Their vector treatment still renders at a stable resting phase.
    if (!_supported) return widget.child;

    CustomPaint paintAt(double progress) => CustomPaint(
      painter: _NebulaComponentSurfacePainter(
        style: widget.style!,
        role: widget.role,
        state: widget.state,
        progress: progress,
        alertColor: widget.alertColor,
        focalPosition: (widget.focalPosition ?? .5).clamp(0.0, 1.0).toDouble(),
        borderRadius: widget.borderRadius,
      ),
    );

    final controller = _controller;
    final paintLayer = controller == null
        ? paintAt(_restingProgress)
        : AnimatedBuilder(
            animation: controller,
            builder: (context, _) => paintAt(controller.value),
          );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(child: RepaintBoundary(child: paintLayer)),
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
      case NebulaComponentSurfaceRole.drawerItem:
        _paintDrawerItem(canvas, size);
      case NebulaComponentSurfaceRole.searchBar:
        _paintSearchBar(canvas, size);
      case NebulaComponentSurfaceRole.appLockBackdrop:
        _paintAppLockBackdrop(canvas, size);
      case NebulaComponentSurfaceRole.lockdownBackdrop:
        _paintLockdownBackdrop(canvas, size);
      case NebulaComponentSurfaceRole.itemLockBackdrop:
        _paintItemLockBackdrop(canvas, size);
      case NebulaComponentSurfaceRole.itemLockCard:
        _paintItemLockCard(canvas, size);
      case NebulaComponentSurfaceRole.itemLockBadge:
        _paintItemLockBadge(canvas, size);
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
    // Motion stays anchored to the selected destination: Eclipse breathes at the
    // terminator, while Hermetic raises and lowers a calibrated index. No global
    // left-to-right light sweep is shared between components.
    final lowerY = h * .94;
    final pulse = .5 + .5 * math.sin(progress * math.pi * 2);
    if (_eclipse) {
      _dot(canvas, Offset(x, lowerY), _light, 1.0 + pulse * .55,
          glow: 2.0 + pulse * 2.0);
    } else {
      _line(canvas, Offset(x - r * .62, lowerY), Offset(x + r * .62, lowerY),
          _light, .2 + pulse * .48, .8, glow: pulse * 2.2);
      _dot(canvas, Offset(x, lowerY), _light, .8 + pulse * .55,
          glow: 1.0 + pulse * 2.0);
    }
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
      final pulse = .5 + .5 * math.sin(progress * math.pi * 2);
      for (var i = 0; i < 3; i++) {
        final r2 = r * (.35 + i * .23);
        final path = Path()
          ..moveTo(center.dx, center.dy - r2)
          ..lineTo(center.dx + r2 * .78, center.dy + r2 * .48)
          ..lineTo(center.dx - r2 * .78, center.dy + r2 * .48)
          ..close();
        final strength = i == 1 ? .3 + pulse * .3 : .14 + pulse * .1;
        _path(canvas, path, i == 1 ? _light : ink, strength, .8 + (i == 1 ? pulse * .25 : 0));
      }
      for (var i = 0; i < 5; i++) {
        final x = w * .72 + i * w * .045;
        final active = i == (progress * 5).floor().clamp(0, 4);
        _line(canvas, Offset(x, h * .8), Offset(x, h * (.8 - (i.isEven ? .08 : .04))),
            _light, active ? .78 : .2 + pulse * .12, active ? 1.1 : .7,
            glow: active ? 3 : 0);
      }
      _dot(canvas, Offset(center.dx, center.dy - r * .32), _light,
          .8 + pulse * .8, glow: 1.5 + pulse * 2.0);
    }
  }

  void _paintDrawerItem(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final pulse = .5 + .5 * math.sin(progress * math.pi * 2);
    final selected = state == NebulaComponentSurfaceState.selected ||
        state == NebulaComponentSurfaceState.focused ||
        state == NebulaComponentSurfaceState.warning;
    if (_eclipse) {
      // A selected route is caught by an incomplete orbital rim on its leading
      // edge. Idle rows only have a quiet terminator so the drawer stays calm.
      final r = (h * .24).clamp(5.0, 14.0).toDouble();
      final center = Offset(r * .55, h * .5);
      if (selected) {
        final start = -math.pi * .82 + progress * .055;
        _arc(canvas, Rect.fromCircle(center: center, radius: r), start,
            math.pi * 1.42, _light, .48 + pulse * .32, 1.1, glow: 2 + pulse * 2.5);
        final a = start + math.pi * 1.42;
        _dot(canvas, center + Offset(math.cos(a) * r, math.sin(a) * r),
            _light, 1.1 + pulse * .45, glow: 2 + pulse * 2.2);
      } else {
        _line(canvas, Offset(2, h * .3), Offset(2, h * .7), _accent, .16 + pulse * .1, .8);
      }
      _line(canvas, Offset(w * .16, h * .92), Offset(w * .16 + (selected ? w * .18 : w * .06), h * .92),
          _accent, selected ? .26 + pulse * .16 : .1, .7);
    } else {
      // Hermetic is a measured row index: the active entry closes a tiny
      // registration diamond, while the remaining rows keep spaced ticks.
      final x = w * .035;
      for (var i = 0; i < 3; i++) {
        final tickY = h * (.32 + i * .18);
        final activeTick = selected && i == 1;
        _line(canvas, Offset(x, tickY), Offset(x + (activeTick ? 7 : 4), tickY),
            _light, activeTick ? .6 + pulse * .3 : .16 + pulse * .08,
            activeTick ? 1.1 : .7, glow: activeTick ? 2 + pulse * 2 : 0);
      }
      if (selected) {
        // Reinforce the leading registration rail rather than placing an emblem
        // beneath trailing actions/icons at the opposite edge of the row.
        final y = h * .5;
        _line(canvas, Offset(x + 1, y), Offset(x + 7 + pulse * 2, y),
            _light, .46 + pulse * .34, 1.0, glow: 1.5 + pulse * 2);
      }
      _line(canvas, Offset(w * .12, h * .93), Offset(w * (selected ? .32 : .2), h * .93),
          _accent, selected ? .22 + pulse * .15 : .08, .7);
    }
  }

  void _paintSearchBar(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final emphasis = _active ? .72 + .2 * _pulse : .3;
    _line(canvas, Offset(w * .035, h * .08), Offset(w * .965, h * .08), _accent, .2, .7);
    _line(canvas, Offset(w * .08, h * .94), Offset(w * .92, h * .94), _accent, _active ? .34 : .16, .8);
    if (_eclipse) {
      // Search gets its own scan at the upper edge plus an orbiting terminator;
      // this cadence is intentionally different from the navigation indicator.
      final scanX = w * (.08 + .84 * progress);
      _line(canvas, Offset(scanX - w * .045, h * .1), Offset(scanX + w * .045, h * .1),
          _light, emphasis, 1.4, glow: _active ? 4.5 : 2);
      _dot(canvas, Offset(scanX, h * .1), _light, _active ? 1.8 : 1.1,
          glow: _active ? 5 : 2);
      final center = Offset(w * .94, h * .49);
      final r = (h * .25).clamp(5.0, 14.0).toDouble();
      _arc(canvas, Rect.fromCircle(center: center, radius: r),
          -math.pi * .78, math.pi * 1.38, _light, _active ? .86 : .42, 1.1,
          glow: _active ? 4 : 0);
      final angle = -math.pi * .78 + progress * math.pi * 1.38;
      _dot(canvas, center + Offset(math.cos(angle) * r, math.sin(angle) * r),
          _light, 1.3, glow: 3);
    } else {
      // Hermetic is a calibrated instrument: its index breathes vertically and
      // the diamond has a rotating elliptical reticle, not a horizontal sweep.
      final x0 = w * .055;
      final pulse = .5 + .5 * math.sin(progress * math.pi * 2);
      for (var i = 0; i < 4; i++) {
        final x = x0 + i * 5.0;
        _line(canvas, Offset(x, h * .36), Offset(x, h * .63), _light,
            .18 + pulse * (i == 3 ? .42 : .2), .75);
      }
      final x = w * .94;
      final y = h * (.5 + math.sin(progress * math.pi * 2) * .035);
      final reticle = Rect.fromCenter(
        center: Offset(x, y),
        width: 8 + pulse * 5,
        height: 6 + pulse * 3,
      );
      _arc(canvas, reticle, progress * math.pi * .22, math.pi * 1.42,
          _light, (_active ? .58 : .28) + pulse * .25, .8, glow: 1.2 + pulse * 2);
      final diamond = Path()
        ..moveTo(x, y - 4 - pulse * 1.2)
        ..lineTo(x + 4 + pulse, y)
        ..lineTo(x, y + 4 + pulse * 1.2)
        ..lineTo(x - 4 - pulse, y)
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
    if (_eclipse) {
      // The lockdown marker follows the upper-left interrupted arc, not the full frame.
      final a = -math.pi * .25 + progress * math.pi * .56;
      final p = Offset(w * .12, h * .13) + Offset(math.cos(a) * (m * .065), math.sin(a) * (m * .065));
      _dot(canvas, p, _light, _urgent ? 1.7 : 1.0, glow: _urgent ? 5 : 1.5);
    } else {
      // Hermetic's warning energy breathes at the calibration origin.
      final y = h * .13;
      _dot(canvas, Offset(w * .89, y),
          _light, 1.0 + pulse * (_urgent ? 1.1 : .35),
          glow: _urgent ? 2.5 + pulse * 3.0 : 1.0 + pulse);
    }
  }

  void _paintItemLockBackdrop(Canvas canvas, Size size) {
    final w = size.width, h = size.height, m = math.min(size.width, size.height);
    final pulse = .5 + .5 * math.sin(progress * math.pi * 2);
    if (_eclipse) {
      // The item-lock screen evokes an eclipse in deep space: an oblique orbital
      // sweep sits off-centre so the card owns the foreground.
      final center = Offset(w * .16, h * .74);
      for (var i = 0; i < 3; i++) {
        final r = m * (.11 + i * .055);
        final rect = Rect.fromCenter(center: center, width: r * 2.7, height: r * 1.15);
        _arc(canvas, rect, math.pi * (.12 + i * .18) + progress * .035,
            math.pi * (1.05 + i * .12), _accent, .12 + pulse * .08, .8 + i * .15,
            glow: i == 1 ? 3.5 : 0);
      }
      final a = math.pi * .12 + progress * math.pi * 1.05;
      final r = m * .165;
      _dot(canvas, center + Offset(math.cos(a) * r * 1.35, math.sin(a) * r * .58),
          _light, 1.1 + pulse * .5, glow: 2 + pulse * 2.2);
      _line(canvas, Offset(w * .72, h * .12), Offset(w * .92, h * .12),
          _light, .14 + pulse * .1, .8);
    } else {
      // Hermetic uses a field diagram around the edge: measured rails and an
      // off-centre orbit, leaving the lock emblem and copy unobscured.
      final x = w * .91;
      _line(canvas, Offset(x, h * .11), Offset(x, h * .34),
          _accent, .18 + pulse * .08, .8);
      for (var i = 0; i < 4; i++) {
        final y = h * (.15 + i * .055);
        _line(canvas, Offset(x - m * .055, y), Offset(x, y),
            _light, .2 + pulse * (i == 2 ? .32 : .08), i == 2 ? 1.1 : .7,
            glow: i == 2 ? 2 + pulse * 2 : 0);
      }
      final center = Offset(w * .09, h * .86);
      for (var i = 0; i < 3; i++) {
        final r = m * (.025 + i * .014);
        _arc(canvas, Rect.fromCenter(center: center, width: r * 2.2, height: r * 1.5),
            progress * .11 + i * .8, math.pi * 1.28,
            i == 1 ? _light : _accent, .13 + pulse * .08, .8);
      }
    }
  }

  void _paintItemLockCard(Canvas canvas, Size size) {
    final w = size.width, h = size.height, m = math.min(size.width, size.height);
    final pulse = .5 + .5 * math.sin(progress * math.pi * 2);
    if (_eclipse) {
      final r = m * .14;
      final center = Offset(w * .87, h * .1);
      _arc(canvas, Rect.fromCircle(center: center, radius: r),
          -math.pi * .78 + progress * .09, math.pi * 1.28,
          _light, .22 + pulse * .15, 1.1, glow: 2 + pulse * 2);
      final lower = Path()
        ..moveTo(w * .07, h * .82)
        ..quadraticBezierTo(w * .28, h * .9, w * .47, h * .84)
        ..quadraticBezierTo(w * .68, h * .77, w * .9, h * .83);
      _path(canvas, lower, _accent, .15 + pulse * .08, .7);
      _dot(canvas, center + Offset(math.cos(progress * math.pi * 1.28 - math.pi * .78) * r,
          math.sin(progress * math.pi * 1.28 - math.pi * .78) * r),
          _light, 1.2 + pulse * .4, glow: 2 + pulse * 2);
    } else {
      // Bevelled registration marks rather than an ornamental border around the card.
      final cut = m * .06;
      final frame = Path()
        ..moveTo(0, cut)..lineTo(0, 0)..lineTo(cut, 0)
        ..moveTo(w - cut, 0)..lineTo(w, 0)..lineTo(w, cut)
        ..moveTo(0, h - cut)..lineTo(0, h)..lineTo(cut, h)
        ..moveTo(w - cut, h)..lineTo(w, h)..lineTo(w, h - cut);
      _path(canvas, frame, _light, .32 + pulse * .22, .9);
      final x = w * .92, y = h * .5, r = m * .035;
      _line(canvas, Offset(x, y - r), Offset(x, y + r), _accent, .24 + pulse * .16, .8);
      _line(canvas, Offset(x - r, y), Offset(x + r, y), _accent, .24 + pulse * .16, .8);
      _dot(canvas, Offset(x, y), _light, .8 + pulse * .5, glow: 1.2 + pulse * 2);
    }
  }

  void _paintItemLockBadge(Canvas canvas, Size size) {
    final center = Offset(size.width * .5, size.height * .5);
    final m = math.min(size.width, size.height);
    final pulse = .5 + .5 * math.sin(progress * math.pi * 2);
    if (_eclipse) {
      final r = m * .39;
      _arc(canvas, Rect.fromCircle(center: center, radius: r),
          -math.pi * .72 + progress * .12, math.pi * 1.14,
          _light, .34 + pulse * .32, 1.1, glow: 2.5 + pulse * 2.5);
      final a = -math.pi * .72 + progress * math.pi * 1.14;
      _dot(canvas, center + Offset(math.cos(a) * r, math.sin(a) * r),
          _light, 1.4 + pulse * .4, glow: 3.5 + pulse * 2);
    } else {
      final r = m * .37;
      for (var i = 0; i < 12; i++) {
        final a = i * math.pi / 6;
        final major = i % 3 == 0;
        final inner = r * (major ? .82 : .9);
        final outer = r * (major ? 1.08 : 1.0);
        final active = i == (progress * 12).floor() % 12;
        _line(canvas,
            center + Offset(math.cos(a) * inner, math.sin(a) * inner),
            center + Offset(math.cos(a) * outer, math.sin(a) * outer),
            _light, active ? .8 : .16 + pulse * .12,
            active ? 1.2 : (major ? .9 : .6),
            glow: active ? 2.5 + pulse * 2 : 0);
      }
      _arc(canvas, Rect.fromCircle(center: center, radius: r * (.48 + pulse * .025)),
          progress * math.pi * .1, math.pi * 1.35, _accent, .2 + pulse * .12, .8);
    }
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
    if (_eclipse) {
      final a = -math.pi * .2 + progress * math.pi * .62;
      final r = (math.min(w, h) * .035).clamp(9.0, 18.0).toDouble();
      _dot(canvas, Offset(w * .13, h * .12) + Offset(math.cos(a) * r, math.sin(a) * r),
          _light, _urgent ? 1.8 : 1.1, glow: _urgent ? 5 : 1.5);
    } else {
      final breath = .5 + .5 * math.sin(progress * math.pi * 2);
      final x = w * .87, y = h * .13;
      _line(canvas, Offset(x, y - 4 - breath * 2),
          Offset(x, y + 4 + breath * 2), _light,
          _urgent ? .62 + breath * .3 : .26 + breath * .22,
          _urgent ? 1.2 : .8, glow: _urgent ? 3 + breath * 2 : 0);
    }
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
    final pulse = .5 + .5 * math.sin(progress * math.pi * 2);
    if (_hermetic) {
      // Mechanical field-lock: paired end stops tighten/relax in place, with
      // different intensity at each side so this never reads as a swept streak.
      for (var i = 0; i < 3; i++) {
        final tickH = h * (.12 + i * .025 + pulse * .025);
        final a = emphasis * (.42 + pulse * .5) * (i == 1 ? 1 : .72);
        _line(canvas, Offset(w * .045 + i * 4, h * .5 - tickH / 2),
            Offset(w * .045 + i * 4, h * .5 + tickH / 2), _accent, a, .8);
        _line(canvas, Offset(w * (.955 - i * .012), h * .5 - tickH / 2),
            Offset(w * (.955 - i * .012), h * .5 + tickH / 2), _light, a, .8);
      }
      _line(canvas, Offset(w * .25, inset + .5), Offset(w * .38, inset + .5),
          _light, emphasis * (.25 + pulse * .65), .9, glow: _active ? 2 + pulse * 2 : 0);
    } else {
      // Eclipse's short reflection travels along a curved edge, rather than across
      // the field. The incomplete arc doubles as the component's lock indicator.
      final r = (h * .16).clamp(3.0, 8.0).toDouble();
      final center = Offset(w * .96, h * .5);
      _arc(canvas, Rect.fromCircle(center: center, radius: r),
          -math.pi * .5 + progress * math.pi, math.pi, _light, emphasis, .9);
      final a = -math.pi * .5 + progress * math.pi;
      _dot(canvas, center + Offset(math.cos(a) * r, math.sin(a) * r),
          _light, .8 + pulse * .6, glow: _active ? 2 + pulse * 2 : 0);
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
