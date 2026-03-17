import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/health_condition.dart';
import '../services/preferences_service.dart';
import 'main_parent_screen.dart';

/// Selection Screen: Grid layout, Navy/Mint theme.
/// Navigates to MainParentScreen when done, or back if in update mode.
/// Supports multiple selection of conditions.
class SelectionScreen extends StatefulWidget {
  final bool isUpdateMode;

  const SelectionScreen({super.key, this.isUpdateMode = false});

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  final PreferencesService _prefs = PreferencesService();
  final Set<HealthCondition> _selectedConditions = {};
  bool _loading = false;

  static const List<(HealthCondition, IconData, Color)> _conditionConfig = [
    (HealthCondition.diabetes, Icons.monitor_heart_outlined, Colors.purple),
    (HealthCondition.glutenAllergy, Icons.grass, Color(0xFFB8860B)),
    (HealthCondition.nutAllergy, Icons.restaurant, Color(0xFF8B4513)),
    (HealthCondition.hypertension, Icons.favorite, Colors.red),
  ];

  Future<void> _handleGetStarted() async {
    if (_selectedConditions.isEmpty || _loading) return;
    setState(() => _loading = true);
    final ok = await _prefs.saveHealthConditions(_selectedConditions.toList());
    if (ok && mounted) {
      if (!widget.isUpdateMode) await _prefs.setOnboardingCompleted(true);
      if (widget.isUpdateMode) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainParentScreen()),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _toggleCondition(HealthCondition condition) {
    setState(() {
      if (_selectedConditions.contains(condition)) {
        _selectedConditions.remove(condition);
      } else {
        _selectedConditions.add(condition);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadExistingConditions();
  }

  Future<void> _loadExistingConditions() async {
    final conditions = await _prefs.getHealthConditions();
    if (mounted) {
      setState(() {
        _selectedConditions.clear();
        _selectedConditions.addAll(conditions);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.spaceBlack : AppTheme.icyWhite;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Select Your Conditions'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                'Select Your Conditions',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose one or more health conditions to personalize your food scanning experience',
                style: TextStyle(
                  fontSize: AppTheme.bodyFontSize - 2,
                  color: isDark
                      ? Colors.white.withOpacity(0.55)
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              // 2×2 Grid
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.85,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final (condition, icon, color) in _conditionConfig)
                    _ConditionCard(
                      condition: condition,
                      icon: icon,
                      color: color,
                      selected: _selectedConditions.contains(condition),
                      onTap: () => _toggleCondition(condition),
                      isDark: isDark,
                    ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      _selectedConditions.isNotEmpty && !_loading
                          ? _handleGetStarted
                          : null,
                  child: Text(
                    _loading ? 'Saving...' : 'Get Started',
                    style: const TextStyle(
                      fontSize: AppTheme.bodyFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (_selectedConditions.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Please select at least one condition',
                    style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white.withOpacity(0.4)
                            : Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConditionCard extends StatelessWidget {
  final HealthCondition condition;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _ConditionCard({
    required this.condition,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? (selected ? AppTheme.navyColor : AppTheme.navyCard)
        : Colors.white;
    final selectedBorderColor =
        isDark ? AppTheme.neonMint : AppTheme.navyColor;
    final unselBorderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.grey.shade200;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? selectedBorderColor : unselBorderColor,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(selected ? 0.35 : 0.2)
                  : AppTheme.navyColor.withOpacity(selected ? 0.12 : 0.04),
              blurRadius: selected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              condition.displayName,
              style: TextStyle(
                fontSize: AppTheme.bodyFontSize - 2,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.navyColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              condition.description,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (selected)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: isDark ? AppTheme.neonMint : AppTheme.navyColor,
                  child: Icon(
                    Icons.check,
                    color: isDark ? AppTheme.spaceBlack : Colors.white,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
