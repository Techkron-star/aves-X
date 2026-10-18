import 'dart:async';

import 'package:aves/model/security/app_lock.dart';
import 'package:aves/model/security/failsafe.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/fx/failsafe_badge.dart';
import 'package:aves/widgets/settings/security/failsafe_section.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';

// first launch: the Failsafe introduces itself and offers its options
Future<void> maybeShowFailsafeWelcome(GlobalKey<NavigatorState> navigatorKey) async {
  if (!await failsafe.needsWelcome) return;
  // wait for the app to be usable (not locked, not in lockdown)
  for (var i = 0; i < 40; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 750));
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) continue;
    if (!appLock.ready || appLock.locked || failsafe.lockdown.value) continue;
    // only mark it as seen once it was shown
    await failsafe.markWelcomed();
    if (!context.mounted) return;
    final configure = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(l10n.failsafeWelcomeTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: FailsafeBadge()),
                const SizedBox(height: 8),
                Text(l10n.failsafeWelcomeMessage),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.maybeOf(context)?.pop(false), child: Text(l10n.failsafeWelcomeDismiss)),
            TextButton(onPressed: () => Navigator.maybeOf(context)?.pop(true), child: Text(l10n.failsafeWelcomeConfigure)),
          ],
        );
      },
    );
    if (configure == true && navigatorKey.currentContext != null && navigatorKey.currentContext!.mounted) {
      await FailsafeSection.open(navigatorKey.currentContext!);
    }
    return;
  }
}
