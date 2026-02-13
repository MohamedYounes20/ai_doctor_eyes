import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/health_condition.dart';
import '../services/preferences_service.dart';
import 'selection_screen.dart';

/// Settings Screen: Vibration toggle, Voice Feedback toggle (TTS placeholder).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _prefs = PreferencesService();
  List<HealthCondition> _currentConditions = [];
  bool _vibrationEnabled = true;
  bool _voiceFeedbackEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final conditions = await _prefs.getHealthConditions();
    final vib = await _prefs.isVibrationEnabled();
    final voice = await _prefs.isVoiceFeedbackEnabled();
    if (mounted) {
      setState(() {
        _currentConditions = conditions;
        _vibrationEnabled = vib;
        _voiceFeedbackEnabled = voice;
        _loading = false;
      });
    }
  }

  Future<void> _setVibration(bool value) async {
    await _prefs.setVibrationEnabled(value);
    if (mounted) setState(() => _vibrationEnabled = value);
  }

  Future<void> _setVoiceFeedback(bool value) async {
    await _prefs.setVoiceFeedbackEnabled(value);
    if (mounted) setState(() => _voiceFeedbackEnabled = value);
    // TTS placeholder - will use flutter_tts when implemented
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Accessibility',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _SettingsTile(
                    icon: Icons.vibration,
                    title: 'Vibration Alerts',
                    subtitle: 'Alert you with vibration',
                    value: _vibrationEnabled,
                    onChanged: _setVibration,
                  ),
                  const Divider(),
                  _SettingsTile(
                    icon: Icons.visibility,
                    title: 'High Contrast Mode',
                    subtitle: 'Increase color contrast',
                    value: false,
                    onChanged: (_) {},
                  ),
                  const Divider(),
                  _SettingsTile(
                    icon: Icons.volume_up,
                    title: 'Voice Feedback',
                    subtitle: 'Hear scan results aloud',
                    value: _voiceFeedbackEnabled,
                    onChanged: _setVoiceFeedback,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Health Condition',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    color: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.medical_services, color: AppTheme.primaryColor),
                      title: Text(
                        _currentConditions.isEmpty
                            ? 'None'
                            : _currentConditions.map((c) => c.displayName).join(', '),
                        style: const TextStyle(
                          fontSize: AppTheme.bodyFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _currentConditions.isEmpty
                            ? 'Select conditions'
                            : '${_currentConditions.length} condition(s) selected',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SelectionScreen(isUpdateMode: true),
                          ),
                        );
                        _load();
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppTheme.bodyFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }
}
