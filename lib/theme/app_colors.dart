import 'package:flutter/material.dart';

/// RΛVE theme — dark base with neon rainbow accents (cyan, magenta, pink, orange)
class AppColors {
  // Background — deep dark
  static const Color background = Color(0xFF0A0A0C);
  static const Color backgroundElevated = Color(0xFF0F0F12);

  // Surfaces — dark panels
  static const Color surface = Color(0xFF141418);
  static const Color surfaceVariant = Color(0xFF1A1A1F);
  static const Color surfaceLight = Color(0xFF222228);

  // Glass — frosted overlay
  static const Color glassWhite = Color(0x0DFFFFFF);
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color glassHighlight = Color(0x08FFFFFF);

  // Neon accents (from RΛVE logo: cyan headband, magenta–orange ear cups, rainbow hair)
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonMagenta = Color(0xFFE040FB);
  static const Color neonPink = Color(0xFFFF4081);
  static const Color neonOrange = Color(0xFFFF6D00);
  static const Color neonPurple = Color(0xFF7C4DFF);
  static const Color neonGreen = Color(0xFF69F0AE);

  // Brandy — warm amber/tan accent
  static const Color brandy = Color(0xFFD4A574);
  static const Color brandyLight = Color(0xFFE8C9A0);
  static const Color brandyDark = Color(0xFFA67C52);

  // Primary accent — brandy
  static const Color accent = brandy;
  static const Color accentSecondary = brandyLight;
  static const Color accentTertiary = brandyDark;
  static const Color accentHover = brandyLight;

  // Text — blueish tint (like mini player)
  static const Color textPrimary = Color(0xFFD4EEFF);
  static const Color textSecondary = Color(0xFF8BB8D4);
  static const Color textTertiary = Color(0xFF6B9BB8);

  // Borders
  static const Color border = Color(0xFF2A2A2E);
  static const Color borderLight = Color(0xFF36363C);

  // Navigation
  static const Color navBackground = Color(0xFF0A0A0C);
  static const Color navActive = brandy;
  static const Color navInactive = textTertiary;

  // Legacy aliases
  static const Color deepPurple = background;
  static const Color surfaceDark = surface;
  static const Color violetMid = surfaceVariant;
}
