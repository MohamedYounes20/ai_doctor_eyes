import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app_theme.dart';
import 'screens/splash_screen.dart';

/// Global theme-mode notifier — read/write from any screen via
/// `themeModeNotifier.value = ThemeMode.dark`.
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.light);

/// Global health-conditions notifier — holds the list of selected condition
/// display names so any screen can reactively observe changes.
final ValueNotifier<List<String>> selectedConditionsNotifier =
    ValueNotifier<List<String>>([]);

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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, mode, __) => MaterialApp(
        title: 'AI Doctor Eyes',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: mode,
        home: const SplashScreen(),
      ),
    );
  }
}
