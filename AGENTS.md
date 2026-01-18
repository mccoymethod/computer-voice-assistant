# Agent Guidelines for Computer Voice Assistant

This document provides essential guidelines for AI coding agents working on this Flutter/Dart project.

## Project Overview

**Name**: Computer Voice Assistant  
**Framework**: Flutter (Dart)  
**Target Platform**: Android  
**Architecture**: Provider-based state management with service layer  
**Purpose**: Retro-futuristic voice assistant with local STT/TTS and LLM integration

## Build, Test & Run Commands

### Development
```bash
# Get dependencies
flutter pub get

# Run app (debug mode)
flutter run

# Run on specific device
flutter devices
flutter run -d <device-id>

# Hot reload: Press 'r' in terminal
# Hot restart: Press 'R' in terminal
```

### Build
```bash
# Build APK (debug)
flutter build apk --debug

# Build APK (release)
flutter build apk --release

# Build app bundle
flutter build appbundle --release
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/conversation_test.dart

# Run with coverage
flutter test --coverage
```

### Code Quality
```bash
# Analyze code (linting)
flutter analyze

# Format code
flutter format lib/ test/

# Check formatting without changes
flutter format --set-exit-if-changed lib/ test/
```

### Dependency Management
```bash
# Update dependencies
flutter pub upgrade

# Get dependencies after pubspec.yaml changes
flutter pub get

# Clean build artifacts
flutter clean
```

## Code Style Guidelines

### Imports
- Group imports in order: Flutter SDK, third-party packages, local files
- Use relative imports for local files (`import '../models/conversation.dart'`)
- Separate import groups with blank lines
- Sort imports alphabetically within each group

Example:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

import '../models/conversation.dart';
import '../services/llm_service.dart';
```

### Formatting
- Use 2 spaces for indentation (not tabs)
- Line length: 80 characters (soft limit, 100 max)
- Trailing commas on all parameter lists and collection literals (enables better formatting)
- Always use curly braces for control flow statements

### Types
- **Always** specify types explicitly - avoid `var` except for obvious cases
- Use `final` for variables that won't be reassigned
- Use `const` for compile-time constants
- Prefer explicit return types on functions/methods
- Use nullable types (`Type?`) appropriately, not `Type!`

Example:
```dart
// Good
final String userName = 'Computer';
const int maxRetries = 3;
List<Message> _messages = [];

// Avoid
var userName = 'Computer';  // Type not explicit
List _messages = [];         // Missing type parameter
```

### Naming Conventions
- **Classes/Enums**: PascalCase (`ClaudeService`, `MessageRole`)
- **Functions/Variables**: camelCase (`sendMessage`, `apiKey`)
- **Private members**: prefix with underscore (`_apiKey`, `_handleError`)
- **Constants**: camelCase with const/final (`maxRetries`, `defaultTimeout`)
- **Files**: snake_case (`llm_service.dart`, `assistant_provider.dart`)

### Documentation
- Use `///` for public API documentation (shows in IDE tooltips)
- Use `//` for internal comments
- Document all public classes, methods, and complex logic
- Include parameter descriptions and return values where helpful

Example:
```dart
/// Sends a message to the configured LLM provider.
/// 
/// Returns an [LLMResponse] with the generated text and token usage.
/// Throws [LLMException] if the request fails.
Future<LLMResponse> sendMessage({
  required List<Message> messages,
  required LLMModelConfig modelConfig,
}) async {
  // Implementation
}
```

### Error Handling
- Use custom exception classes (e.g., `LLMException`) not generic `Exception`
- Always catch specific exceptions before generic ones
- Include retry logic for transient failures (network, rate limits)
- Log errors with context using the `logger` package
- Never silently catch errors - log or rethrow

Example:
```dart
try {
  final response = await service.sendMessage(...);
  return response;
} on LLMException catch (e) {
  if (e.isRetryable) {
    // Queue for retry
    await _queueService.enqueue(request);
  } else {
    _logger.e('Non-retryable error: $e');
    rethrow;
  }
} on http.ClientException catch (e) {
  throw LLMException.networkError(provider);
}
```

### State Management
- Use Provider for dependency injection and state management
- Providers should extend `ChangeNotifier` for reactive updates
- Call `notifyListeners()` after state changes
- Use `Consumer` or `context.watch<T>()` in widgets for reactive UI
- Use `context.read<T>()` for one-time reads (like in button handlers)

### Async/Await
- Prefer `async`/`await` over raw `Future.then()`
- Always add `async` marker when using `await`
- Use `Future.wait()` for parallel operations
- Handle loading states explicitly in UI

### Models & Data Classes
- Use immutable models where possible (final fields)
- Implement `toJson()` and `fromJson()` for serialization
- Use factory constructors for named alternatives (`Message.user()`)
- Include `copyWith()` methods for partial updates

## Architecture Patterns

### Service Layer
- Services handle external communication (HTTP, databases, etc.)
- Services should be stateless or use minimal internal state
- Inject services via Provider
- Services throw exceptions; providers handle them

### Provider Layer
- Providers coordinate between services and UI
- Providers manage application state
- Providers transform service exceptions into user-friendly messages
- Providers notify listeners on state changes

### UI Layer
- Screens/widgets consume providers via `Consumer` or `context.watch()`
- Keep widgets focused and composable
- Extract reusable components into separate widget classes
- Separate stateless from stateful widgets appropriately

## File Organization

```
lib/
├── main.dart              # App entry point
├── app.dart               # Root app widget, routing, theming
├── models/                # Data classes, enums
├── providers/             # State management (ChangeNotifiers)
├── screens/               # Full-screen UI pages
├── widgets/               # Reusable UI components (not yet created)
└── services/              # External integrations, business logic
    ├── queue_service.dart
    └── llm/               # LLM provider implementations
```

## Key Dependencies

- `provider` - State management
- `sherpa_onnx` - On-device STT/TTS/wake word (not yet integrated)
- `http` / `dio` - HTTP clients for API calls
- `sqflite` - SQLite for offline queue
- `hive` - Fast key-value storage for settings
- `logger` - Logging
- `flutter_dotenv` - Environment variables (.env file)

## Testing Guidelines

- Write unit tests for models and service logic
- Use `mockito` or `mocktail` for mocking dependencies
- Test providers with `ChangeNotifierProvider` and `ProviderScope`
- Test widgets with `WidgetTester` and `testWidgets()`
- Place tests in `test/` directory mirroring `lib/` structure

## Environment Setup

1. Copy `.env.example` to `.env` and add API keys
2. Never commit `.env` file (already in .gitignore)
3. API keys can also be configured in-app (Settings screen)

## Important Notes

- **User Profile**: Junior Flutter developer - provide clear explanations
- **Voice Components**: STT, TTS, wake word are NOT yet implemented (Sherpa-ONNX integration pending)
- **Current State**: LLM integration, offline queue, and UI scaffold are complete
- **Privacy**: All voice processing will be on-device (local models)
- **Offline Support**: Queue service handles requests when offline
- **Multi-Provider**: Support Claude, OpenAI, and Gemini APIs

## Common Tasks

### Adding a new LLM provider
1. Create service in `lib/services/llm/` implementing `LLMService`
2. Add enum value to `LLMProvider` in `lib/models/llm_provider.dart`
3. Add model configs to `LLMModels` class
4. Register service in `AssistantProvider._initializeLLMServices()`

### Adding a new screen
1. Create file in `lib/screens/`
2. Add route in `lib/app.dart`
3. Use `Scaffold` as root widget
4. Consume providers via `Consumer` or `context.watch()`

### Modifying conversation logic
- Start in `AssistantProvider` (main coordinator)
- Services handle API calls, provider handles state transitions
- Update `AssistantState` enum if adding new states

## References

- See `AGENT_HANDOFF.md` for detailed project context and architecture
- See `TODO.md` for remaining implementation tasks (voice components)
- Flutter docs: https://docs.flutter.dev
- Dart docs: https://dart.dev/guides
