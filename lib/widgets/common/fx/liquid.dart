import 'dart:async';
import 'dart:math';

import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/themes.dart';
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
  final _random = Random();
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
    final span = widget.maxPauseMillis - widget.minPauseMillis;
    final pause = (first ? 0 : widget.minPauseMillis) + _random.nextInt(first ? widget.maxPauseMillis : span);
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

// "Bat-Glass": icons get a liquid highlight flowing inside them from time to time.
// No-op without Bat-Glass, or when animations are disabled (e.g. performance mode).
class LiquidIcon extends StatelessWidget {
  final Widget child;

  const LiquidIcon({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final enabled = settings.batGlass && settings.animate;
    if (!enabled) return child;

    final base = IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    final highlight = Color.lerp(base, const Color(0xFFFF8A9B), .9)!.withValues(alpha: base.a);
    final deep = Color.lerp(base, Themes.batGlassRuby, .35)!.withValues(alpha: base.a);
    return RandomBurst(
      enabled: true,
      child: child,
      builder: (context, t, child) => ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [deep, highlight, base, deep],
          stops: const [0, .35, .65, 1],
          tileMode: TileMode.repeated,
          transform: _LiquidSlide(t),
        ).createShader(bounds),
        child: child,
      ),
    );
  }
}

class _LiquidSlide extends GradientTransform {
  final double t;

  const _LiquidSlide(this.t);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // slide diagonally by one full period, with a slight vertical wobble
    final wobble = (t * 2 - 1).abs() * bounds.height * .15;
    return Matrix4.translationValues(bounds.width * (t * 2 - 1), bounds.height * (t * 2 - 1) * .6 + wobble, 0);
  }
}

// Glass look for selectable controls (switches, tiles, checkboxes) when
// "Glass everywhere" or "Bat-Glass" is on.
class GlassThemeScope extends StatelessWidget {
  final Widget? child;

  const GlassThemeScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final child = this.child ?? const SizedBox();
        if (!(settings.glassEverywhere || settings.batGlass)) return child;

        final theme = Theme.of(context);
        final bat = settings.batGlass;
        final isDark = theme.brightness == Brightness.dark;
        final accent = bat ? Themes.batGlassRuby : theme.colorScheme.primary;
        final edge = bat ? const Color(0x80FF3B5C) : (isDark ? const Color(0x55FFFFFF) : const Color(0x55000000));
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
          ),
          child: child,
        );
      },
    );
  }
}
