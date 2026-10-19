import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves_model/aves_model.dart';
import 'package:material_ui/material_ui.dart';

extension ExtraExplorerActionView on ExplorerAction {
  String getText(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      .addShortcut => l10n.collectionActionAddShortcut,
      .setHome => l10n.collectionActionSetHome,
      .hide => l10n.chipActionHide,
      .noMedia => l10n.explorerActionNoMedia,
      .showAllFolders => l10n.explorerActionShowAllFolders,
      .stats => l10n.menuActionStats,
    };
  }

  Widget getIcon() => Icon(_getIconData());

  IconData _getIconData() {
    return switch (this) {
      .addShortcut => AIcons.addShortcut,
      .setHome => AIcons.home,
      .hide => AIcons.hide,
      .noMedia => AIcons.hide,
      .showAllFolders => AIcons.show,
      .stats => AIcons.stats,
    };
  }
}
