import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Full screen on Pi — hide any system chrome
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const TftNavApp());
}

class TftNavApp extends StatelessWidget {
  const TftNavApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BikeNav TFT',
      debugShowCheckedModeBanner: false,
      // Dark theme — better in sunlight, matches TFT display characteristics
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const AppShell(),
    );
  }
}