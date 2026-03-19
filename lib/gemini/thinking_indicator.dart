import 'package:flutter/material.dart';

class ThinkingIndicator extends StatefulWidget {
  const ThinkingIndicator({super.key});

  @override
  State<ThinkingIndicator> createState() =>
      _ThinkingIndicatorState();
}

class _ThinkingIndicatorState
    extends State<ThinkingIndicator>
    with TickerProviderStateMixin {
  late AnimationController c;

  @override
  void initState() {
    super.initState();

    c = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: 700),
    )..repeat();
  }

  Widget dot(double delay) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.5,
        end: 1.3,
      ).animate(
        CurvedAnimation(
          parent: c,
          curve: Interval(
            delay,
            1,
            curve: Curves.easeInOut,
          ),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(3),
        child: CircleAvatar(
          radius: 3,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.auto_awesome,
          color: Colors.white,
        ),
        const SizedBox(width: 8),
        dot(0),
        dot(0.3),
        dot(0.6),
      ],
    );
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }
}
