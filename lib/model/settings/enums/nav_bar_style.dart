import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/widgets.dart';

// shape of the bottom navigation bar
enum NavBarStyle { classic, rounded, floating, rectangular }

extension ExtraNavBarStyle on NavBarStyle {
  String getName(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case NavBarStyle.classic:
        return l10n.navBarStyleClassic;
      case NavBarStyle.rounded:
        return l10n.navBarStyleRounded;
      case NavBarStyle.floating:
        return l10n.navBarStyleFloating;
      case NavBarStyle.rectangular:
        return l10n.navBarStyleRectangular;
    }
  }

  BorderRadius get borderRadius {
    switch (this) {
      case NavBarStyle.classic:
        return const BorderRadius.all(Radius.circular(8));
      case NavBarStyle.rounded:
        return const BorderRadius.all(Radius.circular(24));
      case NavBarStyle.floating:
        return const BorderRadius.all(Radius.circular(32));
      case NavBarStyle.rectangular:
        return BorderRadius.zero;
    }
  }

  EdgeInsets margin(double safeBottomPadding) {
    switch (this) {
      case NavBarStyle.classic:
      case NavBarStyle.rounded:
        return EdgeInsets.only(left: 8, top: 8, right: 8, bottom: safeBottomPadding + 4 > 8 ? safeBottomPadding + 4 : 8);
      case NavBarStyle.floating:
        return EdgeInsets.only(left: 24, top: 8, right: 24, bottom: safeBottomPadding + 12 > 16 ? safeBottomPadding + 12 : 16);
      case NavBarStyle.rectangular:
        return EdgeInsets.only(top: 0, bottom: safeBottomPadding);
    }
  }
}
