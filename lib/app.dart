import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/conversation_screen.dart';
import 'theme/tricorder_theme.dart';

/// Main application widget.
///
/// Sets up:
/// - Material 3 theming with dark/light mode
/// - Navigation routes
/// - Global error handling
class ComputerAssistantApp extends StatelessWidget {
  const ComputerAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'Computer',
          debugShowCheckedModeBanner: false,

          // Theme configuration - Retro-Futuristic Scientific inspired
          theme:
              TricorderTheme.darkTheme(), // Use retro-futuristic for both modes
          darkTheme: TricorderTheme.darkTheme(),
          themeMode: ThemeMode.dark, // Always use dark mode for vintage look

          // Navigation routes
          initialRoute: '/',
          routes: {
            '/': (context) => const HomeScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/conversation': (context) => const ConversationScreen(),
          },

          // Global error widget
          builder: (context, child) {
            // Add global error boundary
            ErrorWidget.builder = (FlutterErrorDetails details) {
              return _ErrorDisplay(details: details);
            };
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }

  /// Light theme - clean and professional
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6B9BD2), // LCARS-inspired blue
        brightness: Brightness.light,
      ),
      // Card styling
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      // AppBar styling
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      // Button styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Dark theme - Star Trek LCARS inspired
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF9900), // LCARS orange
        brightness: Brightness.dark,
        surface: const Color(0xFF1A1A2E),
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F0F1A),
      // Card styling - LCARS rounded rectangles
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Color(0xFF3D3D5C),
            width: 1,
          ),
        ),
      ),
      // AppBar styling
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      // Button styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      // Text styling
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        bodyLarge: TextStyle(
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Error display widget for unhandled exceptions
class _ErrorDisplay extends StatelessWidget {
  final FlutterErrorDetails details;

  const _ErrorDisplay({required this.details});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.red.shade900,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            details.exceptionAsString(),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
