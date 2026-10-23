import 'package:aves/model/security/failsafe.dart';
import 'package:aves/model/security/failsafe_config.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/fx/black_hole.dart';
import 'package:material_ui/material_ui.dart';

/// Gargantuan is Aves-X's optional root-assisted Black Hole mode.
/// It is deliberately distinct from Gargantua, which protects data leaving the app.
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
    final scheme = Theme.of(context).colorScheme;
    return AvesScaffold(
      appBar: AppBar(title: const Text('Gargantuan')),
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: failsafe.safeMode,
          builder: (context, safeMode, _) => AbsorbPointer(
            absorbing: safeMode,
            child: Opacity(
              opacity: safeMode ? .5 : 1,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0x885F32A5)),
                      gradient: const RadialGradient(
                        center: Alignment(0, -.25),
                        radius: 1.12,
                        colors: [Color(0xFF35134F), Color(0xFF10091D), Color(0xFF030206)],
                        stops: [0, .48, 1],
                      ),
                      boxShadow: const [
                        BoxShadow(color: Color(0x332D0D48), blurRadius: 28, spreadRadius: -4),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 450),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF170B25).withValues(alpha: _enabled ? .96 : .65),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF9B42FF).withValues(alpha: _enabled ? .28 : .1),
                                  blurRadius: _enabled ? 32 : 15,
                                  spreadRadius: _enabled ? 5 : 0,
                                ),
                              ],
                            ),
                            child: _loading
                                ? const SizedBox.square(dimension: 112, child: Center(child: CircularProgressIndicator()))
                                : BlackHoleDisc(size: 112, animate: animate),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'GARGANTUAN',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 3.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'BLACK HOLE MODE',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: const Color(0xFFD7B8FF),
                              letterSpacing: 2.4,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Let the event horizon take over the destructive-action visuals.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xD9FFFFFF),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Divider(color: const Color(0x66C59AFF)),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            secondary: Icon(
                              _enabled ? Icons.blur_on_rounded : Icons.radio_button_unchecked_rounded,
                              color: _enabled ? const Color(0xFFD7B8FF) : scheme.onSurfaceVariant,
                            ),
                            title: const Text('Black Hole mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              _rootAvailable ? l10n.blackHoleRootOptionSubtitle : l10n.blackHoleRootUnavailable,
                              style: const TextStyle(color: Color(0xBFFFFFFF)),
                            ),
                            value: _enabled,
                            onChanged: _loading || safeMode ? null : _setEnabled,
                            activeColor: const Color(0xFFD7B8FF),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow.withValues(alpha: .72),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: scheme.outlineVariant.withValues(alpha: .45)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: scheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Gargantuan is the visual Black Hole mode. Gargantua is a separate protection policy for sharing and handing files to other apps.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
