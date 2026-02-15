import 'package:flutter/material.dart';

class OnboardingSecondScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const OnboardingSecondScreen({
    super.key,
    required this.onNext,
    required this.onBack,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              /// Top Close Button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ),

              const SizedBox(height: 16),

              /// Circular Icon
              Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.orange.shade400,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  size: 70,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              /// Page Indicator (BELOW ICON)
              const _OnboardingIndicator(
                currentIndex: 1,
                total: 3,
              ),

              const SizedBox(height: 32),

              /// Title
              Text(
                "Reduce Waste. Share Surplus. Grow Smart.",
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              /// Subtitle
              Text(
                "List near-expiry items, recover value, and help other businesses while reducing food waste.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 28),

              /// Steps Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: const [
                    _StepRow(
                      number: "1",
                      text: "AI detects near-expiry inventory",
                    ),
                    SizedBox(height: 18),
                    _StepRow(
                      number: "2",
                      text: "List items on Surplus Marketplace",
                    ),
                    SizedBox(height: 18),
                    _StepRow(
                      number: "3",
                      text: "Recover value & reduce waste",
                    ),
                  ],
                ),
              ),

              const Spacer(),

              /// Navigation Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onBack,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.green.shade700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        "Back",
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 86, 172, 90),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("Next"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicator Widget
class _OnboardingIndicator extends StatelessWidget {
  final int currentIndex;
  final int total;

  const _OnboardingIndicator({
    required this.currentIndex,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        total,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          height: 8,
          width: currentIndex == index ? 20 : 8,
          decoration: BoxDecoration(
            color: currentIndex == index
                ? Colors.green.shade700
                : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

/// Step Row Widget
class _StepRow extends StatelessWidget {
  final String number;
  final String text;

  const _StepRow({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.green.shade700,
          child: Text(
            number,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }
}
