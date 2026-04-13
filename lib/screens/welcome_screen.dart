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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.spaceBlack : AppTheme.icyWhite;
    final inputFill = isDark ? AppTheme.navyCard : Colors.white;
    final labelColor = isDark ? Colors.white70 : AppTheme.navyColor;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // ── Logo
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF0D1B35), const Color(0xFF1A2C4A)]
                            : [AppTheme.navyColor, const Color(0xFF243B6E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? AppTheme.neonMint : AppTheme.navyColor)
                              .withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.visibility,
                      color: isDark ? AppTheme.neonMint : AppTheme.mintColor,
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                Text(
                  'Welcome to\nAI Doctor Eyes',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell us about yourself to get started',
                  style: TextStyle(
                    fontSize: AppTheme.bodyFontSize - 2,
                    color: isDark
                        ? Colors.white.withOpacity(0.55)
                        : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // ── Full Name
                Text(
                  'Full Name',
                  style: TextStyle(
                    fontSize: AppTheme.bodyFontSize - 2,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: isDark ? Colors.white38 : Colors.grey,
                    ),
                    filled: true,
                    fillColor: inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: isDark ? AppTheme.neonMint : AppTheme.navyColor,
                          width: 1.5),
                    ),
                  ),
                  style: TextStyle(
                      fontSize: AppTheme.bodyFontSize,
                      color: isDark ? Colors.white : AppTheme.navyColor),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),

                // ── Year of Birth
                Text(
                  'Year of Birth',
                  style: TextStyle(
                    fontSize: AppTheme.bodyFontSize - 2,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickYear,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: inputFill,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _yearOfBirth != null
                              ? '$_yearOfBirth'
                              : 'Select your birth year',
                          style: TextStyle(
                            fontSize: AppTheme.bodyFontSize,
                            color: _yearOfBirth != null
                                ? (isDark ? Colors.white : AppTheme.navyColor)
                                : (isDark
                                    ? Colors.white38
                                    : Colors.grey.shade500),
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.keyboard_arrow_down,
                            color: isDark ? Colors.white38 : Colors.grey),
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
                        color: isDark
                            ? AppTheme.neonMint.withOpacity(0.8)
                            : AppTheme.mintColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 44),

                // ── CTA
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _canProceed && !_saving ? _onNext : null,
                    child: Text(
                      _saving ? 'Saving...' : 'Next: Choose My Conditions',
                      style: const TextStyle(
                        fontSize: AppTheme.bodyFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please fill in all fields to continue',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? Colors.white.withOpacity(0.35)
                        : Colors.grey.shade500,
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
