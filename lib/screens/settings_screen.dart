import 'package:flutter/material.dart';
import '../models/health_condition.dart';
import '../services/preferences_service.dart';
import 'scanner_screen.dart';

/// Settings Screen
/// 
/// This screen allows users to change their selected health condition.
/// It displays the current selection and allows them to choose a different one.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _preferencesService = PreferencesService();
  HealthCondition? _currentCondition;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentCondition();
  }

  /// Load the currently saved health condition
  Future<void> _loadCurrentCondition() async {
    final condition = await _preferencesService.getHealthCondition();
    if (mounted) {
      setState(() {
        _currentCondition = condition;
        _isLoading = false;
      });
    }
  }

  /// Handle changing the health condition
  Future<void> _changeCondition(HealthCondition newCondition) async {
    setState(() {
      _isSaving = true;
    });

    // Save the new condition
    final saved = await _preferencesService.saveHealthCondition(newCondition);

    if (saved && mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Condition changed to ${newCondition.displayName}',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate back to scanner with new condition
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ScannerScreen(healthCondition: newCondition),
        ),
      );
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save changes. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Current selection display
                    Card(
                      color: Colors.blue.shade50,
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const Text(
                              'Current Selection',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _currentCondition?.displayName ?? 'None',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            if (_currentCondition != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _currentCondition!.description,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Change condition section
                    const Text(
                      'Change Condition:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Diabetes option
                    _buildConditionCard(
                      condition: HealthCondition.diabetes,
                      icon: Icons.warning_amber_rounded,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),

                    // Hypertension option
                    _buildConditionCard(
                      condition: HealthCondition.hypertension,
                      icon: Icons.favorite,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),

                    // Gluten Allergy option
                    _buildConditionCard(
                      condition: HealthCondition.glutenAllergy,
                      icon: Icons.restaurant,
                      color: Colors.green,
                    ),

                    const Spacer(),

                    // Loading indicator
                    if (_isSaving)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  /// Build a card widget for each health condition option
  Widget _buildConditionCard({
    required HealthCondition condition,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _currentCondition == condition;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: _isSaving || isSelected
            ? null
            : () => _changeCondition(condition),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      condition.displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      condition.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Selection indicator
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: color,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
