import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

// 6-digit code, used for the Master Code, the app PIN and the panic PIN
class CodeDialog extends StatefulWidget {
  static const routeName = '/dialog/code';
  static const length = 6;

  final bool needConfirmation;
  final String? message;

  const CodeDialog({super.key, required this.needConfirmation, this.message});

  @override
  State<CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<CodeDialog> {
  final _controller = PinInputController();
  bool _confirming = false;
  String? _firstCode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AvesDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.message != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(widget.message!, textAlign: TextAlign.center)),
          Text(_confirming ? context.l10n.pinDialogConfirm : context.l10n.pinDialogEnter, textAlign: TextAlign.center),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: CodeDialog.length * 48.0,
                  child: MaterialPinField(
                    length: CodeDialog.length,
                    pinController: _controller,
                    keyboardType: TextInputType.number,
                    autoFocus: true,
                    autoDismissKeyboard: !widget.needConfirmation || _confirming,
                    obscureText: true,
                    onChanged: (v) {},
                    onCompleted: _submit,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit(String code) {
    if (!widget.needConfirmation) {
      Navigator.maybeOf(context)?.pop<String>(code);
    } else if (_confirming) {
      final match = _firstCode == code;
      Navigator.maybeOf(context)?.pop<String>(match ? code : null);
      if (!match) {
        showWarningDialog(context: context, message: context.l10n.genericFailureFeedback);
      }
    } else {
      _firstCode = code;
      _controller.clear();
      setState(() => _confirming = true);
    }
  }
}
