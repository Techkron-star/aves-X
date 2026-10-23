import 'dart:async';
import 'dart:math' as math;

import 'package:aves/model/settings/settings.dart';
import 'package:material_ui/material_ui.dart';

// Plays `builder` in short bursts at random moments, and shows the plain `child` the rest of the time.
// Every instance has its own random timing, so that effects never run all at once:
// this keeps the cost low even with many icons or badges on screen.
class RandomBurst extends StatefulWidget {
  final bool enabled;
  final Duration duration;
  final int minPauseMillis, maxPauseMillis;
  final Widget child;
  final Widget Function(BuildContext context, double t, Widget child) builder;

  const RandomBurst({
    super.key,
    required this.enabled,
    this.duration = const Duration(milliseconds: 1400),
    this.minPauseMillis = 2500,
    this.maxPauseMillis = 9000,
    required this.child,
    required this.builder,
  });

  @override
  State<RandomBurst> createState() => _RandomBurstState();
}

class _RandomBurstState extends State<RandomBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration);
  final _random = math.Random();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.value = 0;
        _schedule();
      }
    });
    if (widget.enabled) _schedule(first: true);
  }

  void _schedule({bool first = false}) {
    _timer?.cancel();
    final minPause = widget.minPauseMillis < 0 ? 0 : widget.minPauseMillis;
    final maxPause = widget.maxPauseMillis < minPause ? minPause : widget.maxPauseMillis;
    final span = maxPause - minPause;
    final pause = first
        ? (maxPause == 0 ? 0 : _random.nextInt(maxPause + 1))
        : (span == 0 ? minPause : minPause + _random.nextInt(span + 1));
    _timer = Timer(Duration(milliseconds: pause), () {
      if (mounted && widget.enabled) _controller.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(covariant RandomBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) _schedule(first: true);
    if (!widget.enabled) {
      _timer?.cancel();
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        // idle: no shader, no extra layer
        if (!_controller.isAnimating) return child!;
        return widget.builder(context, _controller.value, child!);
      },
    );
  }
}

// Nebula glass themes: icons get a liquid highlight flowing inside them from time to time
// (ruby for Nosferatu Glass, purple hellfire for Night Demon, pale gold for Godly).
// No-op without a glass theme, or when animations are disabled (e.g. performance mode).
class LiquidIcon extends StatelessWidget {
  final Widget child;

  const LiquidIcon({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final material = settings.materialStyle;
    if (material == null || !settings.animate) return child;

    final base = IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    final highlight = Color.lerp(base, material.liquidHighlight, .9)!.withValues(alpha: base.a);
    final deep = Color.lerp(base, material.liquidDeep, .35)!.withValues(alpha: base.a);
    return RandomBurst(
      enabled: true,
      child: child,
      builder: (context, t, child) {
        // Ease the shimmer in/out. The ends stay on the base colour so no tint is cut at glyph edges.
        // A non-repeating gradient avoids a visible seam when its moving band crosses an icon.
        final envelope = math.pow(math.sin(math.pi * t), 1.35).toDouble();
        if (envelope < .008) return child;
        final d = Color.lerp(base, deep, envelope * .72)!;
        final h = Color.lerp(base, highlight, envelope)!;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [base, d, h, base, d, base],
            stops: const [0, .19, .38, .62, .82, 1],
            transform: _LiquidSlide(t),
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

class _LiquidSlide extends GradientTransform {
  final double t;

  const _LiquidSlide(this.t);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Move on a stable, eased diagonal. The non-repeating colour caps soften each pass.
    final eased = Curves.easeInOutCubic.transform(t);
    final x = bounds.width * (eased * 1.5 - .75);
    final y = bounds.height * (eased * .6 - .3);
    return Matrix4.translationValues(x, y, 0);
  }
}

// Glass look for selectable controls (switches, tiles, checkboxes) when
// "Glass everywhere" or a Nebula glass theme is on.
class GlassThemeScope extends StatelessWidget {
  final Widget? child;

  const GlassThemeScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final child = this.child ?? const SizedBox();
        final theme = Theme.of(context);
        // same tree shape whether the glass is on or not: otherwise toggling it remounts the whole app below
        final material = settings.materialStyle;
        if (!(settings.glassEverywhere || material != null)) return Theme(data: theme, child: child);

        final isDark = theme.brightness == Brightness.dark;
        final accent = material?.accent ?? theme.colorScheme.primary;
        final edge = material?.edge ?? (isDark ? const Color(0x55FFFFFF) : const Color(0x55000000));
        final surface = material?.surface ?? theme.colorScheme.surfaceContainerHigh;
        // every material has its own silhouette: faceted ruby, cut obsidian, soft gold
        final ShapeBorder Function(double, BorderSide) shape = material != null
            ? material.shape
            : (radius, side) => RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: side);
        final ShapeBorder Function(double, BorderSide) topShape = material != null
            ? material.topShape
            : (radius, side) => RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius)), side: side);
        final rim = BorderSide(color: edge, width: .8);
        final tint = isDark ? const Color(0x12FFFFFF) : const Color(0x0C000000);
        return Theme(
          data: theme.copyWith(
            switchTheme: SwitchThemeData(
              trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accent.withValues(alpha: .55) : tint),
              trackOutlineColor: WidgetStateProperty.all(edge),
              thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.white.withValues(alpha: .92) : edge),
            ),
            checkboxTheme: CheckboxThemeData(
              fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accent.withValues(alpha: .7) : tint),
              side: BorderSide(color: edge, width: 1.4),
            ),
            radioTheme: RadioThemeData(
              fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accent : edge),
            ),
            listTileTheme: theme.listTileTheme.copyWith(
              selectedTileColor: accent.withValues(alpha: .18),
            ),
            // Glass-Everywhere 2.0: every floating surface becomes translucent glass with a bright edge
            // (menus, sheets, snack bars, cards, drawer); the Nebula glass themes tint them smoked ruby, black violet or dark gold
            // `copyWith` keeps the label text style and icon color of the base theme (the menu panels rely on them)
            popupMenuTheme: theme.popupMenuTheme.copyWith(
              color: surface.withValues(alpha: .74),
              surfaceTintColor: Colors.transparent,
              shape: shape(18, rim),
            ),
            bottomSheetTheme: theme.bottomSheetTheme.copyWith(
              backgroundColor: surface.withValues(alpha: .78),
              modalBackgroundColor: surface.withValues(alpha: .78),
              surfaceTintColor: Colors.transparent,
              shape: topShape(24, rim),
            ),
            snackBarTheme: theme.snackBarTheme.copyWith(
              backgroundColor: surface.withValues(alpha: .86),
              behavior: SnackBarBehavior.floating,
              shape: shape(16, rim),
            ),
            cardTheme: theme.cardTheme.copyWith(
              color: surface.withValues(alpha: .6),
              surfaceTintColor: Colors.transparent,
              shape: shape(16, rim),
            ),
            drawerTheme: theme.drawerTheme.copyWith(
              backgroundColor: surface.withValues(alpha: .8),
              surfaceTintColor: Colors.transparent,
            ),
          ),
          child: child,
        );
      },
    );
  }
}
