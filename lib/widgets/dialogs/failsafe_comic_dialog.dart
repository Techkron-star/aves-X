import 'dart:async';

import 'package:aves/model/security/failsafe_voice.dart';
import 'package:aves/theme/nebula/nebula_tokens.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/fx/app_mark.dart';
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
  bool _narrating = false;

  @override
  void initState() {
    super.initState();
    unawaited(_narrate());
  }

  String? _voiceError;

  Future<void> _narrate() async {
    if (_narrating) return; // prevent spam
    _narrating = true;
    try {
      final status = await FailsafeVoice.say(widget.message);
      if (!mounted) return;
      setState(() => _voiceError = FailsafeVoice.isFailure(status) ? FailsafeVoice.describe(context.l10n, status) : null);
    } finally {
      if (mounted) {
        setState(() => _narrating = false);
      }
    }
  }

  @override
  void dispose() {
    // Stop any ongoing narration when dialog is dismissed
    FailsafeVoice.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.nebula;
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
                  color: t.securityScrim,
                  border: Border.all(color: t.securityAccent, width: 2),
                ),
                child: const Center(child: AppMark(size: 24)),
              ),
              const SizedBox(width: 10),
              // name plate: `securityOnSurface` is the readable ink on `securitySurface`, which is not the
              // barrier colour behind the transparent dialog, so the name needs its own surface
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: t.securitySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.securityBubbleBorder.withValues(alpha: .5)),
                ),
                child: Text('Fail-Safe', style: TextStyle(color: t.securityOnSurface, fontWeight: FontWeight.w800, letterSpacing: .5)),
              ),
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
                    color: t.securityBubbleSurface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: t.securityBubbleBorder, width: 3),
                    boxShadow: [
                      // soft glow for depth, under the hard comic shadow
                      BoxShadow(color: t.securityBubbleGlow, blurRadius: 13, spreadRadius: 1),
                      // hard comic-style shadow
                      BoxShadow(color: t.securityBubbleShadow, offset: const Offset(5, 5)),
                    ],
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
                            style: TextStyle(color: t.securityBubbleInk, fontSize: 15, fontWeight: FontWeight.w600, height: 1.3),
                          ),
                          if (_voiceError != null) ...[
                            const SizedBox(height: 8),
                            Text(_voiceError!, style: TextStyle(color: t.securityAlert, fontSize: 11, fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // tail of the bubble, pointing up to the character
              PositionedDirectional(
                top: -17,
                start: 20,
                child: CustomPaint(size: const Size(26, 20), painter: _TailPainter(fill: t.securityBubbleTail, line: t.securityBubbleBorder)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: t.securitySurface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: t.securityBubbleBorder.withValues(alpha: .5)),
            ),
            child: Theme(
              data: theme.copyWith(
                textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: t.securityOnSurface)),
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
