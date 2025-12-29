import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  // Responsive padding
  static double getPadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    return 32.0;
  }

  // Responsive font size
  static double getFontSize(BuildContext context, double baseFontSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return baseFontSize * 0.85; // Small phones
    if (width < 375) return baseFontSize * 0.9;  // Medium phones
    if (width < 414) return baseFontSize;        // Large phones
    return baseFontSize * 1.1;                   // Tablets and larger
  }

  // Responsive spacing
  static double getSpacing(BuildContext context, double baseSpacing) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return baseSpacing * 0.8;
    if (width < 375) return baseSpacing * 0.9;
    return baseSpacing;
  }

  // Responsive icon size
  static double getIconSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return baseSize * 0.85;
    if (width < 375) return baseSize * 0.9;
    return baseSize;
  }

  // Get responsive width percentage
  static double getWidth(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }

  // Get responsive height percentage
  static double getHeight(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * percentage;
  }

  // Get max width for content (prevents stretching on tablets)
  static double getMaxContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) return 600; // Max width for tablets
    return width;
  }

  // Responsive grid columns
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 1;
    if (width < 600) return 2;
    if (width < 900) return 3;
    return 4;
  }
}
