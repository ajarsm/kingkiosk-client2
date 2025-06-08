import 'package:flutter/material.dart';
import '../core/utils/responsive_utils.dart';

/// Responsive app bar that handles action overflow gracefully
class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<ResponsiveAction>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final double? elevation;
  final PreferredSizeWidget? bottom;

  const ResponsiveAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.elevation,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      elevation: elevation,
      bottom: bottom,
      actions: _buildResponsiveActions(context),
    );
  }

  List<Widget>? _buildResponsiveActions(BuildContext context) {
    if (actions == null || actions!.isEmpty) return null;

    final maxActions = ResponsiveUtils.getMaxAppBarActions(context);

    if (actions!.length <= maxActions) {
      // All actions fit, show them all
      return actions!.map((action) => action.build(context)).toList();
    }

    // Need overflow menu
    final visibleActions = actions!.take(maxActions - 1).toList();
    final overflowActions = actions!.skip(maxActions - 1).toList();

    return [
      ...visibleActions.map((action) => action.build(context)),
      _buildOverflowMenu(context, overflowActions),
    ];
  }

  Widget _buildOverflowMenu(
      BuildContext context, List<ResponsiveAction> overflowActions) {
    return PopupMenuButton<int>(
      icon: Icon(ResponsiveUtils.isMobile(context)
          ? Icons.more_vert
          : Icons.more_horiz),
      tooltip: 'More options',
      itemBuilder: (context) => overflowActions
          .asMap()
          .entries
          .map((entry) => PopupMenuItem<int>(
                value: entry.key,
                child: ListTile(
                  leading: entry.value.icon,
                  title: Text(entry.value.label),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ))
          .toList(),
      onSelected: (index) {
        if (overflowActions[index].onPressed != null) {
          overflowActions[index].onPressed!();
        }
      },
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}

/// Action item for responsive app bar
class ResponsiveAction {
  final Icon icon;
  final String label;
  final String? tooltip;
  final VoidCallback? onPressed;
  final bool showLabelOnDesktop;

  const ResponsiveAction({
    required this.icon,
    required this.label,
    this.tooltip,
    this.onPressed,
    this.showLabelOnDesktop = false,
  });

  Widget build(BuildContext context) {
    if (ResponsiveUtils.isDesktop(context) && showLabelOnDesktop) {
      return TextButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        ),
      );
    }

    return IconButton(
      onPressed: onPressed,
      icon: icon,
      tooltip: tooltip ?? label,
    );
  }
}
