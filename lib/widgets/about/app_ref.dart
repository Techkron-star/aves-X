import 'package:aves/widgets/common/fx/app_mark.dart';
import 'package:aves/model/device.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/theme/styles.dart';
import 'package:aves/widgets/about/policy_page.dart';
import 'package:aves/widgets/common/basic/link_chip.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/identity/aves_logo.dart';
import 'package:material_ui/material_ui.dart';

class AppReference extends StatelessWidget {
  static const avesGithub = 'https://github.com/deckerst/aves';
  static const avesXGithub = 'https://github.com/Techkron-star/aves-X';
  static const avesFaq = '$avesGithub/wiki/FAQ';

  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          _buildAvesLine(context),
          const SizedBox(height: 8),
          Text(
            context.l10n.aboutBasedOnAves(device.packageVersion),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: .center,
            spacing: 16,
            crossAxisAlignment: .center,
            children: AppReference.buildLinks(context),
          ),
          const SizedBox(height: 20),
          _buildForkCredit(context),
        ],
      ),
    );
  }

  // the author of the fork, highlighted with the Bat-Glass look and a bat on each side
  Widget _buildForkCredit(BuildContext context) {
    return Column(
      children: [
        Text(
          context.l10n.aboutForkedBy,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xCC2A0710), Color(0xCC090103)],
            ),
            border: Border.all(color: const Color(0x99FF6A80), width: 1.2),
            boxShadow: const [BoxShadow(color: Color(0x44E0183E), blurRadius: 14)],
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: .min,
              spacing: 6,
              children: [
                // both bats look towards the name
                AppMark(size: 30),
                LinkChip(
                  leading: Icon(
                    AIcons.github,
                    size: 22,
                    color: Colors.white,
                  ),
                  text: 'Techkron-star',
                  urlString: 'https://github.com/Techkron-star',
                ),
                AppMark(size: 30, mirrored: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvesLine(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final appName = context.l10n.appName;
    const fontSize = 20.0;
    final appTitleStyle = AStyles.appNameStyle(context, appName).copyWith(
      fontSize: fontSize,
      fontWeight: .normal,
    );

    return Row(
      mainAxisSize: .min,
      spacing: 8,
      children: [
        AvesLogo(
          size: textScaler.scale(fontSize) * 1.3,
        ),
        Text(
          appName,
          style: appTitleStyle,
        ),
        Text(
          'alpha',
          style: appTitleStyle,
        ),
      ],
    );
  }

  static List<Widget> buildLinks(BuildContext context) {
    final l10n = context.l10n;
    return [
      const LinkChip(
        leading: Icon(
          AIcons.github,
          size: 24,
        ),
        text: 'Aves-X',
        urlString: AppReference.avesXGithub,
      ),
      const LinkChip(
        leading: Icon(
          AIcons.github,
          size: 24,
        ),
        text: 'Aves',
        urlString: AppReference.avesGithub,
      ),
      LinkChip(
        leading: const Icon(
          AIcons.legal,
          size: 22,
        ),
        text: l10n.aboutLinkLicense,
        urlString: '${AppReference.avesXGithub}/blob/develop/LICENSE',
      ),
      LinkChip(
        leading: const Icon(
          AIcons.privacy,
          size: 22,
        ),
        text: l10n.aboutLinkPolicy,
        onTap: () => _goToPolicyPage(context),
      ),
    ];
  }

  static void _goToPolicyPage(BuildContext context) {
    Navigator.maybeOf(context)?.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: PolicyPage.routeName),
        builder: (context) => const PolicyPage(),
      ),
    );
  }
}
