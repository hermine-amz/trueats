import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/services/service_locator.dart';
import 'core/services/deeplink_service.dart';
import 'features/onboarding/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await ServiceLocator.init();
  DeepLinkService.init();
  
  final pushService = PushNotificationService();
  await pushService.init(navigatorKey);
  
  runApp(const TruEatsApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class TruEatsApp extends StatelessWidget {
  const TruEatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TruEats',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

