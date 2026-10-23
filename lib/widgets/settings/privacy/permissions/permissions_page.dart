import 'package:aves/model/device.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/tiles/switch_list.dart';
import 'package:aves/widgets/settings/privacy/permissions/manage_media.dart';
import 'package:aves/widgets/settings/privacy/permissions/notification.dart';
import 'package:aves_model/aves_model.dart';
import 'package:material_ui/material_ui.dart';

class const PermissionsPage({super.key}) extends StatelessWidget {
  static const routeName = '/settings/privacy/permissions';

  static const List<String> settingKeys = [
    SettingKeys.isInstalledAppAccessAllowedKey,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AvesScaffold(
      appBar: AppBar(
        title: Text(l10n.settingsPermissionsPageTitle),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            SettingsSwitchListTile(
              selector: (context, s) => s.isInstalledAppAccessAllowed,
              onChanged: (v) => settings.isInstalledAppAccessAllowed = v,
              leading: const Icon(AIcons.app),
              title: (context) => context.l10n.settingsAllowInstalledAppAccess,
              subtitle: (context) => context.l10n.settingsAllowInstalledAppAccessSubtitle,
            ),
            const NotificationPermissionTile(),
            if (!settings.useTvLayout && device.canRequestMediaManagementPermission) const ManageMediaTile(),
          ],
        ),
      ),
    );
  }
}
