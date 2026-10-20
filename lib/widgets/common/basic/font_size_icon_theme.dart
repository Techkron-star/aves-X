import 'package:aves/widgets/common/fx/liquid.dart';
import 'package:flutter/widgets.dart';

// scale icons according to text scale
class FontSizeIconTheme extends StatelessWidget {
  final Widget child;

  const new({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final iconTheme = IconTheme.of(context);
    // Bat-Glass: app bar actions get the liquid highlight too (no-op otherwise)
    return LiquidIcon(
      child: IconTheme(
        data: iconTheme.copyWith(
          size: textScaler.scale(iconTheme.size!),
        ),
        child: child,
      ),
    );
  }
}
