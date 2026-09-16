import 'package:flutter/material.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.restoreSession();
  runApp(const AqaryApp());
}

class AqaryApp extends StatelessWidget {
  const AqaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AQARY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const WelcomeScreen(),
    );
  }
}
