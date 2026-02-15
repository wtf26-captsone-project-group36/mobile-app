import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    
    // 1. Start the animation after a brief moment
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
          _scale = 1.0;
        });
      }
    });

    // 2. Wait for 3 seconds, then navigate to onboarding
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        context.go('/onboarding-1');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      body: Center(
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutBack, // This adds the "bouncy" feel
          child: AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(milliseconds: 1000),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                
                Image.asset(
                  'assets/green_boxplant.png',
                  width: 120,                                             // Adjust size
                ),
                const SizedBox(height: 20),
                // Optional: A thin, elegant loader that matches your green theme
                SizedBox(
                  width: 40,
                  child: LinearProgressIndicator(
                    color: Colors.green,
                    backgroundColor: Colors.green.withOpacity(0.3), // Used a lighter green or grey
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