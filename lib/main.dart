import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/services/service_locator.dart';
import 'core/services/deeplink_service.dart';
import 'features/onboarding/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/push_notification_service.dart';

import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase nécessite une configuration spécifique sur le Web (firebase_options.dart).
  // Pour éviter le crash sur Chrome, on ne l'initialise que sur mobile pour l'instant.
  if (!kIsWeb) {
    await Firebase.initializeApp();
  }
  
  await ServiceLocator.init();
  DeepLinkService.init();
  
  if (!kIsWeb) {
    final pushService = PushNotificationService();
    await pushService.init(navigatorKey);
  }
  
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

