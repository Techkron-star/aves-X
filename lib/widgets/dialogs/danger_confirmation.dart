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
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, disabledBackgroundColor: scheme.surfaceContainerHighest),
          onPressed: ready ? () => Navigator.maybeOf(context)?.pop<bool>(true) : null,
          child: Text(ready ? widget.confirmLabel : '${widget.confirmLabel} ($_remaining)'),
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
