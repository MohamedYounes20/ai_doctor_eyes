import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/health_condition.dart';
import '../services/preferences_service.dart';
import 'profile_screen.dart';
import 'scanner_screen.dart';
import 'settings_screen.dart';

/// Main screen with BottomNavigationBar: Profile, Scan, Settings.
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
    if (mounted) setState(() => _healthConditions = conditions);
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
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _buildPages(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        selectedFontSize: AppTheme.bodyFontSize,
        unselectedFontSize: AppTheme.bodyFontSize,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 28),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.document_scanner_outlined, size: 28),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined, size: 28),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
