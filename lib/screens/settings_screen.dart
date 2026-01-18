import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../models/llm_provider.dart';

/// Settings screen for configuring the assistant
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            children: [
              // Theme section
              _buildSectionHeader(context, 'Appearance'),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Theme'),
                trailing: DropdownButton<ThemeMode>(
                  value: settings.themeMode,
                  onChanged: (mode) {
                    if (mode != null) settings.setThemeMode(mode);
                  },
                  items: const [
                    DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                    DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                  ],
                ),
              ),

              // LLM section
              _buildSectionHeader(context, 'AI Provider'),
              ListTile(
                leading: const Icon(Icons.smart_toy),
                title: const Text('Default Provider'),
                trailing: DropdownButton<LLMProvider>(
                  value: settings.defaultProvider,
                  onChanged: (provider) {
                    if (provider != null) settings.setDefaultProvider(provider);
                  },
                  items: LLMProvider.values.map((p) {
                    final configured = settings.hasApiKey(p);
                    return DropdownMenuItem(
                      value: p,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(p.displayName),
                          if (!configured)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.warning, size: 16, color: Colors.orange),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              // API Keys section
              _buildSectionHeader(context, 'API Keys'),
              ...LLMProvider.values.map((provider) => _buildApiKeyTile(
                context,
                settings,
                provider,
              )),

              // Voice section
              _buildSectionHeader(context, 'Voice'),
              ListTile(
                leading: const Icon(Icons.hearing),
                title: const Text('Wake Word Sensitivity'),
                subtitle: Slider(
                  value: settings.wakeWordSensitivity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label: '${(settings.wakeWordSensitivity * 100).round()}%',
                  onChanged: (value) => settings.setWakeWordSensitivity(value),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.speed),
                title: const Text('Speech Speed'),
                subtitle: Slider(
                  value: settings.ttsSpeakingRate,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: '${settings.ttsSpeakingRate.toStringAsFixed(1)}x',
                  onChanged: (value) => settings.setTtsSpeakingRate(value),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.volume_up),
                title: const Text('Auto-play Responses'),
                value: settings.autoPlayTts,
                onChanged: (value) => settings.setAutoPlayTts(value),
              ),

              // STT Model section
              _buildSectionHeader(context, 'Speech Recognition'),
              ListTile(
                leading: const Icon(Icons.memory),
                title: const Text('Model Size'),
                subtitle: const Text('Larger = more accurate, slower'),
                trailing: DropdownButton<String>(
                  value: settings.sttModelSize,
                  onChanged: (size) {
                    if (size != null) settings.setSttModelSize(size);
                  },
                  items: const [
                    DropdownMenuItem(value: 'tiny', child: Text('Tiny (fastest)')),
                    DropdownMenuItem(value: 'small', child: Text('Small (balanced)')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium (accurate)')),
                  ],
                ),
              ),

              // About section
              _buildSectionHeader(context, 'About'),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Reset to Defaults'),
                onTap: () => _confirmReset(context, settings),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildApiKeyTile(
    BuildContext context,
    SettingsProvider settings,
    LLMProvider provider,
  ) {
    final hasKey = settings.hasApiKey(provider);
    
    return ListTile(
      leading: Icon(
        hasKey ? Icons.check_circle : Icons.circle_outlined,
        color: hasKey ? Colors.green : null,
      ),
      title: Text(provider.displayName),
      subtitle: Text(hasKey ? 'Configured' : 'Not configured'),
      trailing: const Icon(Icons.edit),
      onTap: () => _showApiKeyDialog(context, settings, provider),
    );
  }

  void _showApiKeyDialog(
    BuildContext context,
    SettingsProvider settings,
    LLMProvider provider,
  ) {
    final controller = TextEditingController(
      text: settings.getApiKey(provider) ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${provider.displayName} API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your ${provider.displayName} API key.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: provider.envKeyName,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              settings.setApiKey(provider, controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings?'),
        content: const Text(
          'This will reset all settings to their defaults. API keys will be cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              settings.resetToDefaults();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
