import 'package:flutter/material.dart';
import 'package:hervest_ai/widgets/onboarding_asset_image.dart';
import 'package:hervest_ai/widgets/onboarding_indicator.dart';


class OnboardingFirstScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onClose;
  final VoidCallback onSkip;

  const OnboardingFirstScreen({
    super.key,
    required this.onNext,
    required this.onClose,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// Close Button
              Row(
                children: [
                  TextButton(
                    onPressed: onSkip,
                    child: const Text(
                      'Skip',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// Title
              Text(
                "Track Inventory, Cashflow & AI Risks",
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              /// Subtitle
              Text(
                "Monitor your inventory in real-time, track expenses, and get AI-powered alerts before problems arise.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 18),

              /// Page Indicators
              const OnboardingIndicator(
                currentIndex: 0,
                total: 3,
                activeColor: Color(0xFF2A8C68),
                inactiveColor: Color(0xFFD9D9D9),
              ),

              const SizedBox(height: 32),

              /// Image
              SizedBox(
                height: 270,                                                  // ADJUST
                width: double.infinity,
                child: const OnboardingAssetImage(
                  assetPath: 'assets/onbo_grid.png',
                  fit: BoxFit.contain,
                  placeholderColor: Colors.transparent,
                ),
              ),

              const SizedBox(height: 25),

              /// Feature Row
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _FeatureIcon(
                    icon: Icons.trending_up,
                    label: "Cashflow",
                    color: Colors.orange,
                  ),
                  _FeatureIcon(
                    icon: Icons.warning_amber_rounded,
                    label: "AI Alerts",
                    color: Colors.red,
                  ),
                  _FeatureIcon(
                    icon: Icons.shopping_cart_outlined,
                    label: "Inventory",
                    color: Colors.green,
                  ),
                ],
              ),

              const Spacer(),

              /// Next Button
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A8C68),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),               //was 24
            ],
          ),
        ),
      ),
    );
  }
}

/// Feature Icon Widget
class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureIcon({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 28,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

















/*class OnboardingFirstScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onClose;

  const OnboardingFirstScreen({
    super.key,
    required this.onNext,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// Close Button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ),

              const SizedBox(height: 20),

              /// Title
              Text(
                "Track Inventory, Cashflow & AI Risks",
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              /// Subtitle
              Text(
                "Monitor your inventory in real-time, track expenses, and get AI-powered alerts before problems arise.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 24),

              /// Page Indicators (ABOVE IMAGE)
              const OnboardingIndicator(
                currentIndex: 0,
                total: 3,
              ),

              const SizedBox(height: 32),

              /// Illustration
              Container(
                height: 180,
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 40),

              /// Feature Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _FeatureIcon(
                    icon: Icons.trending_up,
                    label: "Cashflow",
                    color: Colors.orange,
                  ),
                  _FeatureIcon(
                    icon: Icons.warning_amber_rounded,
                    label: "AI Alerts",
                    color: Colors.red,
                  ),
                  _FeatureIcon(
                    icon: Icons.shopping_cart_outlined,
                    label: "Inventory",
                    color: Colors.green,
                  ),
                ],
              ),

              const Spacer(),

              /// Next Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 86, 172, 90),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Next",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      ),
                  ),
                ),
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
class OnboardingIndicator extends StatelessWidget {
  final int currentIndex;
  final int total;

  const OnboardingIndicator({
    super.key,
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

/// Feature Icon Widget
class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureIcon({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 28,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
*/
