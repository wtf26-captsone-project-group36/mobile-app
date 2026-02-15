import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:hervest_ai/features/onboarding/onboarding_first_page.dart';
import 'package:hervest_ai/features/onboarding/onboarding_second_page.dart';
import 'package:hervest_ai/features/onboarding/onboarding_third_page.dart';


void main() {
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

// --- SPLASH SCREEN WIDGET ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;
  double _scale = 0.8;

  @override
  void initState() {
    super.initState();
    
    // Trigger the Fade & Scale animation
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
          _scale = 1.0;
        });
      }
    });

    // Navigate to Onboarding after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/onboarding-1');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(milliseconds: 1000),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo.png', // Ensure this exists in pubspec.yaml
                  width: 180,
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 50,
                  child: LinearProgressIndicator(
                    color: Colors.green,
                    backgroundColor: Color(0xFFE8F5E9), // Light green tint
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- ROUTER CONFIGURATION ---
final GoRouter _router = GoRouter(
  initialLocation: '/', // Start at the Splash Screen
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding-1',
      builder: (context, state) => OnboardingFirstScreen(
        onNext: () => context.go('/onboarding-2'),
        onClose: () => context.go('/onboarding-3'),
      ),
    ),
    GoRoute(
      path: '/onboarding-2',
      builder: (context, state) => OnboardingSecondScreen(
        onNext: () => context.go('/onboarding-3'),
        onBack: () => context.go('/onboarding-1'),
        onClose: () => context.go('/onboarding-3'),
      ),
    ),
    GoRoute(
      path: '/onboarding-3',
      builder: (context, state) => OnboardingThirdScreen(
        onBack: () => context.go('/onboarding-2'),
        onFinish: () {
          // Changed to loop back to start or navigate to a Sign-In page
          context.go('/onboarding-1');
        },
      ),
    ),
  ],
);
