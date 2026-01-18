# Authentication Implementation Plan

## Overview

This document outlines the phased approach for implementing authentication in the Computer Voice Assistant app.

## Research Findings

### What We Learned from OpenCode/Superset:

1. **Superset** uses OAuth for user accounts (GitHub/Google) but **NOT** for LLM provider authentication
2. **OpenCode** has Anthropic OAuth tokens but they're for OpenCode's service, not direct API access
3. **Anthropic API** doesn't support OAuth for public use yet (returns "OAuth authentication is currently not supported")
4. **All major LLM providers** (Claude, OpenAI, Gemini) require manual API keys for direct API access

### Decision: Phased Approach

**Phase 1**: Launch with secure API key storage and premium UX  
**Phase 2**: Add optional OAuth for cloud sync features (using our own backend)

---

## Phase 1: Secure API Key Storage (CURRENT)

### Goal
Get users up and running in 2 minutes with an excellent manual API key experience.

### What We're Building

#### 1. Secure Storage Service ✅ CREATED
**File**: `lib/services/secure_storage_service.dart`

Features:
- Encrypted storage using `flutter_secure_storage`
- Platform-specific secure storage (Keychain on iOS, EncryptedSharedPreferences on Android)
- API key validation and format detection
- Last tested timestamps
- Active provider management

Methods:
```dart
// Store/retrieve API keys
setApiKey(LLMProvider provider, String apiKey)
getApiKey(LLMProvider provider)
deleteApiKey(LLMProvider provider)
hasApiKey(LLMProvider provider)

// Provider management
getConfiguredProviders()
setActiveProvider(LLMProvider provider)
getActiveProvider()

// Validation
validateApiKeyFormat(LLMProvider provider, String apiKey)
detectProviderFromKey(String apiKey)

// Testing metadata
setLastTested(LLMProvider provider, DateTime timestamp)
getLastTested(LLMProvider provider)
```

#### 2. Onboarding Wizard (TODO)
**Files to Create**:
- `lib/screens/onboarding/welcome_screen.dart`
- `lib/screens/onboarding/provider_selection_screen.dart`
- `lib/screens/onboarding/api_key_input_screen.dart`
- `lib/screens/onboarding/api_key_test_screen.dart`
- `lib/screens/onboarding/onboarding_complete_screen.dart`

Flow:
```
1. Welcome Screen
   └─> Explain what the app does
   └─> "Get Started" button

2. Provider Selection
   └─> Choose Claude, OpenAI, or Gemini
   └─> Brief description of each
   └─> "Continue" button

3. API Key Input
   └─> Step-by-step guide with screenshots
   └─> Link to provider's API key page
   └─> Manual paste field
   └─> QR code scanner option (Phase 1.5)
   └─> Format validation in real-time

4. Test Connection
   └─> "Test Connection" button
   └─> Loading state with progress indicator
   └─> Success/error message
   └─> Retry option on failure

5. Complete
   └─> Celebration animation
   └─> "Start Using Computer" button
```

#### 3. Update Settings Provider (TODO)
**File**: `lib/providers/settings_provider.dart`

Changes needed:
- Remove Hive storage for API keys
- Integrate SecureStorageService
- Add methods to migrate existing keys (if any)

```dart
class SettingsProvider extends ChangeNotifier {
  final SecureStorageService _secureStorage;
  
  // Remove old _apiKeys map
  // Add methods:
  Future<void> setApiKey(LLMProvider provider, String key) async {
    await _secureStorage.setApiKey(provider, key);
    notifyListeners();
  }
  
  Future<String?> getApiKey(LLMProvider provider) async {
    return await _secureStorage.getApiKey(provider);
  }
  
  Future<bool> hasApiKey(LLMProvider provider) async {
    return await _secureStorage.hasApiKey(provider);
  }
}
```

#### 4. Update Settings Screen UI (TODO)
**File**: `lib/screens/settings_screen.dart`

Add sections:
- **API Key Management**
  - List of configured providers with status badges
  - "Last tested" timestamps
  - Edit/Delete buttons
  - "Add Provider" button
- **Model Configuration**
  - STT model size selection (tiny/small/medium)
  - Keep models loaded toggle
  - STT timeout setting
- **Memory Management**
  - Current RAM usage display
  - Model status (loaded/unloaded)

#### 5. API Key Testing Service (TODO)
**File**: `lib/services/api_key_test_service.dart`

Features:
- Test connection with minimal API call
- Validate key actually works (not just format)
- Return detailed error messages
- Update last tested timestamp on success

```dart
class ApiKeyTestService {
  Future<ApiKeyTestResult> testApiKey(
    LLMProvider provider,
    String apiKey,
  ) async {
    // Make minimal API call to test
    // Return success/failure with details
  }
}

class ApiKeyTestResult {
  final bool success;
  final String? errorMessage;
  final String? errorCode;
  final DateTime testedAt;
}
```

### Timeline: 2-3 Days

- Day 1: Onboarding wizard screens
- Day 2: Settings screen updates + API key testing
- Day 3: Polish, testing, bug fixes

---

## Phase 2: OAuth Backend (FUTURE)

### Goal
Provide optional cloud sync for users who want cross-device conversation history.

### Architecture Decision

**Option A: Firebase Auth** (Recommended for MVP)
- Pros: Quick setup, free tier, handles OAuth providers
- Cons: Vendor lock-in, limited customization

**Option B: Supabase**
- Pros: Open source, PostgreSQL backend, great free tier
- Cons: More setup than Firebase

**Option C: Custom Backend (Bun + Drizzle + Better Auth)**
- Pros: Full control, modeled after Superset
- Cons: Most complex, requires server maintenance

### What We'll Build

#### 1. Deep Link Handler
**File**: `lib/services/deep_link_service.dart`

Handle `computerapp://` protocol:
- OAuth callback: `computerapp://auth/callback?token=...&state=...`
- State validation (CSRF protection)
- Token extraction and storage

#### 2. OAuth Flow
```
1. User taps "Sign in to Sync"
2. App opens browser: https://yourbackend.com/auth/google
3. User signs in with Google/GitHub
4. Backend creates session + bearer token
5. Redirects to: computerapp://auth/callback?token=xxx
6. App catches deep link
7. App stores bearer token securely
8. App can now sync conversations
```

#### 3. Backend Services (If Custom)
- User authentication (Google/GitHub OAuth)
- Bearer token management
- Encrypted conversation storage
- API key backup (encrypted with user's password)

#### 4. Cloud Sync Features
- Auto-sync conversations on create/update
- Pull conversations from cloud on new device
- Conflict resolution (last-write-wins)
- Encrypted backup of API keys (optional)

### Timeline: 1-2 Weeks

- Week 1: Backend setup + deep link handling
- Week 2: Sync logic + testing

---

## Current Status

### ✅ Completed
1. Memory monitoring service
2. Model lifecycle manager
3. Conversation archive system
4. Secure API key storage service
5. Retro-futuristic theme (legally safe!)
6. Push-to-talk architecture
7. Updated AGENTS.md

### 🔄 In Progress
1. Phase 1 implementation (secure API keys)

### 📋 Next Steps
1. Run `flutter pub get` to install flutter_secure_storage
2. Create onboarding wizard screens
3. Update settings provider to use SecureStorageService
4. Create API key testing service
5. Update settings screen UI
6. Test on Android device

---

## Testing Checklist

### Phase 1 Testing
- [ ] API key storage encryption works
- [ ] Keys persist across app restarts
- [ ] Format validation catches invalid keys
- [ ] Provider auto-detection works
- [ ] Test connection validates keys correctly
- [ ] Onboarding flow is smooth
- [ ] Settings screen shows correct status
- [ ] Can switch between multiple providers
- [ ] Can delete and re-add keys
- [ ] Handles no internet gracefully

### Phase 2 Testing
- [ ] Deep link handling works on Android
- [ ] OAuth flow completes successfully
- [ ] Tokens are stored securely
- [ ] Conversations sync across devices
- [ ] Works offline (queued sync)
- [ ] Handles token expiration
- [ ] Can sign out and delete cloud data

---

## References

- Superset OAuth analysis: `~/.local/share/opencode/tool-output/superset-oauth-analysis.md`
- Flutter secure storage: https://pub.dev/packages/flutter_secure_storage
- Deep linking in Flutter: https://docs.flutter.dev/ui/navigation/deep-linking

---

## Notes

### Why Not Use Anthropic OAuth?
- Anthropic's API returns: "OAuth authentication is currently not supported"
- OpenCode's OAuth tokens authenticate with OpenCode's service, not Anthropic directly
- OpenCode proxies requests using their own API keys
- For direct API access, manual API keys are the only option

### Security Considerations
- Never log API keys (even in debug mode)
- Use flutter_secure_storage for all sensitive data
- Clear keys from memory after use
- Validate all user input
- Use HTTPS for all API calls
- Implement rate limiting to prevent abuse

### User Experience Priorities
1. Fast onboarding (< 2 minutes)
2. Clear error messages
3. One-tap test connection
4. Visual feedback for all actions
5. Helpful tooltips and guides
6. Graceful offline handling
