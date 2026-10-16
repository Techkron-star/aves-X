import 'package:aves/model/security/auto_delete.dart';
import 'package:aves/model/security/master_code.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/model/vaults/vaults.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:aves/widgets/dialogs/danger_confirmation.dart';
import 'package:aves/widgets/dialogs/selection_dialogs/single_selection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

// Automatic deletion of old items: recycle bin retention, and per album/vault limits.
class AutoDeletePage extends StatelessWidget {
  static const routeName = '/settings/auto_delete';

  const AutoDeletePage({super.key});

  static String describe(BuildContext context, Duration d) {
    final l10n = context.l10n;
    if (d.inMinutes < 60) return l10n.autoDeleteMinutes(d.inMinutes);
    if (d.inHours < 24) return l10n.autoDeleteHours(d.inHours);
    return l10n.autoDeleteDays(d.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final source = context.read<CollectionSource>();
    return AvesScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !settings.useTvLayout,
        title: Text(l10n.settingsAutoDelete),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: autoDelete,
          builder: (context, _) {
            final vaultPaths = vaults.all.map((v) => v.path).toSet();
            final dirs = <String>{...source.rawAlbums, ...vaultPaths}.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.autoDeleteExplanation),
                ),
                ListTile(
                  title: Text(l10n.autoDeleteBin),
                  subtitle: Text(describe(context, autoDelete.binRetention)),
                  onTap: () => _choose(context, current: autoDelete.binRetention, allowOff: false, onSelected: (d) => autoDelete.setBinRetention(d!)),
                ),
                const Divider(),
                ...dirs.map((dir) {
                  final current = autoDelete.albumRetention(dir);
                  final isVault = vaultPaths.contains(dir);
                  return ListTile(
                    leading: Icon(isVault ? Icons.lock_outline : Icons.photo_album_outlined),
                    title: Text(p.basename(dir)),
                    subtitle: Text(current != null ? describe(context, current) : l10n.autoDeleteOff),
                    onTap: () => _choose(context, current: current, allowOff: true, onSelected: (d) => autoDelete.setAlbumRetention(dir, d)),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _choose(
    BuildContext context, {
    required Duration? current,
    required bool allowOff,
    required Future<void> Function(Duration? value) onSelected,
  }) async {
    final l10n = context.l10n;
    // -1 stands for "off"
    final options = <int, String>{
      if (allowOff) -1: l10n.autoDeleteOff,
      for (final d in AutoDelete.presets) d.inMinutes: describe(context, d),
    };
    final choice = await showAvesDialog<int>(
      context: context,
      builder: (context) => AvesSingleSelectionDialog<int>(
        initialValue: current?.inMinutes ?? -1,
        options: options,
        title: l10n.settingsAutoDelete,
      ),
      routeSettings: const RouteSettings(name: AvesSingleSelectionDialog.routeName),
    );
    if (choice == null || !context.mounted) return;

    final value = choice < 0 ? null : Duration(minutes: choice);
    if (value == current) return;

    // deleting automatically is destructive: Master Code first, and an explicit confirmation for short delays
    if (!await MasterCode.require(context) || !context.mounted) return;
    if (value != null && value < AutoDelete.shortDelay) {
      if (!await confirmTypedRisk(context, l10n.autoDeleteShortWarning, 'ENTIENDO')) return;
    }
    await onSelected(value);
  }
}
