import 'package:flutter/material.dart';
import '../core/utils/responsive_utils.dart';

/// Responsive layout for settings and list views
class ResponsiveSettingsLayout extends StatelessWidget {
  final List<Widget> children;
  final String? title;
  final EdgeInsets? padding;
  final bool enableHorizontalScroll;
  final CrossAxisAlignment crossAxisAlignment;

  const ResponsiveSettingsLayout({
    Key? key,
    required this.children,
    this.title,
    this.padding,
    this.enableHorizontalScroll = false,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(context),
      tablet: _buildTabletLayout(context),
      desktop: _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    if (enableHorizontalScroll) {
      return _buildHorizontalScrollableLayout(context);
    }

    return SingleChildScrollView(
      padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          if (title != null) _buildTitle(context),
          ...children.map((child) => Padding(
                padding: EdgeInsets.only(
                  bottom: ResponsiveUtils.getSpacing(context),
                ),
                child: child,
              )),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveUtils.getResponsiveWidth(context),
          ),
          child: Column(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              if (title != null) _buildTitle(context),
              _buildGridLayout(context, 2), // 2 columns for tablet
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveUtils.getResponsiveWidth(context),
          ),
          child: Column(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              if (title != null) _buildTitle(context),
              _buildGridLayout(context, 3), // 3 columns for desktop
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalScrollableLayout(BuildContext context) {
    return Column(
      children: [
        if (title != null) _buildTitle(context),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children
                    .map((child) => Padding(
                          padding: EdgeInsets.only(
                            right: ResponsiveUtils.getSpacing(context),
                          ),
                          child: SizedBox(
                            width: 300, // Fixed width for horizontal cards
                            child: child,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridLayout(BuildContext context, int columns) {
    final spacing = ResponsiveUtils.getSpacing(context);

    // Group children into rows
    List<Widget> rows = [];
    for (int i = 0; i < children.length; i += columns) {
      final rowChildren = children.skip(i).take(columns).toList();

      // Fill remaining slots with empty containers if needed
      while (rowChildren.length < columns) {
        rowChildren.add(const SizedBox.shrink());
      }

      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowChildren
                .map((child) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: rowChildren.indexOf(child) <
                                  rowChildren.length - 1
                              ? spacing
                              : 0,
                        ),
                        child: child,
                      ),
                    ))
                .toList(),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: rows,
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveUtils.getSpacing(context,
            mobile: 16, tablet: 20, desktop: 24),
      ),
      child: Text(
        title!,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 24),
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

/// Responsive card widget that adapts to screen size
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Color? color;
  final VoidCallback? onTap;

  const ResponsiveCard({
    Key? key,
    required this.child,
    this.padding,
    this.elevation,
    this.borderRadius,
    this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ??
        EdgeInsets.all(
          ResponsiveUtils.getSpacing(context,
              mobile: 12, tablet: 16, desktop: 20),
        );

    final responsiveElevation =
        elevation ?? (ResponsiveUtils.isMobile(context) ? 2.0 : 4.0);

    return Card(
      elevation: responsiveElevation,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ??
            BorderRadius.circular(
              ResponsiveUtils.getSpacing(context,
                  mobile: 8, tablet: 12, desktop: 16),
            ),
      ),
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ??
            BorderRadius.circular(
              ResponsiveUtils.getSpacing(context,
                  mobile: 8, tablet: 12, desktop: 16),
            ),
        child: Padding(
          padding: responsivePadding,
          child: child,
        ),
      ),
    );
  }
}

/// Responsive list tile that adapts content based on screen size
class ResponsiveListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;

  const ResponsiveListTile({
    Key? key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.dense = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isMobile(context)) {
      return ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        dense: dense,
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getSpacing(context),
          vertical: ResponsiveUtils.getSpacing(context,
              mobile: 4, tablet: 6, desktop: 8),
        ),
      );
    }

    // For tablet and desktop, use more spacious layout
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getSpacing(context),
        vertical: ResponsiveUtils.getSpacing(context,
            mobile: 8, tablet: 12, desktop: 16),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(width: ResponsiveUtils.getSpacing(context)),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontSize:
                            ResponsiveUtils.getResponsiveFontSize(context, 16),
                      ),
                  child: title,
                ),
                if (subtitle != null) ...[
                  SizedBox(
                      height: ResponsiveUtils.getSpacing(context,
                          mobile: 2, tablet: 4, desktop: 6)),
                  DefaultTextStyle(
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context, 14),
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                    child: subtitle!,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: ResponsiveUtils.getSpacing(context)),
            trailing!,
          ],
        ],
      ),
    );
  }
}
