import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/nebula/nebula_theme.dart';
import 'package:aves/theme/nebula/nebula_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

// Translucent bat mark: the "bat" of the former Bat-Glass, drawn without a padlock.
// Used by the About screen, the Fail-Safe comic bubble and the lockdown screen.
// The padlock itself is drawn by `_PadlockPainter` in `lock_animation.dart`.

/// Color source of the mark.
enum AppMarkTone {
  /// Follows the active Nebula theme: the fixed ruby identity of Nosferatu Glass,
  /// dynamic Material You colors for every other theme.
  auto,

  /// Fixed crystal identity from the Nebula tokens (ruby by default).
  brand,

  /// Dynamic colors derived from `ColorScheme` (Material You seed).
  scheme,

  /// Single ink color from `IconTheme.of(context).color`, else `onSurface`.
  monochrome,
}

class AppMark extends StatelessWidget {
  final double size;
  final bool mirrored;
  final AppMarkTone tone;

  /// Optional accessibility label. The mark is decorative by default.
  final String? semanticLabel;

  /// Cross-fades the mark when the theme/size changes. `settings.animate`
  /// already includes performance mode and the accessibility setting.
  final bool animate;

  const AppMark({
    super.key,
    this.size = 28,
    this.mirrored = false,
    this.tone = AppMarkTone.auto,
    this.semanticLabel,
    this.animate = true,
  });

  const AppMark.monochrome({super.key, this.size = 28, this.mirrored = false, this.semanticLabel, this.animate = true})
    : tone = AppMarkTone.monochrome;

  const AppMark.brand({super.key, this.size = 28, this.mirrored = false, this.semanticLabel, this.animate = true})
    : tone = AppMarkTone.brand;

  const AppMark.scheme({super.key, this.size = 28, this.mirrored = false, this.semanticLabel, this.animate = true})
    : tone = AppMarkTone.scheme;

  /// `auto` keeps the brand look only for Nosferatu Glass; the other Nebula
  /// themes (and the default theme) get Material You colors.
  AppMarkTone get _effectiveTone =>
      tone != AppMarkTone.auto ? tone : (settings.effectiveNebulaTheme == NebulaTheme.nosferatuGlass ? AppMarkTone.brand : AppMarkTone.scheme);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).nebula;
    final iconColor = IconTheme.of(context).color;
    final effectiveTone = _effectiveTone;

    final List<Color> gradient;
    final Color? stroke;
    switch (effectiveTone) {
      case AppMarkTone.brand:
        // fixed ruby/black identity, exactly the former Bat-Glass mark
        final body = tokens.securityCrystalBody;
        gradient = [
          tokens.securityAccent.withValues(alpha: .70),
          tokens.securityAccent.withValues(alpha: .60),
          body.length > 2 ? body[2] : tokens.securityAccent,
        ];
        stroke = tokens.securityCrystalEdge;
      case AppMarkTone.scheme:
        // Material You: the seed drives primary/secondary/tertiary
        gradient = [
          colors.primary.withValues(alpha: .85),
          colors.secondary.withValues(alpha: .75),
          colors.tertiary,
        ];
        stroke = colors.primary.withValues(alpha: .55);
      case AppMarkTone.monochrome:
        gradient = <Color>[iconColor ?? colors.onSurface];
        stroke = null;
      case AppMarkTone.auto:
        // resolved by `_effectiveTone`, kept for exhaustiveness
        gradient = <Color>[colors.primary];
        stroke = null;
    }

    final motion = (animate && settings.animate) ? const Duration(milliseconds: 240) : Duration.zero;
    // the key changes only with the look or the size, so plain rebuilds do not
    // restart the switch animation
    final look = '${effectiveTone.name}-$size-${Object.hashAll(gradient)}-${stroke?.hashCode}';

    final Widget mark = SizedBox.square(
      dimension: size,
      child: AnimatedSwitcher(
        duration: motion,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: RotationTransition(
            turns: Tween<double>(begin: -.02, end: 0).animate(animation),
            child: ScaleTransition(
              scale: Tween<double>(begin: .92, end: 1).animate(animation),
              child: child,
            ),
          ),
        ),
        child: SizedBox.square(
          key: ValueKey(look),
          dimension: size,
          child: CustomPaint(
            painter: AppMarkPainter(gradient: gradient, strokeColor: stroke),
            isComplex: true,
            willChange: false,
          ),
        ),
      ),
    );

    return Semantics(
      label: semanticLabel,
      image: true,
      child: Transform.flip(flipX: mirrored, child: mark),
    );
  }
}

// Bat with a keyhole-free silhouette (static: no open/animate state).
// Colors are injected so the mark follows the Nebula theme or Material You.
class AppMarkPainter extends CustomPainter {
  // former Bat-Glass recipe, kept as the default for call sites that still
  // draw the mark without a theme
  static const defaultGradient = <Color>[Color(0xB3FF6A80), Color(0x99C4122F), Color(0xB37A0A1E)];
  static const defaultStroke = Color(0xCCFFB3BF);

  /// Gradient from the top-left facet to the deepest one. A single color draws
  /// a flat, monochrome mark.
  final List<Color> gradient;

  /// Edge color. `null` draws no outline (monochrome tone).
  final Color? strokeColor;

  final double strokeWidth;

  const AppMarkPainter({
    this.gradient = defaultGradient,
    this.strokeColor = defaultStroke,
    this.strokeWidth = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 100;
    canvas.scale(s);
    final path = Path()
      // body and head
      ..moveTo(50, 22)
      ..lineTo(43, 8)
      ..lineTo(41, 26)
      // left wing
      ..cubicTo(26, 20, 8, 28, 2, 48)
      ..quadraticBezierTo(10, 50, 15, 47)
      ..quadraticBezierTo(21, 62, 29, 56)
      ..quadraticBezierTo(33, 72, 42, 64)
      ..lineTo(50, 92)
      // right wing (mirrored)
      ..lineTo(58, 64)
      ..quadraticBezierTo(67, 72, 71, 56)
      ..quadraticBezierTo(79, 62, 85, 47)
      ..quadraticBezierTo(90, 50, 98, 48)
      ..cubicTo(92, 28, 74, 20, 59, 26)
      ..lineTo(57, 8)
      ..close();

    final Paint fill;
    if (gradient.length < 2) {
      fill = Paint()..color = gradient.isEmpty ? const Color(0x00FF6A80) : gradient.first;
    } else {
      fill = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ).createShader(path.getBounds());
    }
    canvas.drawPath(path, fill);

    final stroke = strokeColor;
    if (stroke != null) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeJoin = StrokeJoin.round
          ..color = stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AppMarkPainter old) =>
      old.strokeColor != strokeColor || old.strokeWidth != strokeWidth || !listEquals(old.gradient, gradient);
}
