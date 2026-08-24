import 'package:flutter/material.dart';

/// Helper class for responsive screen sizing and layout breakpoints across Web, Mobile, and Tablet.
class ResponsiveLayout {
  static const double mobileMax = 600.0;
  static const double tabletMax = 950.0;
  static const double desktopMax = 1200.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMax;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileMax &&
      MediaQuery.of(context).size.width < tabletMax;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletMax;

  /// Returns responsive crossAxisCount for grid views based on available width
  static int getGridCrossAxisCount(
    BuildContext context, {
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= tabletMax) return desktop;
    if (width >= mobileMax) return tablet;
    return mobile;
  }

  /// Returns responsive grid child aspect ratio based on width
  static double getGridAspectRatio(
    BuildContext context, {
    double mobile = 0.65,
    double tablet = 0.72,
    double desktop = 0.78,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= tabletMax) return desktop;
    if (width >= mobileMax) return tablet;
    return mobile;
  }
}
