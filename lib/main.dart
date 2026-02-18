import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';
import 'package:hervest_ai/features/onboarding/onboarding_first_page.dart';
import 'package:hervest_ai/features/onboarding/onboarding_second_page.dart';
import 'package:hervest_ai/features/onboarding/onboarding_third_page.dart';
import 'package:hervest_ai/features/onboarding/splash_screen.dart';
import 'package:hervest_ai/bottom_navigation/bottom_naviagation.dart';
import 'package:hervest_ai/pages/forgotpw_enter_email.dart';
import 'package:hervest_ai/pages/forgotpw_otp.dart';
import 'package:hervest_ai/pages/forgotpw_three.dart';
import 'package:hervest_ai/pages/landing_page.dart';
import 'package:hervest_ai/pages/reset_password.dart';
import 'package:hervest_ai/pages/signin_page.dart';
import 'package:hervest_ai/pages/signup_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SurplusApp());
}

Future<void> _exitOnboarding(BuildContext context) async {
  await AppSessionStore.instance.setHasSeenOnboarding(true);
  final isLoggedIn = await AppSessionStore.instance.isLoggedIn();
  if (context.mounted) {
    context.go(isLoggedIn ? '/dashboard' : '/landing');
  }
}

class SurplusApp extends StatelessWidget {
  const SurplusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'HerVest AI',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      routerConfig: _router,
    );
  }
}

// --- ROUTER CONFIGURATION ---
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding-1',
      builder: (context, state) => OnboardingFirstScreen(
        onNext: () => context.go('/onboarding-2'),
        onSkip: () => _exitOnboarding(context),
        onClose: () => _exitOnboarding(context),
      ),
    ),
    GoRoute(
      path: '/onboarding-2',
      builder: (context, state) => OnboardingSecondScreen(
        onNext: () => context.go('/onboarding-3'),
        onBack: () => context.go('/onboarding-1'),
        onClose: () => _exitOnboarding(context),
      ),
    ),
    GoRoute(
      path: '/onboarding-3',
      builder: (context, state) => OnboardingThirdScreen(
        onBack: () => context.go('/onboarding-2'),
        onFinish: () => _exitOnboarding(context),
        onClose: () => _exitOnboarding(context),
      ),
    ),
    GoRoute(path: '/landing', builder: (context, state) => const LandingPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordEmailScreen(),
    ),
    GoRoute(
      path: '/forgot-password/check-email/:email',
      builder: (context, state) => CheckEmailScreen(
        email: Uri.decodeComponent(state.pathParameters['email'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/forgot-password/enter-code/:email',
      builder: (context, state) => EnterCodeScreen(
        email: Uri.decodeComponent(state.pathParameters['email'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/forgot-password/reset-password/:email',
      builder: (context, state) => ResetPasswordScreen(
        email: Uri.decodeComponent(state.pathParameters['email'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const MainNavigationScreen(),
    ),
  ],
);
