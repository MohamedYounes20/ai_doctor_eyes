import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../main.dart' show themeModeNotifier, selectedConditionsNotifier;
import '../models/health_condition.dart';
import '../services/preferences_service.dart';
import '../widgets/modern_header.dart';
import 'selection_screen.dart';

/// Settings tab — card-based layout matching the Profile screen aesthetic.
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
      // Keep global notifier in sync so Profile screen updates instantly.
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? AppTheme.neonMint : AppTheme.navyColor,
              ),
            )
          : CustomScrollView(
              slivers: [
                // ── Page header ─────────────────────────────────────────────
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 56, 20, 24),
                    child: ModernHeader(
                      firstWord: 'App',
                      secondWord: 'Settings',
                      hasLineBreak: false,
                    ),
                  ),
                ),

                // ── Appearance card ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _SettingsCard(
                    isDark: isDark,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    header: _CardHeader(
                      label: 'Appearance',
                      icon: Icons.palette_rounded,
                      isDark: isDark,
                    ),
                    child: ValueListenableBuilder<ThemeMode>(
                      valueListenable: themeModeNotifier,
                      builder: (_, mode, __) => _SettingsTile(
                        icon: mode == ThemeMode.dark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        title: 'Dark Mode',
                        subtitle: mode == ThemeMode.dark
                            ? 'Deep dark theme active'
                            : 'Clean light theme active',
                        value: mode == ThemeMode.dark,
                        onChanged: (v) => themeModeNotifier.value =
                            v ? ThemeMode.dark : ThemeMode.light,
                        isDark: isDark,
                        isLast: true,
                      ),
                    ),
                  ),
                ),

                // ── Accessibility card ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: _SettingsCard(
                    isDark: isDark,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    header: _CardHeader(
                      label: 'Accessibility',
                      icon: Icons.accessibility_new_rounded,
                      isDark: isDark,
                    ),
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.vibration_rounded,
                          title: 'Vibration Alerts',
                          subtitle: 'Alert you with vibration on scan results',
                          value: _vibrationEnabled,
                          onChanged: _setVibration,
                          isDark: isDark,
                        ),
                        _Divider(isDark: isDark),
                        _SettingsTile(
                          icon: Icons.volume_up_rounded,
                          title: 'Voice Feedback',
                          subtitle: 'Hear scan results read aloud',
                          value: _voiceFeedbackEnabled,
                          onChanged: _setVoiceFeedback,
                          isDark: isDark,
                        ),
                        _Divider(isDark: isDark),
                        _SettingsTile(
                          icon: Icons.contrast_rounded,
                          title: 'High Contrast Mode',
                          subtitle: 'Increase colour contrast for readability',
                          value: false,
                          onChanged: (_) {},
                          isDark: isDark,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Health condition card ───────────────────────────────────
                SliverToBoxAdapter(
                  child: _SettingsCard(
                    isDark: isDark,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    header: _CardHeader(
                      label: 'Health Condition',
                      icon: Icons.favorite_rounded,
                      isDark: isDark,
                    ),
                    child: _ConditionTile(
                      conditions: _currentConditions,
                      isDark: isDark,
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
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

/// Card container matching the Profile screen style.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.child,
    required this.isDark,
    this.header,
    this.margin,
  });

  final Widget child;
  final Widget? header;
  final bool isDark;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.25)
                : Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) ...[
            header!,
            const SizedBox(height: 10),
          ],
          child,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Accent-tinted section title row inside each card.
class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.label,
    required this.icon,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.neonMint : AppTheme.navyColor;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: accent),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: accent.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}

/// Single toggle row inside a settings card.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.neonMint : AppTheme.navyColor;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: accent, size: 20),
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
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withOpacity(0.45)
                        : Colors.grey.shade500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: accent,
          ),
        ],
      ),
    );
  }
}

/// Thin divider between tiles.
class _Divider extends StatelessWidget {
  const _Divider({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 54,
      color: isDark ? Colors.white.withOpacity(0.07) : Colors.grey.shade100,
    );
  }
}

/// Health condition row — tappable navigator tile.
class _ConditionTile extends StatelessWidget {
  const _ConditionTile({
    required this.conditions,
    required this.isDark,
    required this.onTap,
  });

  final List<HealthCondition> conditions;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.neonMint : AppTheme.navyColor;
    final label = conditions.isEmpty
        ? 'None selected'
        : conditions.map((c) => c.displayName).join(', ');
    final sublabel = conditions.isEmpty
        ? 'Tap to select your health conditions'
        : '${conditions.length} condition${conditions.length == 1 ? '' : 's'} active';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.09),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.medical_services_rounded,
                  color: accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: AppTheme.bodyFontSize - 2,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.navyColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white.withOpacity(0.45)
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark
                  ? Colors.white.withOpacity(0.30)
                  : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
