import 'package:flutter/material.dart';

import 'package:smartbank/core/theme/app_theme.dart';

enum LayoutKind { mobile, tablet, desktop }

LayoutKind layoutFor(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < AppSpacing.mobileBreakpoint) return LayoutKind.mobile;
  if (width < AppSpacing.railBreakpoint) return LayoutKind.tablet;
  return LayoutKind.desktop;
}

/// Centres content and caps its width so the same page reads well on a phone
/// and on a desktop browser.
class ContentContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ContentContainer({
    super.key,
    required this.child,
    this.maxWidth = AppSpacing.contentMaxWidth,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Two columns on wide screens, one column below the breakpoint.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minColumnWidth;
  final double spacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minColumnWidth = 320,
    this.spacing = AppSpacing.md,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - AppSpacing.lg * 2;
    final columns = (width / minColumnWidth).floor().clamp(1, 4);

    if (columns == 1) {
      return Column(
        children: [
          for (final child in children)
            Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: child,
            ),
        ],
      );
    }

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final child in children)
          SizedBox(
            width: (width - spacing * (columns - 1)) / columns,
            child: child,
          ),
      ],
    );
  }
}
