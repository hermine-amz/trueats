import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/services/service_locator.dart';
import 'features/onboarding/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServiceLocator.init();
  runApp(const TruEatsApp());
}

class TruEatsApp extends StatelessWidget {
  const TruEatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TruEats',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

