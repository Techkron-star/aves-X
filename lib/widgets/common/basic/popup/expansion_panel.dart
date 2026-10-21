import 'package:aves/theme/durations.dart';
import 'package:aves/widgets/common/basic/popup/menu_row.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class PopupMenuExpansionPanel<T> extends PopupMenuEntry<T> {
  final bool enabled;
  final String value;
  final ValueNotifier<String?>? expandedNotifier;
  final IconData icon;
  final String title;
  final List<PopupMenuEntry<T>> items;

  const new({
    super.key,
    this.enabled = true,
    this.height = kMinInteractiveDimension,
    required this.value,
    this.expandedNotifier,
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  final double height;

  @override
  bool represents(void value) => false;

  @override
  State<PopupMenuExpansionPanel<T>> createState() => _PopupMenuExpansionPanelState<T>();
}

class _PopupMenuExpansionPanelState<T> extends State<PopupMenuExpansionPanel<T>> {
  final ValueNotifier<String?> _internalExpandedNotifier = ValueNotifier(null);

  ValueNotifier<String?> get expandedNotifier => widget.expandedNotifier ?? _internalExpandedNotifier;

  @override
  void dispose() {
    _internalExpandedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final states = <WidgetState>{
      if (!widget.enabled) WidgetState.disabled,
    };
    // never assume the theme defines the label style: a missing value would throw while building,
    // and a release build then shows a big gray box in place of the panel
    final style = PopupMenuTheme.of(context).labelTextStyle?.resolve(states) ?? (theme.textTheme.labelLarge ?? const TextStyle()).apply(color: widget.enabled ? theme.colorScheme.onSurface : theme.disabledColor);
    final animationDuration = context.select<DurationsData, Duration>((v) => v.expansionTileAnimation);

    // a simple header + collapsible body, instead of `ExpansionPanelList`, which does not size well inside a popup menu
    // (it left a big empty area, tinted by the translucent glass menu surface)
    Widget child = ValueListenableBuilder<String?>(
      valueListenable: expandedNotifier,
      builder: (context, expandedValue, _) {
        final expanded = expandedValue == widget.value;
        return Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            InkWell(
              onTap: () => expandedNotifier.value = expanded ? null : widget.value,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: widget.height),
                child: DefaultTextStyle(
                  style: style,
                  child: IconTheme.merge(
                    data: IconThemeData(
                      color: widget.enabled ? null : Theme.of(context).disabledColor,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisSize: .min,
                        mainAxisAlignment: .spaceBetween,
                        children: [
                          MenuRow(
                            text: widget.title,
                            icon: Icon(widget.icon),
                          ),
                          const SizedBox(width: 12),
                          AnimatedRotation(
                            turns: expanded ? .5 : 0,
                            duration: animationDuration,
                            child: const Icon(Icons.expand_more),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: animationDuration,
              curve: Curves.easeInOutCubic,
              alignment: AlignmentDirectional.topStart,
              child: expanded
                  ? Column(
                      mainAxisSize: .min,
                      crossAxisAlignment: .start,
                      children: [
                        const PopupMenuDivider(height: 0),
                        ...widget.items,
                        const PopupMenuDivider(height: 0),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
    if (!widget.enabled) {
      child = IgnorePointer(child: child);
    }
    return child;
  }
}
