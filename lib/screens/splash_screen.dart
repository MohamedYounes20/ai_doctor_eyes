import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/preferences_service.dart';
import 'main_parent_screen.dart';
import 'selection_screen.dart';
import 'welcome_screen.dart';

/// Premium splash screen shown at app launch.
///
/// Displays the brand identity for [_kSplashDuration] then routes to:
/// - [WelcomeScreen]    — first-time users (onboarding not complete)
/// - [SelectionScreen]  — onboarded but no condition selected
/// - [MainParentScreen] — fully onboarded users
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _kSplashDuration = Duration(seconds: 3);

  final PreferencesService _prefs = PreferencesService();

  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();

    // ── Entry animations ────────────────────────────────────────────────────
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleIn = Tween<double>(begin: 0.80, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    // ── Routing after delay ─────────────────────────────────────────────────
    Timer(_kSplashDuration, _navigate);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    if (!mounted) return;

    final onboardingDone = await _prefs.hasCompletedOnboarding();
    final hasCondition = await _prefs.hasHealthCondition();

    if (!mounted) return;

    Widget destination;
    if (!onboardingDone) {
      destination = const WelcomeScreen();
    } else if (!hasCondition) {
      destination = const SelectionScreen();
    } else {
      destination = const MainParentScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => destination,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Subtle radial glow behind the logo ────────────────────────
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.textAccent.withOpacity(0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Main content ──────────────────────────────────────────────
            Center(
              child: FadeTransition(
                opacity: _fadeIn,
                child: ScaleTransition(
                  scale: _scaleIn,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Eye icon with ring glow
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.textAccent.withOpacity(0.12),
                          border: Border.all(
                            color: AppTheme.textAccent.withOpacity(0.35),
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppTheme.accentShadow,
                              blurRadius: 32,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.visibility_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Brand name
                      Text(
                        'AI Doctor Eyes',
                        style: GoogleFonts.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.8,
                          height: 1.1,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Tagline
                      Text(
                        'Your intelligent health companion',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.50),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Loading indicator (bottom) ─────────────────────────────────
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  children: [
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.0,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.textAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Initialising…',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.35),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
