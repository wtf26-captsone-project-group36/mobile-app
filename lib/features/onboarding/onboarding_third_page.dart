import 'package:flutter/material.dart';

class OnboardingThirdScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onFinish;
  final VoidCallback? onClose;

  const OnboardingThirdScreen({
    super.key,
    required this.onBack,
    required this.onFinish,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              /// 1. Top Close Button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose ?? onFinish,
                ),
              ),

              const SizedBox(height: 16),

              /// 2. Circular Icon (Themed to HerVest Green)
              Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.green.shade50, // Soft background
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_outlined, // AI/Smart feel icon
                  size: 70,
                  color: Colors.green.shade700,
                ),
              ),

              const SizedBox(height: 24),

              /// 3. Page Indicator (Maintaining the flow)
              const _OnboardingIndicator(
                currentIndex: 2,
                total: 3,
              ),

              const SizedBox(height: 32),

              /// 4. Title
              Text(
                "Let HerVest AI work for you",
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B2D2A), //forest green
                ),
              ),

              const SizedBox(height: 16),

              /// 5. Subtitle
              Text(
                "Grow smarter, waste less, and thrive as you reap a good harvest.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 25),   //was 32

              /// 6. Steps Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FBF9), // Extremely light green tint
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade50),
                ),
                child: const Column(
                  children: [
                    _StepRow(
                      number: "1",
                      text: "Track Inventory: Never miss an expiry date again",
                    ),
                    SizedBox(height: 18),
                    _StepRow(
                      number: "2",
                      text: "Prevent Food Waste through our Suggestion Engine",
                    ),
                    SizedBox(height: 18),
                    _StepRow(
                      number: "3",
                      text: "Avoid Cashflow Surprises: Know ahead of time, plan accordingly",
                    ),
                  ],
                ),
              ),

              const Spacer(),

              /// 7. Navigation Buttons
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
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: Text(
                        "Back",
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onFinish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: const Text(
                        "Finish",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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

// --- SUPPORTING WIDGETS ---

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
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: currentIndex == index ? 24 : 8, // longer...active indicator
          decoration: BoxDecoration(
            color: currentIndex == index
                ? Colors.green.shade700
                : Colors.green.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

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
        Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(
            color: Colors.green.shade700,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1B2D2A),
            ),
          ),
        ),
      ],
    );
  }
}
