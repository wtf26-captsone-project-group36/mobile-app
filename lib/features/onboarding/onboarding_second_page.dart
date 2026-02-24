import 'package:flutter/material.dart';
import 'package:hervest_ai/widgets/onboarding_asset_image.dart';
import 'package:hervest_ai/widgets/onboarding_indicator.dart';

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
    return Scaffold(
      body: Stack(
        children: [
          /// Full background image
          Positioned.fill(
            child: const OnboardingAssetImage(
              assetPath: 'assets/mainmarketonbo.png',
              fit: BoxFit.cover,
              placeholderColor: Colors.black,
            ),
          ),

          /// Bottom dark gradient overlay (same as screen 3)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.45, 0.72, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.88),
                  ],
                ),
              ),
            ),
          ),

          /// Close button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: onClose,
                ),
              ),
            ),
          ),

          /// Bottom Content
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Page indicator (white cinematic style)
                    const OnboardingIndicator(
                      currentIndex: 1,
                      total: 3,
                      activeColor: Colors.white,
                      inactiveColor: Color(0x66FFFFFF),
                    ),

                    const SizedBox(height: 20),

                    /// Glass Card with content from screen 2
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 22,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.48),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Reduce Waste. Share Surplus. Grow Smart.",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            "List near-expiry items, recover value, and help other businesses while reducing food waste.",
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),

                          SizedBox(height: 20),

                          /// Steps inside glass card
                          _StepRow(
                            number: "1",
                            text: "AI detects near-expiry inventory & gives suggestions",
                          ),
                          SizedBox(height: 14),
                          _StepRow(
                            number: "2",
                            text: "Export Inventory & Cashflow Reports",
                          ),
                          SizedBox(height: 14),
                          _StepRow(
                            number: "3",
                            text: "Recover value & reduce waste",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Navigation Buttons (cinematic style)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onBack,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Colors.white,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: const Text(
                              'Back',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: onNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2A8C68),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 18),
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
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}







/*class OnboardingSecondScreen extends StatelessWidget {
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
*/
