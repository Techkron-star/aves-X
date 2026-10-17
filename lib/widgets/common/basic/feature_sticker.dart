import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:material_ui/material_ui.dart';

enum StickerKind { newFeature, experimental }

// small label shown next to the name of a feature, like the "NEW" tags of video games
class FeatureSticker extends StatelessWidget {
  final StickerKind kind;

  const FeatureSticker({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isNew = kind == StickerKind.newFeature;
    final colors = isNew ? const [Color(0xFFFFE066), Color(0xFFE0A100)] : const [Color(0xFFFF8A65), Color(0xFFD84315)];
    return Transform.rotate(
      angle: -.05,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isNew ? const Color(0xFF7A5300) : const Color(0xFF6E1F00), width: 1),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 3, offset: Offset(0, 1))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          child: Text(
            (isNew ? l10n.stickerNew : l10n.stickerExperimental).toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .6,
              color: isNew ? const Color(0xFF3B2800) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
