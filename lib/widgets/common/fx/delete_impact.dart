import 'dart:math' as math;

import 'package:aves/model/security/failsafe_config.dart';
import 'package:aves/widgets/common/fx/black_hole.dart';
import 'package:material_ui/material_ui.dart';

enum DestructiveEffect { trash, erase }

/// Lightweight signature motion for trashing and permanent deletion. This is
/// decoration only: it never changes confirmation delay, input requirements,
/// storage operations, or the security decision.
class DestructiveActionAnimation extends StatefulWidget {
  final DestructiveEffect effect;
  final bool animate;
  final double size;

  const DestructiveActionAnimation({
    super.key,
    required this.effect,
    this.animate = true,
    this.size = 64,
  });

  @override
  State<DestructiveActionAnimation> createState() => _DestructiveActionAnimationState();
}

class _DestructiveActionAnimationState extends State<DestructiveActionAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant DestructiveActionAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = .5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: FailsafeConfig.rootModeActive,
    builder: (context, blackHoleMode, _) => SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final phase = widget.animate ? _controller.value * 2 * math.pi : 0.0;
          if (blackHoleMode && widget.effect == DestructiveEffect.trash) {
            // Replace the bin with an event horizon and inward-orbiting matter.
            return Stack(
              alignment: Alignment.center,
              children: [
                BlackHoleDisc(size: widget.size * .92, animate: widget.animate),
                for (var i = 0; i < 5; i++)
                  Positioned(
                    left: widget.size * (.5 + .34 * math.cos(phase + i * 2 * math.pi / 5)) - widget.size * .025,
                    top: widget.size * (.5 + .34 * math.sin(phase + i * 2 * math.pi / 5)) - widget.size * .025,
                    child: Transform.scale(
                      scale: .45 + .55 * (.5 + .5 * math.sin(phase * 1.6 + i)),
                      child: Container(
                        width: widget.size * .05,
                        height: widget.size * .05,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFD6A0).withValues(alpha: .55 + .4 * math.sin(phase).abs()),
                          boxShadow: [BoxShadow(color: const Color(0xFFFF8A1F).withValues(alpha: .65), blurRadius: widget.size * .07)],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }
        final pulse = widget.animate ? .5 + .5 * math.sin(phase) : .5;
        final swing = widget.animate ? math.sin(phase) : 0.0;
        final color = widget.effect == DestructiveEffect.trash ? const Color(0xFFFF8A34) : const Color(0xFFE5394F);
        final icon = widget.effect == DestructiveEffect.trash ? Icons.delete_outline_rounded : Icons.delete_forever_rounded;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Transform.scale(
              scale: .78 + pulse * .12,
              child: Container(
                width: widget.size * .72,
                height: widget.size * .72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: .06 + pulse * .08),
                  border: Border.all(color: color.withValues(alpha: .24 + pulse * .28)),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: .12 + pulse * .12), blurRadius: 8 + pulse * 8)],
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(swing * 2.2, -pulse * 1.1),
              child: Transform.rotate(
                angle: swing * (widget.effect == DestructiveEffect.trash ? .06 : .025),
                child: Icon(icon, size: widget.size * .53, color: color),
              ),
            ),
            for (var i = 0; i < 3; i++)
              Positioned(
                left: widget.size * (.18 + .25 * i),
                top: widget.size * (.16 + .07 * math.sin(phase + i * 2 * math.pi / 3).abs()),
                child: Container(
                  width: widget.size * .045,
                  height: widget.size * .045,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: .2 + pulse * .4)),
                ),
              ),
          ],
        );
        },
      ),
    ),
  );
}
