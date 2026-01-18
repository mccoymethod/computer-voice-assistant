import 'package:flutter/material.dart';

/// Retro-Futuristic Scientific Theme
///
/// A vintage scientific instrument aesthetic with:
/// - Curved edges and pill-shaped buttons
/// - Bold, chunky UI elements
/// - Amber/copper accents (classic laboratory instruments)
/// - Black/charcoal backgrounds
/// - Segmented panels with rounded corners
/// - Technical display styling
class TricorderTheme {
  // ============================================
  // Color Palette
  // ============================================

  // Primary colors (Amber/Copper - vintage scientific instruments)
  static const Color primaryAmber = Color(0xFFFFAA00);
  static const Color primaryCopper = Color(0xFFDD8844);

  // Accent colors (vintage electronics/oscilloscopes)
  static const Color accentCyan = Color(0xFF00CCCC);
  static const Color accentViolet = Color(0xFFAA88FF);
  static const Color accentCoral = Color(0xFFFF7755);
  static const Color accentMint = Color(0xFF77DD99);

  // Background colors
  static const Color backgroundDark = Color(0xFF000000);
  static const Color backgroundPanel = Color(0xFF1A1A2E);
  static const Color backgroundCard = Color(0xFF2A2A3E);

  // Border/divider colors
  static const Color borderColor = Color(0xFF3D3D5C);
  static const Color dividerColor = Color(0xFF2D2D4C);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color textTertiary = Color(0xFF808090);

  // Status colors
  static const Color statusActive = primaryAmber;
  static const Color statusListening = accentCyan;
  static const Color statusThinking = accentViolet;
  static const Color statusSpeaking = accentMint;
  static const Color statusError = accentCoral;
  static const Color statusIdle = Color(0xFF505060);

  // ============================================
  // Border Radius
  // ============================================

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusPill = 100.0;

  // ============================================
  // Spacing
  // ============================================

  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  // ============================================
  // Theme Data
  // ============================================

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryAmber,
        secondary: primaryCopper,
        surface: backgroundPanel,
        onSurface: textPrimary,
        error: accentCoral,
        tertiary: accentCyan,
      ),

      scaffoldBackgroundColor: backgroundDark,

      // Card theme - rounded panels
      cardTheme: CardThemeData(
        elevation: 0,
        color: backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(spacingM),
      ),

      // AppBar theme - transparent with orange accent
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: primaryAmber,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAmber,
          foregroundColor: backgroundDark,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryAmber,
          side: const BorderSide(color: primaryAmber, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryAmber,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingM,
            vertical: spacingS,
          ),
        ),
      ),

      // FAB theme - pill-shaped
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryAmber,
        foregroundColor: backgroundDark,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusPill)),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryAmber, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textTertiary),
      ),

      // Text theme - monospace for technical feel
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: primaryAmber,
          letterSpacing: 2.0,
        ),
        displayMedium: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: primaryAmber,
          letterSpacing: 1.5,
        ),
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 1.0,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 1.0,
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: primaryAmber,
        size: 24,
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: spacingM,
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryAmber,
      ),
    );
  }

  // ============================================
  // Custom Widgets
  // ============================================

  /// Scientific panel with amber accent bar
  static Widget panel({
    required Widget child,
    Color? accentColor,
    EdgeInsets? padding,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundCard,
        borderRadius: BorderRadius.circular(radiusMedium),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Accent bar at top
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: accentColor ?? primaryAmber,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(radiusMedium),
                topRight: Radius.circular(radiusMedium),
              ),
            ),
          ),
          Padding(
            padding: padding ?? const EdgeInsets.all(spacingM),
            child: child,
          ),
        ],
      ),
    );
  }

  /// Status indicator pill
  static Widget statusPill({
    required String label,
    required Color color,
    bool isActive = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: spacingM,
        vertical: spacingS,
      ),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.2) : Colors.transparent,
        border: Border.all(
          color: color,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? color : color.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: spacingS),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  /// Data readout display (monospace technical text)
  static Widget dataReadout({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: textSecondary,
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? primaryAmber,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
