import 'package:aves/model/settings/settings.dart';
import 'dart:async';

import 'package:aves/model/security/privacy_options.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/aves_confirmation_dialog.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:aves_model/aves_model.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

const dangerWord = 'BORRAR';
const _dangerDelay = Duration(seconds: 5);

// Deletion confirmation against mistakes:
// 1. red button, disabled for a few seconds so that it is not tapped by reflex,
// 2. then the user has to type the word.
// When the option is off, this is a regular confirmation.
Future<bool> confirmDangerousDelete({
  required BuildContext context,
  required String message,
  required String confirmLabel,
  required Future<bool> Function() regular,
}) async {
  if (!privacyOptions.strictDelete) return regular();

  final first = await showAvesDialog<bool>(
    context: context,
    builder: (context) => _DelayedDangerDialog(message: message, confirmLabel: confirmLabel),
    routeSettings: const RouteSettings(name: AvesDialog.confirmationRouteName),
  );
  if (first != true || !context.mounted) return false;

  final typed = await showAvesDialog<bool>(
    context: context,
    builder: (context) => const _TypeWordDialog(),
    routeSettings: const RouteSettings(name: AvesDialog.confirmationRouteName),
  );
  return typed == true;
}

class _DelayedDangerDialog extends StatefulWidget {
  final String message, confirmLabel;

  const _DelayedDangerDialog({required this.message, required this.confirmLabel});

  @override
  State<_DelayedDangerDialog> createState() => _DelayedDangerDialogState();
}

class _DelayedDangerDialogState extends State<_DelayedDangerDialog> {
  late int _remaining = _dangerDelay.inSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) timer.cancel();
      if (mounted) setState(() => _remaining--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AvesDialog(
      content: Text(widget.message),
      actions: [
        const CancelButton<bool>(result: false),
        _HoldToConfirmButton(
          label: widget.confirmLabel,
          remaining: _remaining,
          onConfirmed: () => Navigator.maybeOf(context)?.pop<bool>(true),
        ),
      ],
    );
  }
}

class _TypeWordDialog extends StatefulWidget {
  final String word;

  const _TypeWordDialog({this.word = dangerWord});

  @override
  State<_TypeWordDialog> createState() => _TypeWordDialogState();
}

class _TypeWordDialogState extends State<_TypeWordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _controller.text == widget.word;
    return AvesDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.dangerTypeWordMessage(widget.word)),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        const CancelButton<bool>(result: false),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _crystal ? const Color(0xB3C4122F) : Colors.red.shade700,
            foregroundColor: Colors.white,
            side: _crystal ? const BorderSide(color: Color(0x99FFB3BF)) : null,
          ),
          onPressed: matches ? () => Navigator.maybeOf(context)?.pop<bool>(true) : null,
          child: Text(widget.word),
        ),
      ],
    );
  }
}

// convenience wrappers with the regular fallbacks
Future<bool> confirmDeleteForever({
  required BuildContext context,
  required String message,
  required String confirmLabel,
}) {
  return confirmDangerousDelete(
    context: context,
    message: message,
    confirmLabel: confirmLabel,
    regular: () => showSkippableConfirmationDialog(context: context, type: ConfirmationDialog.deleteForever, message: message, confirmationButtonLabel: confirmLabel),
  );
}

// warning before enabling a risky option: red button, disabled for a few seconds
Future<bool> showRiskWarning(BuildContext context, String message) async {
  final confirmed = await showAvesDialog<bool>(
    context: context,
    builder: (context) => _DelayedDangerDialog(message: message, confirmLabel: context.l10n.riskWarningContinue),
    routeSettings: const RouteSettings(name: AvesDialog.confirmationRouteName),
  );
  return confirmed == true;
}

// with the glass options, solid buttons become translucent red crystal
bool get _crystal => settings.glassEverywhere || settings.batGlass;

const _crystalGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xE6FF6A80), Color(0xCCC4122F), Color(0xE67A0A1E)],
);

// red button that has to be held for 2 seconds, with a fill animation covering the whole pill;
// disabled (with the remaining seconds) while `remaining` is positive
class _HoldToConfirmButton extends StatefulWidget {
  final String label;
  final int remaining;
  final VoidCallback onConfirmed;

  const _HoldToConfirmButton({required this.label, required this.remaining, required this.onConfirmed});

  @override
  State<_HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<_HoldToConfirmButton> with SingleTickerProviderStateMixin {
  static const _holdDuration = Duration(seconds: 2);
  static const _width = 128.0;
  static const _height = 40.0;

  late final AnimationController _controller = AnimationController(vsync: this, duration: _holdDuration)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        widget.onConfirmed();
      }
    });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _release() {
    if (_controller.status != AnimationStatus.completed) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.remaining <= 0;
    final red = Colors.red.shade700;
    final scheme = Theme.of(context).colorScheme;
    final crystal = _crystal;
    final label = enabled ? widget.label : '${widget.label} (${widget.remaining})';

    return GestureDetector(
      onTapDown: enabled ? (_) => _controller.forward() : null,
      onTapUp: enabled ? (_) => _release() : null,
      onTapCancel: enabled ? _release : null,
      child: Container(
        width: _width,
        height: _height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_height / 2),
          border: crystal && enabled ? Border.all(color: const Color(0x99FFB3BF)) : null,
        ),
        // the clip covers the whole pill, including the fill animation
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_height / 2),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(child: ColoredBox(color: enabled ? red.withValues(alpha: .3) : scheme.surfaceContainerHighest)),
              if (enabled)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FractionallySizedBox(
                        widthFactor: _controller.value,
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: crystal ? const BoxDecoration(gradient: _crystalGradient) : BoxDecoration(color: red),
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(color: enabled ? Colors.white : scheme.onSurface.withValues(alpha: .5), fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// risk confirmation in two steps: the delayed warning, then typing a word (e.g. `ENTIENDO`)
Future<bool> confirmTypedRisk(BuildContext context, String message, String word) async {
  if (!await showRiskWarning(context, message) || !context.mounted) return false;

  final typed = await showAvesDialog<bool>(
    context: context,
    builder: (context) => _TypeWordDialog(word: word),
    routeSettings: const RouteSettings(name: AvesDialog.confirmationRouteName),
  );
  return typed == true;
}
