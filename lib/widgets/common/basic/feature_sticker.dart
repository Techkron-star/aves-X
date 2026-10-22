import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:material_ui/material_ui.dart';

enum StickerKind { newFeature, experimental }

// small label shown next to the name of a feature, like the "NEW" tags of video games
class FeatureSticker extends StatelessWidget {
  final StickerKind kind;

  const FeatureSticker({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final l10n = context.l10n;
        final isNew = kind == StickerKind.newFeature;
        final scheme = Theme.of(context).colorScheme;
        final glass = settings.glassEverywhere || settings.materialStyle != null;

        // gold for new features, theme error/accent for experimental ones
        final base = isNew ? scheme.tertiary : scheme.error;
        final onBase = isNew ? scheme.onTertiary : scheme.onError;

        final fill = glass ? base.withValues(alpha: .24) : base;
        final fillEnd = glass ? base.withValues(alpha: .12) : Color.lerp(base, Colors.black, .18)!;
        final border = base.withValues(alpha: glass ? .65 : 1);
        final ink = glass ? scheme.onSurface : onBase;
        final shadow = glass ? base.withValues(alpha: .16) : Colors.black26;

        return Transform.rotate(
          angle: -.05,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [fill, fillEnd],
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: shadow,
                  blurRadius: glass ? 6 : 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              child: Text(
                (isNew ? l10n.stickerNew : l10n.stickerExperimental).toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .6,
                  color: ink,
                  shadows: glass ? [Shadow(color: base.withValues(alpha: .35), blurRadius: 4)] : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
