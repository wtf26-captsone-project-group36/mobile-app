import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _progressOpacity;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startBootFlow();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _logoScale = Tween(
      begin: 0.86,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6)),
    );

    _progressOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0)),
    );

    _controller.forward();
  }

  /// This is where future app boot logic will live
  Future<void> _startBootFlow() async {
    // Ensure splash is visible long enough to feel intentional
    const minimumSplashTime = Duration(seconds: 2);

    final stopwatch = Stopwatch()..start();

    // 🔮 FUTURE:
    // await initializeFirebase();
    // await loadUserSession();
    // await warmUpLocalDatabase();

    // Simulated tiny startup work
    await Future.delayed(const Duration(milliseconds: 600));

    // Guarantee minimum display time
    final remainingTime =
        minimumSplashTime -
        Duration(milliseconds: stopwatch.elapsedMilliseconds);

    if (remainingTime > Duration.zero) {
      await Future.delayed(remainingTime);
    }

    if (!mounted) return;

    _routeFromSplash();
  }

  /// Smart routing (expand later easily)
  void _routeFromSplash() {
    _resolveStartupRoute();
  }

  Future<void> _resolveStartupRoute() async {
    final hasSeenOnboarding = await AppSessionStore.instance
        .hasSeenOnboarding();
    final isLoggedIn = await AppSessionStore.instance.isLoggedIn();

    if (!mounted) return;

    if (!hasSeenOnboarding) {
      context.go('/onboarding-1');
      return;
    }

    if (isLoggedIn) {
      context.go('/dashboard');
      return;
    }

    context.go('/landing');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // MUST match native splash color
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _logoOpacity,
              child: ScaleTransition(
                scale: _logoScale,
                child: Image.asset('assets/whitetintborderico.png', width: 130),
              ),
            ),

            const SizedBox(height: 32),

            FadeTransition(
              opacity: _progressOpacity,
              child: const _ElegantLoader(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom minimal premium loader
class _ElegantLoader extends StatefulWidget {
  const _ElegantLoader();

  @override
  State<_ElegantLoader> createState() => _ElegantLoaderState();
}

class _ElegantLoaderState extends State<_ElegantLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _widthAnim = Tween(
      begin: 40.0,
      end: 90.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnim,
      builder: (_, __) => Container(
        width: _widthAnim.value,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
