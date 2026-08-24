import 'package:flutter/material.dart';

/// A widget that constrains content to a maximum width and centers it on wider screens (Web/Tablet).
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 1400.0,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    EdgeInsetsGeometry effectivePadding = padding ?? EdgeInsets.zero;
    if (padding == null && screenWidth > 600) {
      effectivePadding = EdgeInsets.symmetric(
        horizontal: screenWidth > 1200 ? 32.0 : (screenWidth > 600 ? 20.0 : 16.0),
      );
    }

    return Container(
      color: backgroundColor,
      alignment: Alignment.topCenter,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(padding: effectivePadding, child: child),
        ),
      ),
    );
  }
}

/// Helper extensions to check breakpoints and responsive grid counts in screens.
extension ResponsiveBreakpoints on BuildContext {
  bool get isMobile => MediaQuery.of(this).size.width < 600;
  bool get isTablet =>
      MediaQuery.of(this).size.width >= 600 &&
      MediaQuery.of(this).size.width < 1024;
  bool get isDesktop => MediaQuery.of(this).size.width >= 1024;
  bool get isWideDesktop => MediaQuery.of(this).size.width >= 1400;

  int get marketplaceGridCount {
    final width = MediaQuery.of(this).size.width;
    if (width >= 1400) return 4;
    if (width >= 1024) return 3;
    if (width >= 650) return 2;
    return 1;
  }

  int get formColumnCount {
    final width = MediaQuery.of(this).size.width;
    if (width >= 1024) return 2;
    return 1;
  }

  int get responsiveGridCount {
    final width = MediaQuery.of(this).size.width;
    if (width >= 1400) return 4;
    if (width >= 1024) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  int get responsiveCategoryGridCount {
    final width = MediaQuery.of(this).size.width;
    if (width >= 1024) return 6;
    if (width >= 600) return 4;
    return 3;
  }
}
