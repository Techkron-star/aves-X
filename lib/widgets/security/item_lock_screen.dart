import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/item_locks.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/nebula/nebula_material.dart';
import 'package:aves/theme/nebula/nebula_tokens.dart';
import 'package:aves/widgets/common/action_mixins/feedback.dart';
import 'package:aves/widgets/common/basic/scaffold.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/fx/blurred.dart';
import 'package:aves/widgets/common/fx/diamond.dart';
import 'package:aves/widgets/common/fx/failsafe_badge.dart';
import 'package:aves/widgets/common/fx/lock_animation.dart';
import 'package:flutter/material.dart';

// Full-screen lock for a single item (photo/video) or a whole album.
// It covers the content with the Fail-Safe scrim and a translucent surface,
// shows a `LockedBadge` and asks the user to authenticate with the items lock.
// On success the screen is popped and the thumbnail plays the unlock animation:
// `ThumbnailImage` reacts to `ItemLocks.isRecentlyUnlocked` via its `ListenableBuilder`
// and shows `_UnlockingThumbnail` (`LockedBadge.playUnlockAnimation`).
class ItemLockScreen extends StatelessWidget with FeedbackMixin {
  /// The locked item, or `null` when unlocking a whole album.
  final AvesEntry? entry;
  /// The album directory path, used when `entry` is `null`.
  final String? dirPath;

  const ItemLockScreen({super.key, this.entry, this.dirPath});

  bool get _isAlbum => entry == null;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final nebula = Theme.of(context).nebula;
    final animate = settings.animate && !settings.performanceMode;
    final material = settings.materialStyle;
    final glass = material != null || settings.glassEverywhere;

    return AvesScaffold(
      backgroundColor: nebula.securityScrimOverlay,
      body: SafeArea(
        child: AnimatedCrystal(
          animate: animate,
          opacity: .3,
          material: material?.material ?? NebulaMaterial.ruby,
          // the glass of the theme with a slow glint (cracks flaring up for Night Demon): Fail-Safe holds the item
          child: Center(
            child: BlurredRRect.all(
              borderRadius: 26,
              enabled: glass,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: nebula.securitySurface,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: 160,
                        child: Center(child: LockedBadge(fresh: false)),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _isAlbum ? l10n.itemLockAlbumLocked : l10n.itemLockItemLocked,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: nebula.securityOnSurface),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.itemLockUnlockHint,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: nebula.securityOnSurface.withValues(alpha: .7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: () => _unlock(context),
                        child: Text(l10n.itemLockUnlockButton),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _unlock(BuildContext context) async {
    final l10n = context.l10n;
    final ok = _isAlbum
        ? (dirPath == null ? false : await itemLocks.unlockAlbum(context, dirPath!))
        : (entry == null ? false : await itemLocks.unlockEntry(context, entry!));
    if (!context.mounted) return;
    if (!ok) {
      showFeedback(context, FeedbackType.warn, l10n.itemLockUnlockFailed);
      return;
    }
    if (context.mounted) Navigator.maybeOf(context)?.pop();
  }
}
