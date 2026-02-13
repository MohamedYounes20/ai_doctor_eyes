import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/health_condition.dart';
import '../services/preferences_service.dart';
import 'main_parent_screen.dart';

/// Selection Screen: Grid layout, Blue #0052CC theme.
/// Navigates to MainParentScreen when done, or back if in update mode.
class SelectionScreen extends StatefulWidget {
  final bool isUpdateMode;

  const SelectionScreen({super.key, this.isUpdateMode = false});

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  final PreferencesService _prefs = PreferencesService();
  HealthCondition? _selectedCondition;
  bool _loading = false;

  Future<void> _handleGetStarted() async {
    if (_selectedCondition == null || _loading) return;
    setState(() => _loading = true);
    final ok = await _prefs.saveHealthCondition(_selectedCondition!);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Select Your Condition'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Select Your Condition',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your health conditions to personalize your food scanning experience',
                style: TextStyle(
                  fontSize: AppTheme.bodyFontSize,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              // 2x2 Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: [
                    _ConditionCard(
                      condition: HealthCondition.diabetes,
                      icon: Icons.monitor_heart_outlined,
                      color: Colors.purple,
                      selected: _selectedCondition == HealthCondition.diabetes,
                      onTap: () => setState(
                          () => _selectedCondition = HealthCondition.diabetes),
                    ),
                    _ConditionCard(
                      condition: HealthCondition.glutenAllergy,
                      icon: Icons.grass,
                      color: Colors.amber.shade700,
                      selected:
                          _selectedCondition == HealthCondition.glutenAllergy,
                      onTap: () => setState(() =>
                          _selectedCondition = HealthCondition.glutenAllergy),
                    ),
                    _ConditionCard(
                      condition: HealthCondition.hypertension,
                      icon: Icons.favorite,
                      color: Colors.red,
                      selected:
                          _selectedCondition == HealthCondition.hypertension,
                      onTap: () => setState(() =>
                          _selectedCondition = HealthCondition.hypertension),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _selectedCondition != null && !_loading
                    ? _handleGetStarted
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _loading ? 'Saving...' : 'Get Started',
                  style: const TextStyle(
                    fontSize: AppTheme.bodyFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_selectedCondition == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Please select at least one condition',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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

  const _ConditionCard({
    required this.condition,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: selected ? 3 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              condition.displayName,
              style: const TextStyle(
                fontSize: AppTheme.bodyFontSize,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              condition.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (selected)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: AppTheme.primaryColor,
                  child: const Icon(Icons.check, color: Colors.white, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
