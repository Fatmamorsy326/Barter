import 'package:flutter/material.dart';

class ColorsManager {
  // Primary Purple Palette
  static const Color purple = Color(0xFF6C63FF);
  static const Color purpleLight = Color(0xFF9D97FF);
  static const Color purpleDark = Color(0xFF4B44B2);
  static const Color purpleAccent = Color(0xFF8B5CF6);
  static const Color purpleSoft = Color(0xFFE8E6FF);

  // Grey Palette
  static const Color grey = Color(0xFF757575);
  static const Color greyLight = Color(0xFFBDBDBD);
  static const Color greyDark = Color(0xFF424242);
  static const Color greyUltraLight = Color(0xFFF0F0F0);

  // Base Colors - Light Mode
  static const Color background = Color(0xFFF8F9FE);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF212121);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Dark Mode Colors - Refined for Premium Look
  // Using a very deep, rich dark blue-grey for background instead of flat black
  static const Color darkBackground = Color(0xFF0B0B15); 
  static const Color darkSurface = Color(0xFF151520);
  static const Color darkCard = Color(0xFF1E1E2C);
  static const Color darkElevated = Color(0xFF252535);
  
  static const Color darkText = Color(0xFFF0F0F5);
  static const Color darkTextSecondary = Color(0xFFA0A0B0);
  static const Color darkBorder = Color(0xFF2D2D3F);
  static const Color darkDivider = Color(0xFF252535);

  // Dark Mode Purple Accents - Adjusted to pop against the new background
  static const Color darkPurple = Color(0xFF7D73FF);
  static const Color darkPurpleSoft = Color(0xFF252240);
  static const Color darkPurpleAccent = Color(0xFF9D8BFA);

  // Dark Mode Gradients
  static const Color darkGradientStart = Color(0xFF5C53EF);
  static const Color darkGradientEnd = Color(0xFF7B5CF6);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Dark Status Colors
  static const Color darkSuccess = Color(0xFF34D399);
  static const Color darkError = Color(0xFFF87171);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkInfo = Color(0xFF60A5FA);

  // Gradient Colors
  static const Color gradientStart = Color(0xFF6C63FF);
  static const Color gradientEnd = Color(0xFF8B5CF6);
  static const Color gradientAccent = Color(0xFFA78BFA);
  
  // Shimmer Colors
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  
  // Dark Shimmer Colors
  static const Color darkShimmerBase = Color(0xFF252535);
  static const Color darkShimmerHighlight = Color(0xFF303045);

  // Shadow Color
  static const Color shadow = Color(0x1A6C63FF);
  static const Color shadowDark = Color(0x336C63FF);
  static const Color darkShadow = Color(0x40000000);

  // Helper method to get colors based on brightness
  static Color backgroundFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : background;
  }

  static Color cardFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCard
        : white;
  }

  static Color textFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkText
        : black;
  }

  static Color textSecondaryFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : grey;
  }

  static Color purpleSoftFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkPurpleSoft
        : purpleSoft;
  }

  static Color purpleFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkPurple
        : purple;
  }

  static Color dividerFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkDivider
        : greyUltraLight;
  }

  static Color surfaceFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : white;
  }

  static Color shadowFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkShadow
        : shadow;
  }

  static List<Color> gradientFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? [darkGradientStart, darkGradientEnd]
        : [gradientStart, gradientEnd];
  }

  static Color shimmerBaseFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkShimmerBase
        : shimmerBase;
  }

  static Color shimmerHighlightFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkShimmerHighlight
        : shimmerHighlight;
  }
}
