import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/security/failsafe_config.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/fx/black_hole.dart';
import 'package:flutter/widgets.dart';

class TrashFilter extends CollectionFilter {
  static const type = 'trash';

  static bool _test(AvesEntry entry) => entry.trashed;

  static const instance = TrashFilter._private();
  static const instanceReversed = TrashFilter._private(reversed: true);

  @override
  List<Object?> get props => [reversed];

  const new _private({super.reversed = false});

  factory fromMap(Map<String, Object?> json) {
    final reversed = json['reversed'] as bool? ?? false;
    return reversed ? instanceReversed : instance;
  }

  @override
  Map<String, Object?> toJsonMap() => {
    'type': type,
    if (reversed) 'reversed': reversed,
  };

  @override
  EntryPredicate get positiveTest => _test;

  @override
  bool get exclusiveProp => false;

  @override
  String get universalLabel => type;

  @override
  String getLabel(BuildContext context) => context.l10n.filterBinLabel;

  // With Black Hole active, the bin wears the same event horizon and accretion disk as its settings card.
  @override
  Widget? iconBuilder(BuildContext context, double size, {bool allowGenericIcon = true}) => ValueListenableBuilder<bool>(
    valueListenable: FailsafeConfig.rootModeActive,
    builder: (context, blackHole, _) => blackHole
        ? BlackHoleDisc(size: size, animate: !settings.performanceMode)
        : Icon(AIcons.bin, size: size),
  );

  @override
  String get category => type;

  @override
  String get key => '$type-$reversed';
}
