import 'package:aves/model/device.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/view/view.dart';
import 'package:aves/widgets/about/app_ref.dart';
import 'package:aves/widgets/aves_app.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/settings/common/tiles/single_selection.dart';
import 'package:aves_model/aves_model.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class const VideoPlaybackPage({super.key}) extends StatelessWidget {
  static const routeName = '/settings/video/playback';

  static const List<String> settingKeys = [
    SettingKeys.videoAutoPlayModeKey,
    SettingKeys.videoLoopModeKey,
    SettingKeys.videoResumptionModeKey,
    SettingKeys.videoBackgroundModeKey,
    SettingKeys.videoCustomMpvOptionsKey,
    SettingKeys.videoHardwareAccelerationKey,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AvesScaffold(
      appBar: AppBar(
        title: Text(l10n.settingsVideoPlaybackPageTitle),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            SettingsSelectionListTile<VideoAutoPlayMode>(
              values: VideoAutoPlayMode.values,
              getName: (context, v) => v.getName(context),
              selector: (context, s) => s.videoAutoPlayMode,
              onSelection: (v) => settings.videoAutoPlayMode = v,
              tileTitle: (_) => l10n.settingsVideoAutoPlay,
            ),
            SettingsSelectionListTile<VideoLoopMode>(
              values: VideoLoopMode.values,
              getName: (context, v) => v.getName(context),
              selector: (context, s) => s.videoLoopMode,
              onSelection: (v) => settings.videoLoopMode = v,
              tileTitle: (_) => l10n.settingsVideoLoopModeTile,
              dialogTitle: l10n.settingsVideoLoopModeDialogTitle,
            ),
            SettingsSelectionListTile<VideoResumptionMode>(
              values: VideoResumptionMode.values,
              getName: (context, v) => v.getName(context),
              selector: (context, s) => s.videoResumptionMode,
              onSelection: (v) => settings.videoResumptionMode = v,
              tileTitle: (_) => l10n.settingsVideoResumptionModeTile,
              dialogTitle: l10n.settingsVideoResumptionModeDialogTitle,
            ),
            if (!settings.useTvLayout && device.supportPictureInPicture)
              SettingsSelectionListTile<VideoBackgroundMode>(
                values: VideoBackgroundMode.values,
                getName: (context, v) => v.getName(context),
                selector: (context, s) => s.videoBackgroundMode,
                onSelection: (v) => settings.videoBackgroundMode = v,
                tileTitle: (_) => l10n.settingsVideoBackgroundMode,
                dialogTitle: l10n.settingsVideoBackgroundModeDialogTitle,
              ),
            SettingsSelectionListTile<VideoHardwareAcceleration>(
              values: VideoHardwareAcceleration.values,
              getName: (context, v) => v.getName(context),
              selector: (context, s) => s.videoHardwareAcceleration,
              onSelection: (v) => settings.videoHardwareAcceleration = v,
              tileTitle: (_) => l10n.settingsVideoEnableHardwareAcceleration,
              trailingBuilder: (context) => IconButton(
                icon: const Icon(AIcons.help),
                onPressed: () => AvesApp.launchUrl('${AppReference.avesFaq}#should-i-enable-hardware-acceleration-to-play-videos'),
                tooltip: 'FAQ',
              ),
            ),
            const _CustomMpvOptionsTile(),
          ],
        ),
      ),
    );
  }
}

// advanced decoder / player options (mpv)
class _CustomMpvOptionsTile extends StatelessWidget {
  const _CustomMpvOptionsTile();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = context.select<Settings, String?>((s) => s.videoCustomMpvOptions);
    return ListTile(
      title: Text(l10n.settingsVideoCustomMpvOptions),
      subtitle: Text(value == null ? l10n.settingsVideoCustomMpvOptionsSubtitle : value.trim().split('\n').first),
      onTap: () async {
        final controller = TextEditingController(text: value ?? '');
        final result = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.settingsVideoCustomMpvOptions),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.settingsVideoCustomMpvOptionsHelp),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 6,
                    minLines: 3,
                    autocorrect: false,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    decoration: const InputDecoration(hintText: 'vd-lavc-threads=4\nhwdec-codecs=h264,hevc'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.maybeOf(context)?.pop(), child: Text(MaterialLocalizations.of(context).cancelButtonLabel)),
              TextButton(onPressed: () => Navigator.maybeOf(context)?.pop(controller.text), child: Text(l10n.applyButtonLabel)),
            ],
          ),
        );
        controller.dispose();
        if (result != null) settings.videoCustomMpvOptions = result;
      },
    );
  }
}
