import 'dart:math' as math;

import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/nebula/nebula_tokens.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';

/// Visual state of Fail-Safe's own character, deliberately separate from Aves-X's app mark.
enum FailsafeSpriteMood {
  idle,
  suspicious,
  alert,
  lockdown,
}

/// A compact, front-facing sentinel bat. It uses Nebula security tokens and contains no
/// authentication or security policy; [speaking] only adds a restrained mouth movement/quiver.
class FailsafeSprite extends StatefulWidget {
  final double size;
  final FailsafeSpriteMood mood;
  final bool speaking;
  final String? semanticLabel;

  const FailsafeSprite({
    super.key,
    this.size = 28,
    this.mood = FailsafeSpriteMood.idle,
    this.speaking = false,
    this.semanticLabel,
  });

  @override
  State<FailsafeSprite> createState() => _FailsafeSpriteState();
}

class _FailsafeSpriteState extends State<FailsafeSprite> with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
  );
  bool _motionEnabled = false;

  @override
  void initState() {
    super.initState();
    settings.addListener(_onSettingsChanged);
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant FailsafeSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speaking != widget.speaking) _syncMotion();
  }

  void _onSettingsChanged() {
    final shouldAnimate = settings.animate;
    if (shouldAnimate == _motionEnabled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncMotion();
    });
  }

  void _syncMotion() {
    _motionEnabled = settings.animate; // includes performance/reduced-motion handling
    if (widget.speaking && _motionEnabled) {
      if (!_shake.isAnimating) _shake.repeat(reverse: true);
    } else {
      _shake.stop();
      _shake.value = 0;
    }
  }

  @override
  void dispose() {
    settings.removeListener(_onSettingsChanged);
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).nebula;
    final transition = settings.animate ? const Duration(milliseconds: 180) : Duration.zero;

    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _shake,
          builder: (context, _) {
            // Less than one logical pixel: enough to suggest speech, never a violent shake.
            final talking = widget.speaking && _motionEnabled;
            final dx = talking ? (_shake.value * 2 - 1) * .58 : 0.0;
            final dy = talking ? math.sin(_shake.value * math.pi * 2) * .14 : 0.0;
            return Transform.translate(
              offset: Offset(dx, dy),
              child: AnimatedSwitcher(
                duration: transition,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: .94, end: 1).animate(animation),
                    child: child,
                  ),
                ),
                child: CustomPaint(
                  key: ValueKey(widget.mood),
                  size: Size.square(widget.size),
                  painter: _FailsafeBatPainter(
                    mood: widget.mood,
                    speaking: widget.speaking,
                    tokens: tokens,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FailsafeBatPainter extends CustomPainter {
  final FailsafeSpriteMood mood;
  final bool speaking;
  final NebulaTokens tokens;

  const _FailsafeBatPainter({required this.mood, required this.speaking, required this.tokens});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 72);

    final wingPath = switch (mood) {
      FailsafeSpriteMood.alert => _alertWings(),
      FailsafeSpriteMood.lockdown => _foldedWings(),
      _ => _openWings(),
    };

    // A fine edge and one quiet membrane tone make the silhouette read at small sizes.
    canvas.drawPath(
      wingPath,
      Paint()
        ..color = tokens.securityBubbleGlow.withValues(alpha: .25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
    );
    canvas.drawPath(wingPath, Paint()..color = tokens.securitySurface.withValues(alpha: .98));
    canvas.drawPath(
      wingPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = tokens.securityCrystalEdge.withValues(alpha: .92),
    );

    _drawWingSeams(canvas, tokens.securityAccent.withValues(alpha: mood == FailsafeSpriteMood.lockdown ? .62 : .42));

    // Face: compact ears, a tapered muzzle and expressive eyes; no generic shield or circuitry.
    final face = Path()
      ..moveTo(39, 25)
      ..quadraticBezierTo(50, 19, 61, 25)
      ..lineTo(59, 37)
      ..lineTo(55, 43)
      ..lineTo(50, 47)
      ..lineTo(45, 43)
      ..lineTo(41, 37)
      ..close();
    canvas.drawPath(face, Paint()..color = tokens.securityScrim.withValues(alpha: .62));

    final eyes = (mood == FailsafeSpriteMood.alert || mood == FailsafeSpriteMood.lockdown)
        ? tokens.securityAlert
        : tokens.securityAccent;
    if (mood == FailsafeSpriteMood.suspicious) {
      final brows = Paint()
        ..color = tokens.securityAccent.withValues(alpha: .9)
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(40.5, 32), const Offset(46.5, 34), brows);
      canvas.drawLine(const Offset(53.5, 34), const Offset(59.5, 32), brows);
    }

    final eyeSize = mood == FailsafeSpriteMood.alert || mood == FailsafeSpriteMood.lockdown ? 5.7 : 4.6;
    final eyePaint = Paint()..color = eyes;
    for (final x in [43.7, 56.3]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 35.5), width: eyeSize, height: mood == FailsafeSpriteMood.suspicious ? 2.1 : 2.8),
        eyePaint,
      );
    }

    if (mood == FailsafeSpriteMood.lockdown) {
      // Closed-wing crease: a calm, unmistakable "containment" posture.
      final crease = Path()
        ..moveTo(35, 31)
        ..quadraticBezierTo(42, 41, 50, 45)
        ..quadraticBezierTo(58, 41, 65, 31);
      canvas.drawPath(
        crease,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round
          ..color = tokens.securityAlert.withValues(alpha: .72),
      );
    }

    if (speaking) {
      // A tiny open mouth pairs with the very small horizontal quiver in the widget.
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(50, 41.5), width: 5.4, height: 5.8),
        Paint()..color = tokens.securityAlert.withValues(alpha: .92),
      );
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(50, 40.8), width: 2.1, height: 1.3),
        Paint()..color = tokens.securitySurface,
      );
    } else {
      final nose = Path()
        ..moveTo(47.8, 39.4)
        ..lineTo(52.2, 39.4)
        ..lineTo(50, 42)
        ..close();
      canvas.drawPath(nose, Paint()..color = tokens.securityAccent.withValues(alpha: .88));
    }

    canvas.restore();
  }

  static Path _openWings() => Path()
    ..moveTo(45, 21)
    ..lineTo(37, 5)
    ..lineTo(33, 23)
    ..lineTo(21, 18)
    ..lineTo(8, 24)
    ..lineTo(2, 37)
    ..lineTo(15, 38)
    ..lineTo(10, 47)
    ..lineTo(24, 44)
    ..lineTo(25, 52)
    ..lineTo(39, 48)
    ..lineTo(48, 59)
    ..lineTo(50, 65)
    ..lineTo(52, 59)
    ..lineTo(61, 48)
    ..lineTo(75, 52)
    ..lineTo(76, 44)
    ..lineTo(90, 47)
    ..lineTo(85, 38)
    ..lineTo(98, 37)
    ..lineTo(92, 24)
    ..lineTo(79, 18)
    ..lineTo(67, 23)
    ..lineTo(63, 5)
    ..lineTo(55, 21)
    ..lineTo(50, 25)
    ..close();

  static Path _alertWings() => Path()
    ..moveTo(45, 21)
    ..lineTo(36, 3)
    ..lineTo(31, 23)
    ..lineTo(20, 17)
    ..lineTo(6, 25)
    ..lineTo(2, 39)
    ..lineTo(16, 37)
    ..lineTo(10, 49)
    ..lineTo(26, 43)
    ..lineTo(25, 54)
    ..lineTo(40, 47)
    ..lineTo(48, 59)
    ..lineTo(50, 65)
    ..lineTo(52, 59)
    ..lineTo(60, 47)
    ..lineTo(75, 54)
    ..lineTo(74, 43)
    ..lineTo(90, 49)
    ..lineTo(84, 37)
    ..lineTo(98, 39)
    ..lineTo(94, 25)
    ..lineTo(80, 17)
    ..lineTo(69, 23)
    ..lineTo(64, 3)
    ..lineTo(55, 21)
    ..lineTo(50, 25)
    ..close();

  static Path _foldedWings() => Path()
    ..moveTo(45, 21)
    ..lineTo(37, 5)
    ..lineTo(33, 24)
    ..lineTo(22, 21)
    ..lineTo(10, 29)
    ..lineTo(19, 36)
    ..lineTo(17, 43)
    ..lineTo(29, 45)
    ..lineTo(31, 52)
    ..lineTo(41, 54)
    ..lineTo(48, 60)
    ..lineTo(50, 64)
    ..lineTo(52, 60)
    ..lineTo(59, 54)
    ..lineTo(69, 52)
    ..lineTo(71, 45)
    ..lineTo(83, 43)
    ..lineTo(81, 36)
    ..lineTo(90, 29)
    ..lineTo(78, 21)
    ..lineTo(67, 24)
    ..lineTo(63, 5)
    ..lineTo(55, 21)
    ..lineTo(50, 25)
    ..close();

  static void _drawWingSeams(Canvas canvas, Color color) {
    final seam = Path()
      ..moveTo(44, 28)
      ..quadraticBezierTo(29, 24, 13, 34)
      ..lineTo(25, 37)
      ..lineTo(18, 43)
      ..lineTo(31, 42)
      ..lineTo(31, 48)
      ..lineTo(42, 47);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    canvas.drawPath(seam, paint);
    canvas.save();
    canvas.translate(100, 0);
    canvas.scale(-1, 1);
    canvas.drawPath(seam, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FailsafeBatPainter old) =>
      old.mood != mood || old.speaking != speaking || old.tokens != tokens;
}
