import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';
import 'package:hervest_ai/features/onboarding/onboarding_first_page.dart';
import 'package:hervest_ai/features/onboarding/onboarding_second_page.dart';
import 'package:hervest_ai/features/onboarding/onboarding_third_page.dart';
import 'package:hervest_ai/features/onboarding/splash_screen.dart';
import 'package:hervest_ai/bottom_navigation/bottom_naviagation.dart';
import 'package:hervest_ai/pages/landing_page.dart';
import 'package:hervest_ai/pages/signin_page.dart';
import 'package:hervest_ai/pages/signup_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // DEV ONLY: Reset onboarding and login flags for testing
  await AppSessionStore.instance.setHasSeenOnboarding(false);
  await AppSessionStore.instance.setLoggedIn(false);
  runApp(const SurplusApp());
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
        onClose: () async {
          await AppSessionStore.instance.setHasSeenOnboarding(true);
          if (context.mounted) {
            context.go('/landing');
          }
        },
      ),
    ),
    GoRoute(
      path: '/onboarding-2',
      builder: (context, state) => OnboardingSecondScreen(
        onNext: () => context.go('/onboarding-3'),
        onBack: () => context.go('/onboarding-1'),
        onClose: () async {
          await AppSessionStore.instance.setHasSeenOnboarding(true);
          if (context.mounted) {
            context.go('/landing');
          }
        },
      ),
    ),
    GoRoute(
      path: '/onboarding-3',
      builder: (context, state) => OnboardingThirdScreen(
        onBack: () => context.go('/onboarding-2'),
        onFinish: () async {
          await AppSessionStore.instance.setHasSeenOnboarding(true);
          if (context.mounted) {
            context.go('/landing');
          }
        },
        onClose: () async {
          await AppSessionStore.instance.setHasSeenOnboarding(true);
          if (context.mounted) {
            context.go('/landing');
          }
        },
      ),
    ),
    GoRoute(path: '/landing', builder: (context, state) => const LandingPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const MainNavigationScreen(),
    ),
  ],
);
