import 'package:aves/model/security/failsafe.dart';
import 'package:aves/model/security/failsafe_config.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/fx/black_hole.dart';
import 'package:material_ui/material_ui.dart';

/// Gargantuan is the home for Aves-X's optional root-assisted Black Hole mode.
/// It is distinct from Gargantua, which guards data leaving the app.
class GargantuanModePage extends StatefulWidget {
  static const routeName = '/settings/gargantuan';

  const GargantuanModePage({super.key});

  @override
  State<GargantuanModePage> createState() => _GargantuanModePageState();
}

class _GargantuanModePageState extends State<GargantuanModePage> {
  bool _enabled = false;
  bool _rootAvailable = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await FailsafeConfig.rootMode;
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _loading = false;
    });
  }

  Future<void> _setEnabled(bool value) async {
    if (value) {
      final available = await securityService.isRootAvailable();
      if (!mounted) return;
      if (!available) {
        setState(() => _rootAvailable = false);
        return;
      }
    }
    await FailsafeConfig.setRootMode(value);
    if (!mounted) return;
    setState(() {
      _enabled = value;
      _rootAvailable = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final animate = settings.animate && !settings.performanceMode;
    return AvesScaffold(
      appBar: AppBar(title: const Text('Gargantuan')),
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: failsafe.safeMode,
          builder: (context, safeMode, _) => ListView(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Text(l10n.blackHoleRootOptionSubtitle),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0x665F32A5)),
                  gradient: const RadialGradient(
                    center: Alignment(-.85, -.2),
                    radius: 1.45,
                    colors: [Color(0xFF24103B), Color(0xFF090611), Color(0xFF030206)],
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x262D0D48), blurRadius: 22, spreadRadius: -4),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    secondary: _loading
                        ? const SizedBox.square(dimension: 52, child: Center(child: CircularProgressIndicator()))
                        : BlackHoleDisc(size: 52, animate: animate),
                    title: Text(l10n.blackHoleRootOption, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      _rootAvailable ? l10n.blackHoleRootOptionSubtitle : l10n.blackHoleRootUnavailable,
                      style: const TextStyle(color: Color(0xB3FFFFFF)),
                    ),
                    value: _enabled,
                    onChanged: _loading || safeMode ? null : _setEnabled,
                  ),
                ),
              ),
              if (safeMode)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(l10n.failsafeLockdownOptionSubtitle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
