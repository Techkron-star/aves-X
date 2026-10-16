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
    final scheme = Theme.of(context).colorScheme;
    final ready = _remaining <= 0;
    return AvesDialog(
      content: Text(widget.message),
      actions: [
        const CancelButton<bool>(result: false),
        if (ready)
          _HoldToConfirmButton(
            label: widget.confirmLabel,
            onConfirmed: () => Navigator.maybeOf(context)?.pop<bool>(true),
          )
        else
          FilledButton(
            style: FilledButton.styleFrom(disabledBackgroundColor: scheme.surfaceContainerHighest),
            onPressed: null,
            child: Text('${widget.confirmLabel} ($_remaining)'),
          ),
      ],
    );
  }
}

class _TypeWordDialog extends StatefulWidget {
  const _TypeWordDialog();

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
    final matches = _controller.text == dangerWord;
    return AvesDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.dangerTypeWordMessage(dangerWord)),
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
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
          onPressed: matches ? () => Navigator.maybeOf(context)?.pop<bool>(true) : null,
          child: Text(dangerWord),
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

// red button that has to be held for 2 seconds, with a fill animation
class _HoldToConfirmButton extends StatefulWidget {
  final String label;
  final VoidCallback onConfirmed;

  const _HoldToConfirmButton({required this.label, required this.onConfirmed});

  @override
  State<_HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<_HoldToConfirmButton> with SingleTickerProviderStateMixin {
  static const _holdDuration = Duration(seconds: 2);

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
    final red = Colors.red.shade700;
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _release(),
      onTapCancel: _release,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 40,
          constraints: const BoxConstraints(minWidth: 140),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          color: red.withValues(alpha: .3),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(widthFactor: _controller.value, child: ColoredBox(color: red, child: const SizedBox.expand())),
                  ),
                ),
              ),
              Text(widget.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
