import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/nebula/nebula_material.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/navigation/drawer/tile.dart';
import 'package:aves/widgets/common/fx/nebula_component_surfaces.dart';
import 'package:aves/widgets/navigation/nav_item.dart';
import 'package:material_ui/material_ui.dart';

typedef TileRouteBuilder = Route Function(BuildContext context, String routeName, bool topLevel);

class const PageNavTile({
  super.key,
  final Widget? leading,
  final Widget? title,
  final Widget? trailing,
  required final AvesNavItem navItem,
  final bool Function()? isSelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final routeName = navItem.route;
    final materialStyle = context.select<Settings, NebulaMaterialStyle?>((s) => s.materialStyle);
    final animate = context.select<Settings, bool>((s) => s.animate);
    final selected = context.currentRouteName == routeName && (isSelected?.call() ?? true);
    return SafeArea(
      top: false,
      bottom: false,
      child: NebulaComponentSurfaceAccent(
        style: materialStyle,
        role: NebulaComponentSurfaceRole.drawerItem,
        state: selected ? NebulaComponentSurfaceState.selected : NebulaComponentSurfaceState.idle,
        animate: animate && selected,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          // key is expected by test driver
          key: Key('$routeName-tile'),
          leading: leading ?? DrawerPageIcon(route: routeName),
          title: title ?? DrawerPageTitle(route: routeName),
          trailing: trailing != null
              ? Builder(
                  builder: (context) => DefaultTextStyle.merge(
                    style: TextStyle(
                      color: IconTheme.of(context).color!.withValues(alpha: .6),
                    ),
                    child: trailing!,
                  ),
                )
              : null,
          onTap: () {
            Navigator.maybeOf(context)?.pop();
            navItem.goTo(context);
          },
          selected: selected,
        ),
      ),
    );
  }
}
