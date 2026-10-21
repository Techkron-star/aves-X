import 'dart:async';

import 'package:aves/model/security/failsafe_voice.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/fx/lock_animation.dart';
import 'package:material_ui/material_ui.dart';

// Warning and confirmation messages as a comic speech bubble said by the Fail-Safe character,
// who also reads the message out loud with his voice (tap the bubble to hear it again).
// Used by `AvesDialog` when the option is on, for dialogs that only show a message.
class FailsafeComicDialog extends StatefulWidget {
  final String message;
  final List<Widget> actions;

  const FailsafeComicDialog({super.key, required this.message, required this.actions});

  @override
  State<FailsafeComicDialog> createState() => _FailsafeComicDialogState();
}

class _FailsafeComicDialogState extends State<FailsafeComicDialog> {
  static const _ink = Color(0xFF14121A);
  static const _paper = Color(0xFFFFFBF0);

  @override
  void initState() {
    super.initState();
    unawaited(_narrate());
  }

  String? _voiceError;

  Future<void> _narrate() async {
    final status = await FailsafeVoice.say(widget.message);
    if (!mounted) return;
    setState(() => _voiceError = FailsafeVoice.isFailure(status) ? FailsafeVoice.describe(context.l10n, status) : null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * .5;
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black87,
                  border: Border.all(color: const Color(0xFFFF5A6E), width: 2),
                ),
                child: const Center(child: BatMark(size: 24)),
              ),
              const SizedBox(width: 10),
              const Text('Fail-Safe', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: .5)),
            ],
          ),
          const SizedBox(height: 18),
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: _narrate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: _paper,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _ink, width: 3),
                    // hard comic-style shadow
                    boxShadow: const [BoxShadow(color: _ink, offset: Offset(5, 5))],
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.message,
                            style: const TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w600, height: 1.3),
                          ),
                          if (_voiceError != null) ...[
                            const SizedBox(height: 8),
                            Text(_voiceError!, style: const TextStyle(color: Color(0xFFB3122D), fontSize: 11, fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // tail of the bubble, pointing up to the character
              const PositionedDirectional(
                top: -17,
                start: 20,
                child: CustomPaint(size: Size(26, 20), painter: _TailPainter(fill: _paper, line: _ink)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .65),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Theme(
              data: theme.copyWith(
                textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: Colors.white)),
              ),
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: widget.actions,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  final Color fill, line;

  const _TailPainter({required this.fill, required this.line});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(0, h)
      ..lineTo(w * .3, 1)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(path, Paint()..color = fill);
    // only the two slanted sides get an outline: the base merges with the bubble
    final edges = Path()
      ..moveTo(0, h)
      ..lineTo(w * .3, 1)
      ..lineTo(w, h);
    canvas.drawPath(
      edges,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) => oldDelegate.fill != fill || oldDelegate.line != line;
}
