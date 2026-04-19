import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../core/constants/condition_config.dart';
import '../main.dart' show selectedConditionsNotifier;
import '../services/preferences_service.dart';
import 'medical_record_screen.dart';
import 'selection_screen.dart';
import 'welcome_screen.dart';

/// Profile tab: User name, Active condition, Scan history list.
class ProfileScreen extends StatefulWidget {
  final VoidCallback? onUpdateConditions;
  final ValueNotifier<int>? scanRefreshTrigger;

  const ProfileScreen({super.key, this.onUpdateConditions, this.scanRefreshTrigger});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PreferencesService _prefs = PreferencesService();

  String? _fullName;
  int? _yearOfBirth;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    widget.scanRefreshTrigger?.addListener(_load);
  }

  @override
  void dispose() {
    widget.scanRefreshTrigger?.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final name = await _prefs.getFullName();
    final year = await _prefs.getYearOfBirth();
    if (mounted) {
      setState(() {
        _fullName = name ?? 'User';
        _yearOfBirth = year;
        _loading = false;
      });
    }
  }

  void _refresh() => _load();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.spaceBlack : AppTheme.icyWhite;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: bg,
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: cs.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: isDark ? AppTheme.neonMint : AppTheme.navyColor,
              child: CustomScrollView(
                slivers: [
                  // ── Gradient header
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 52, bottom: 28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF0D1B35), const Color(0xFF162040)]
                              : [AppTheme.navyColor, const Color(0xFF243B6E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'My Profile',
                            style: TextStyle(
                              fontSize: AppTheme.titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Avatar with mint ring
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.neonMint
                                    : AppTheme.mintColor,
                                width: 2.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white.withOpacity(0.15),
                              child: Text(
                                (_fullName?.isNotEmpty == true
                                        ? _fullName![0]
                                        : '?')
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppTheme.neonMint
                                      : AppTheme.mintColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _fullName ?? 'User',
                                style: const TextStyle(
                                  fontSize: AppTheme.titleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.white70, size: 18),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const WelcomeScreen(),
                                    ),
                                  );
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          if (_yearOfBirth != null)
                            Text(
                              'Age: ${_prefs.getAgeFromYearOfBirth(_yearOfBirth!)} years',
                              style: const TextStyle(
                                fontSize: AppTheme.bodyFontSize - 2,
                                color: Colors.white60,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Active conditions — reactive via global notifier
                          Text(
                            'Active Health Conditions',
                            style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          const SizedBox(height: 12),
                          ValueListenableBuilder<List<String>>(
                            valueListenable: selectedConditionsNotifier,
                            builder: (context, conditionNames, _) {
                              // Also sync local _conditions list for the button label
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppTheme.navyCard
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? AppTheme.neonMint.withOpacity(0.25)
                                        : AppTheme.navyColor.withOpacity(0.15),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black.withOpacity(0.2)
                                          : AppTheme.navyColor.withOpacity(0.05),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (conditionNames.isEmpty)
                                      Text(
                                        'No conditions selected',
                                        style: TextStyle(
                                          fontSize: AppTheme.bodyFontSize,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.grey,
                                        ),
                                      )
                                    else
                                      ...conditionNames.map(
                                        (name) => _buildConditionRow(
                                            name, isDark),
                                      ),
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const SelectionScreen(
                                                    isUpdateMode: true),
                                          ),
                                        );
                                        _refresh();
                                        widget.onUpdateConditions?.call();
                                      },
                                      icon: const Icon(Icons.edit, size: 18),
                                      label: Text(
                                        conditionNames.isEmpty
                                            ? 'Select Conditions'
                                            : 'Update My Conditions',
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          // ── Medical & Data section ──────────────────────
                          Text(
                            'Medical & Data',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.navyCard : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.neonMint.withOpacity(0.25)
                                    : AppTheme.navyColor.withOpacity(0.15),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withOpacity(0.2)
                                      : AppTheme.navyColor.withOpacity(0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (isDark
                                          ? AppTheme.neonMint
                                          : AppTheme.navyColor)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.medical_information_rounded,
                                  color: isDark
                                      ? AppTheme.neonMint
                                      : AppTheme.navyColor,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                'Lab Report & Backup',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDark ? Colors.white : AppTheme.navyColor,
                                ),
                              ),
                              subtitle: Text(
                                'Upload lab results • Export & Import data',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey.shade600,
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey.shade400,
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MedicalRecordScreen(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Emoji lookup delegated to shared condition_config.dart

  Widget _buildConditionRow(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            emojiForCondition(text),
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: AppTheme.bodyFontSize,
                color: isDark ? Colors.white : AppTheme.navyColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
