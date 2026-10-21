import 'package:aves/model/security/gargantua.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/tiles/sub_page.dart';
import 'package:aves/widgets/settings/settings_definition.dart';
import 'package:material_ui/material_ui.dart';

// Gargantua: files do not leave the app without permission.
// Phase 1 only exposes the "share and hand off" category; the other ones come later.
class GargantuaPage extends StatefulWidget {
  static const routeName = '/settings/gargantua';

  const GargantuaPage({super.key});

  @override
  State<GargantuaPage> createState() => _GargantuaPageState();
}

class _GargantuaPageState extends State<GargantuaPage> {
  late Future<void> _loader = gargantua.init();

  Future<void> _retry() async {
    setState(() => _loader = gargantua.reload());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AvesScaffold(
      appBar: AppBar(title: Text(l10n.settingsGargantua)),
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _loader,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());

            return ListenableBuilder(
              listenable: gargantua,
              builder: (context, _) {
                final master = gargantua.masterEnabled;
                final error = Theme.of(context).colorScheme.error;
                return ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l10n.gargantuaExplanation),
                    ),
                    if (gargantua.storeError)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.gargantuaWarningStoreError,
                              style: TextStyle(color: error, fontWeight: FontWeight.w600),
                            ),
                            TextButton(onPressed: _retry, child: Text(l10n.gargantuaRetryStore)),
                          ],
                        ),
                      ),
                    SwitchListTile(
                      value: master,
                      title: Text(l10n.gargantuaMaster),
                      subtitle: Text(l10n.gargantuaMasterSubtitle),
                      onChanged: (value) => gargantua.setMaster(context, value),
                    ),
                    SwitchListTile(
                      value: master && gargantua.categoryEnabled(GargantuaCategory.share),
                      title: Text(l10n.gargantuaCategoryShare),
                      subtitle: Text(l10n.gargantuaCategoryShareSubtitle),
                      onChanged: master ? (value) => gargantua.setCategory(context, GargantuaCategory.share, value) : null,
                    ),
                    SwitchListTile(
                      value: master && gargantua.requireMasterCode,
                      title: Text(l10n.gargantuaRequireMasterCode),
                      subtitle: Text(l10n.gargantuaRequireMasterCodeSubtitle),
                      onChanged: master ? (value) => gargantua.setRequireMasterCode(context, value) : null,
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        l10n.gargantuaWarningNoRecovery,
                        style: TextStyle(color: error, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(l10n.gargantuaWarningAttempts),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Text(l10n.gargantuaWarningAlreadyShared),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// Entry point linked from the Security section (owned by `failsafe-ui`), kept here to avoid duplicating the page.
class SettingsTileGargantua extends SettingsTile {
  @override
  List<String> get settingKeys => []; // kept in the secure store, not in the settings

  @override
  String title(BuildContext context) => context.l10n.settingsGargantua;

  @override
  Widget build(BuildContext context) => SettingsSubPageTile(
    title: title,
    subtitle: (context) => Text(context.l10n.settingsGargantuaSubtitle),
    routeName: GargantuaPage.routeName,
    builder: (context) => const GargantuaPage(),
  );
}
