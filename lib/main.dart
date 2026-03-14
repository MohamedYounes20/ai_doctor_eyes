import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app_theme.dart';
import 'screens/main_parent_screen.dart';
import 'screens/selection_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await _requestCameraPermission();
  runApp(const MyApp());
}

Future<void> _requestCameraPermission() async {
  final status = await Permission.camera.request();
  if (status.isDenied) debugPrint('Camera permission denied');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Doctor Eyes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const InitialRoute(),
    );
  }
}

/// Routes: WelcomeScreen (first time) -> SelectionScreen -> MainParentScreen.
class InitialRoute extends StatefulWidget {
  const InitialRoute({super.key});

  @override
  State<InitialRoute> createState() => _InitialRouteState();
}

class _InitialRouteState extends State<InitialRoute> {
  final PreferencesService _prefs = PreferencesService();

  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final onboardingDone = await _prefs.hasCompletedOnboarding();
    final hasCondition = await _prefs.hasHealthCondition();

    if (!mounted) return;

    if (!onboardingDone) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
      return;
    }
    if (!hasCondition) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SelectionScreen()),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainParentScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            SizedBox(height: 20),
            Text('Loading...',
                style: TextStyle(fontSize: AppTheme.bodyFontSize)),
          ],
        ),
      ),
    );
  }
}
