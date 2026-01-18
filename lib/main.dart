import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'providers/assistant_provider.dart';
import 'providers/settings_provider.dart';
import 'services/queue_service.dart';
import 'services/memory_service.dart';
import 'services/model_lifecycle_service.dart';
import 'services/conversation_archive_service.dart';

/// Main entry point for the Computer Voice Assistant app.
///
/// Initialization order:
/// 1. Flutter bindings
/// 2. Environment variables (.env file)
/// 3. Hive (local storage)
/// 4. Offline queue database
/// 5. Run app with providers
void main() async {
  // Ensure Flutter is initialized before any async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait (optional, but voice apps often work better this way)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables from .env file
  // This contains API keys - NEVER commit .env to version control!
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // .env file might not exist yet - that's okay, user will configure in app
    debugPrint(
        'Warning: .env file not found. API keys must be configured in settings.');
  }

  // Initialize Hive for fast local storage (settings, cache)
  await Hive.initFlutter();

  // Initialize the offline request queue (SQLite)
  final queueService = QueueService();
  await queueService.initialize();

  // Initialize conversation archive service
  final archiveService = ConversationArchiveService();
  await archiveService.initialize();

  // Initialize memory service
  final memoryService = MemoryService();
  await memoryService.updateMemoryUsage();

  // Initialize model lifecycle service
  final modelLifecycleService = ModelLifecycleService(
    memoryService: memoryService,
  );

  // Run the app with all providers
  runApp(
    MultiProvider(
      providers: [
        // Settings provider - manages user preferences
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..initialize(),
        ),

        // Queue service - singleton for offline queue
        Provider<QueueService>.value(value: queueService),

        // Archive service - singleton for conversation storage
        Provider<ConversationArchiveService>.value(value: archiveService),

        // Memory service - for monitoring RAM usage
        ChangeNotifierProvider<MemoryService>.value(value: memoryService),

        // Model lifecycle service - for loading/unloading models
        ChangeNotifierProvider<ModelLifecycleService>.value(
          value: modelLifecycleService,
        ),

        // Main assistant provider - depends on all services
        ChangeNotifierProxyProvider5<
            SettingsProvider,
            QueueService,
            MemoryService,
            ModelLifecycleService,
            ConversationArchiveService,
            AssistantProvider>(
          create: (context) => AssistantProvider(
            settingsProvider: context.read<SettingsProvider>(),
            queueService: context.read<QueueService>(),
            memoryService: context.read<MemoryService>(),
            modelLifecycleService: context.read<ModelLifecycleService>(),
            archiveService: context.read<ConversationArchiveService>(),
          ),
          update: (context, settings, queue, memory, lifecycle, archive,
                  previous) =>
              previous ??
              AssistantProvider(
                settingsProvider: settings,
                queueService: queue,
                memoryService: memory,
                modelLifecycleService: lifecycle,
                archiveService: archive,
              ),
        ),
      ],
      child: const ComputerAssistantApp(),
    ),
  );
}
