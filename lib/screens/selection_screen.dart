import 'package:flutter/material.dart';
import '../models/health_condition.dart';
import '../services/preferences_service.dart';
import 'scanner_screen.dart';

/// Selection Screen
/// 
/// This is the initial setup screen where users select their health condition.
/// It displays large, easy-to-read buttons for each condition option.
/// The selection is saved locally and the user is navigated to the scanner screen.
class SelectionScreen extends StatefulWidget {
  const SelectionScreen({super.key});

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  final PreferencesService _preferencesService = PreferencesService();
  HealthCondition? _selectedCondition;
  bool _isLoading = false;

  /// Handle the selection of a health condition
  /// 
  /// Saves the selection and navigates to the scanner screen
  Future<void> _handleSelection(HealthCondition condition) async {
    setState(() {
      _selectedCondition = condition;
      _isLoading = true;
    });

    // Save the selected condition
    final saved = await _preferencesService.saveHealthCondition(condition);

    if (saved && mounted) {
      // Navigate to scanner screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ScannerScreen(healthCondition: condition),
        ),
      );
    } else {
      // Show error if save failed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save selection. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
          _selectedCondition = null;
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
          'Select Your Condition',
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome message
              const SizedBox(height: 20),
              const Text(
                'Welcome to AI Doctor Eyes',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Please select your health condition to get started:',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Diabetes option
              _buildConditionCard(
                condition: HealthCondition.diabetes,
                icon: Icons.warning_amber_rounded,
                color: Colors.orange,
              ),
              const SizedBox(height: 20),

              // Hypertension option
              _buildConditionCard(
                condition: HealthCondition.hypertension,
                icon: Icons.favorite,
                color: Colors.red,
              ),
              const SizedBox(height: 20),

              // Gluten Allergy option
              _buildConditionCard(
                condition: HealthCondition.glutenAllergy,
                icon: Icons.restaurant,
                color: Colors.green,
              ),

              const Spacer(),

              // Loading indicator
              if (_isLoading)
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
  /// 
  /// [condition] - The health condition to display
  /// [icon] - Icon to show for this condition
  /// [color] - Color theme for this condition card
  Widget _buildConditionCard({
    required HealthCondition condition,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedCondition == condition;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 3 : 1,
        ),
      ),
      child: InkWell(
        onTap: _isLoading ? null : () => _handleSelection(condition),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(width: 20),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      condition.displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      condition.description,
                      style: TextStyle(
                        fontSize: 16,
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
                  size: 32,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
