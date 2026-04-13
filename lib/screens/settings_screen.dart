import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../main.dart' show themeModeNotifier, selectedConditionsNotifier;
import '../models/health_condition.dart';
import '../services/preferences_service.dart';
import 'selection_screen.dart';

/// Settings Screen: Vibration toggle, Voice Feedback toggle, Dark Mode toggle.
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
      // Keep global notifier in sync so Profile screen updates instantly
      selectedConditionsNotifier.value =
          conditions.map((c) => c.displayName).toList();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.spaceBlack : AppTheme.icyWhite;
    final cardBg = isDark ? AppTheme.navyCard : Colors.white;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Appearance section
                  _SectionHeader(title: 'Appearance', isDark: isDark),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    isDark: isDark,
                    cardBg: cardBg,
                    child: Column(
                      children: [
                        ValueListenableBuilder<ThemeMode>(
                          valueListenable: themeModeNotifier,
                          builder: (_, mode, __) => _SettingsTile(
                            icon: mode == ThemeMode.dark
                                ? Icons.dark_mode
                                : Icons.light_mode_outlined,
                            title: 'Dark Mode',
                            subtitle: mode == ThemeMode.dark
                                ? 'Space-black theme active'
                                : 'Icy-white theme active',
                            value: mode == ThemeMode.dark,
                            onChanged: (v) {
                              themeModeNotifier.value =
                                  v ? ThemeMode.dark : ThemeMode.light;
                            },
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Accessibility section
                  _SectionHeader(title: 'Accessibility', isDark: isDark),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    isDark: isDark,
                    cardBg: cardBg,
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.vibration,
                          title: 'Vibration Alerts',
                          subtitle: 'Alert you with vibration',
                          value: _vibrationEnabled,
                          onChanged: _setVibration,
                          isDark: isDark,
                        ),
                        _Divider(isDark: isDark),
                        _SettingsTile(
                          icon: Icons.visibility_outlined,
                          title: 'High Contrast Mode',
                          subtitle: 'Increase colour contrast',
                          value: false,
                          onChanged: (_) {},
                          isDark: isDark,
                        ),
                        _Divider(isDark: isDark),
                        _SettingsTile(
                          icon: Icons.volume_up_outlined,
                          title: 'Voice Feedback',
                          subtitle: 'Hear scan results aloud',
                          value: _voiceFeedbackEnabled,
                          onChanged: _setVoiceFeedback,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Health Condition section
                  _SectionHeader(title: 'Health Condition', isDark: isDark),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    isDark: isDark,
                    cardBg: cardBg,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.medical_services_outlined,
                        color: isDark ? AppTheme.neonMint : AppTheme.navyColor,
                      ),
                      title: Text(
                        _currentConditions.isEmpty
                            ? 'None'
                            : _currentConditions
                                .map((c) => c.displayName)
                                .join(', '),
                        style: TextStyle(
                          fontSize: AppTheme.bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.navyColor,
                        ),
                      ),
                      subtitle: Text(
                        _currentConditions.isEmpty
                            ? 'Select conditions'
                            : '${_currentConditions.length} condition(s) selected',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.white.withOpacity(0.5)
                              : Colors.grey.shade600,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: isDark ? Colors.white38 : Colors.grey,
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const SelectionScreen(isUpdateMode: true),
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

// ── Reusable sub-widgets ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: isDark
            ? AppTheme.neonMint
            : AppTheme.navyColor.withOpacity(0.6),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final Color cardBg;
  const _SettingsCard(
      {required this.child, required this.isDark, required this.cardBg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.25)
                : AppTheme.navyColor.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.neonMint.withOpacity(0.1)
                  : AppTheme.navyColor.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isDark ? AppTheme.neonMint : AppTheme.navyColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTheme.bodyFontSize - 2,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.navyColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
