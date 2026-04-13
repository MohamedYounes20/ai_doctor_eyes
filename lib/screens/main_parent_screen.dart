import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../main.dart' show selectedConditionsNotifier;
import '../models/health_condition.dart';
import '../services/preferences_service.dart';
import 'alternatives_screen.dart';
import 'profile_screen.dart';
import 'scanner_screen.dart';
import 'settings_screen.dart';

/// Main screen with floating pill NavigationBar: Profile, Scan, Ideas, Settings.
class MainParentScreen extends StatefulWidget {
  const MainParentScreen({super.key});

  @override
  State<MainParentScreen> createState() => _MainParentScreenState();
}

class _MainParentScreenState extends State<MainParentScreen> {
  final PreferencesService _prefs = PreferencesService();
  final ValueNotifier<int> _scanRefreshTrigger = ValueNotifier(0);
  int _currentIndex = 1; // Scan is default
  List<HealthCondition> _healthConditions = [];

  @override
  void initState() {
    super.initState();
    _loadConditions();
  }

  @override
  void dispose() {
    _scanRefreshTrigger.dispose();
    super.dispose();
  }

  Future<void> _loadConditions() async {
    final conditions = await _prefs.getHealthConditions();
    if (mounted) {
      setState(() => _healthConditions = conditions);
      // Keep global notifier in sync
      selectedConditionsNotifier.value =
          conditions.map((c) => c.displayName).toList();
    }
  }

  List<Widget> _buildPages() {
    final conditions = _healthConditions.isEmpty
        ? [HealthCondition.diabetes]
        : _healthConditions;
    return [
      ProfileScreen(
        onUpdateConditions: _loadConditions,
        scanRefreshTrigger: _scanRefreshTrigger,
      ),
      ScannerScreen(
        healthConditions: conditions,
        isVisible: _currentIndex == 1,
        onScanComplete: () => _scanRefreshTrigger.value++,
      ),
      const AlternativesScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true, // content goes under the floating nav
      body: IndexedStack(
        index: _currentIndex,
        children: _buildPages(),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D1B35) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.45)
                    : AppTheme.navyColor.withOpacity(0.14),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              backgroundColor: Colors.transparent,
              elevation: 0,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              animationDuration: const Duration(milliseconds: 300),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: Icon(
                    Icons.person,
                    color: isDark ? AppTheme.neonMint : AppTheme.navyColor,
                  ),
                  label: 'Profile',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.document_scanner_outlined),
                  selectedIcon: Icon(
                    Icons.document_scanner,
                    color: isDark ? AppTheme.neonMint : AppTheme.navyColor,
                  ),
                  label: 'Scan',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.lightbulb_outline),
                  selectedIcon: Icon(
                    Icons.lightbulb,
                    color: isDark ? AppTheme.neonMint : AppTheme.navyColor,
                  ),
                  label: 'Ideas',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: Icon(
                    Icons.settings,
                    color: isDark ? AppTheme.neonMint : AppTheme.navyColor,
                  ),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
