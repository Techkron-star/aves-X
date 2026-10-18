import 'package:aves/view/view.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/basic/popup/menu_row.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/buttons/captioned_button.dart';
import 'package:aves_model/aves_model.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

// quick loop switch of the video player, lit when the loop is on
class LoopToggler extends StatelessWidget {
  final bool isMenuItem;
  final FocusNode? focusNode;
  final VoidCallback? onPressed;

  const new({
    super.key,
    this.isMenuItem = false,
    this.focusNode,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final mode = context.select<Settings, VideoLoopMode>((s) => s.videoLoopMode);
    final color = mode == VideoLoopMode.never ? null : Theme.of(context).colorScheme.primary;
    // repeat: off or short videos only, repeat one: always
    final icon = Icon(mode == VideoLoopMode.always ? AIcons.videoLoop : (mode == VideoLoopMode.never ? AIcons.repeatOff : AIcons.repeat), color: color);
    final text = '${context.l10n.videoActionLoop}: ${mode.getName(context)}';
    return isMenuItem
        ? MenuRow(text: text, icon: icon)
        : IconButton(
            icon: icon,
            onPressed: onPressed,
            focusNode: focusNode,
            tooltip: text,
          );
  }
}

class LoopTogglerCaption extends StatelessWidget {
  final bool enabled;

  const new({super.key, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return CaptionedButtonText(
      text: context.l10n.videoActionLoop,
      enabled: enabled,
    );
  }
}
