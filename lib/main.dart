import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'models/health_condition.dart';
import 'screens/selection_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/settings_screen.dart';
import 'services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestCameraPermission();
  runApp(const MyApp());
}

Future<void> _requestCameraPermission() async {
  final status = await Permission.camera.request();
  if (status.isDenied) {
    debugPrint('Camera permission denied');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Doctor Eyes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      routes: {
        '/': (context) => const InitialRoute(),
        '/settings': (context) => const SettingsScreen(),
      },
      initialRoute: '/',
    );
  }
}

class InitialRoute extends StatefulWidget {
  const InitialRoute({super.key});

  @override
  State<InitialRoute> createState() => _InitialRouteState();
}

class _InitialRouteState extends State<InitialRoute> {
  final PreferencesService _preferencesService = PreferencesService();

  @override
  void initState() {
    super.initState();
    _checkHealthCondition();
  }

  Future<void> _checkHealthCondition() async {
    final hasCondition = await _preferencesService.hasHealthCondition();

    if (mounted) {
      if (hasCondition) {
        final condition = await _preferencesService.getHealthCondition();
        if (condition != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ScannerScreen(healthCondition: condition),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => SelectionScreen(),
            ),
          );
        }
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => SelectionScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading...', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
