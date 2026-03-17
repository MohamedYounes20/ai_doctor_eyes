import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/preferences_service.dart';
import 'selection_screen.dart';

/// WelcomeScreen: Full Name, Year of Birth. Save via PreferencesService.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PreferencesService _prefs = PreferencesService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int? _yearOfBirth;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canProceed =>
      _nameController.text.trim().isNotEmpty && _yearOfBirth != null;

  Future<void> _onNext() async {
    if (!_canProceed || _saving) return;
    setState(() => _saving = true);
    final ok = await _prefs.saveUserProfile(
      fullName: _nameController.text.trim(),
      yearOfBirth: _yearOfBirth!,
    );
    if (ok && mounted) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SelectionScreen()),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                // Logo placeholder
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.visibility,
                        color: Colors.white, size: 48),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to AI Doctor Eyes',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell us about yourself',
                  style: TextStyle(
                    fontSize: AppTheme.bodyFontSize,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Text(
                  'Full Name',
                  style: const TextStyle(
                    fontSize: AppTheme.bodyFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: const TextStyle(fontSize: AppTheme.bodyFontSize),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),
                Text(
                  'Year of Birth',
                  style: const TextStyle(
                    fontSize: AppTheme.bodyFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickYear,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined),
                        const SizedBox(width: 12),
                        Text(
                          _yearOfBirth != null
                              ? '$_yearOfBirth'
                              : 'Select your birth year',
                          style: TextStyle(
                            fontSize: AppTheme.bodyFontSize,
                            color: _yearOfBirth != null
                                ? Colors.black
                                : Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.keyboard_arrow_down),
                      ],
                    ),
                  ),
                ),
                if (_yearOfBirth != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Age: ${_prefs.getAgeFromYearOfBirth(_yearOfBirth!)} years',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _canProceed && !_saving ? _onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _saving ? 'Saving...' : 'Next: Choose My Conditions',
                    style: const TextStyle(
                      fontSize: AppTheme.bodyFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please fill in all fields to continue',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickYear() async {
    final now = DateTime.now().year;
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select birth year'),
        content: SizedBox(
          width: 200,
          height: 200,
          child: ListView.builder(
            itemCount: 100,
            itemBuilder: (_, i) {
              final y = now - i;
              return ListTile(
                title: Text('$y'),
                onTap: () => Navigator.pop(ctx, y),
              );
            },
          ),
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _yearOfBirth = picked);
  }
}
