import 'package:flutter/material.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.restoreSession();
  runApp(const AqaryApp());
}

/// AQARY is designed as a phone-width layout — on a real phone that's the
/// whole screen, but on a wide desktop browser window the same layout was
/// stretching edge to edge: two-column grids turning into acres of empty
/// white card around a small icon, text lines running the full width of a
/// monitor. This caps content at phone width and centers it, the same
/// "letterboxed" pattern most mobile-first web apps use, instead of trying
/// to be a genuinely responsive desktop layout.
const double _kMaxContentWidth = 480;

class AqaryApp extends StatelessWidget {
  const AqaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AQARY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const WelcomeScreen(),
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return ColoredBox(
          color: AppColors.line,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
