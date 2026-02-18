import 'package:flutter/material.dart';
import 'package:hervest_ai/widgets/onboarding_asset_image.dart';
import 'package:hervest_ai/widgets/onboarding_indicator.dart';

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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// Full-bleed bkgd image
          Positioned.fill(
            child: const OnboardingAssetImage(
              assetPath: 'assets/eggsonbo.png',
              fit: BoxFit.cover,
              placeholderColor: Colors.black,
            ),
          ),

          /// 2. Gradient overlay — transparent at top, dark at bottom
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

          /// 3. Close button (top right)i
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: onClose ?? onFinish,
                ),
              ),
            ),
          ),

          /// 4. Bottom content
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
                    /// Page indicator — white dots on dark bg, left-aligned
                    /// to match screen 1's indicator style
                    const OnboardingIndicator(
                      currentIndex: 2,
                      total: 3,
                      activeColor: Colors.white,
                      inactiveColor: Color(0x66FFFFFF),
                    ),

                    const SizedBox(height: 20),

                    /// Text card with frosted dark background
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
                            'Get Smart Alerts',
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
                            'Receive Notification For Items Nearing Expiry And Potential Waste Risks.',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Navigation buttons — Back (outlined) + Get Started (teal pill)
                    Row(
                      children: [
                        /// Back — mirrors the outlined style from screen 2
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

                        /// Get Started — teal pill 
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: onFinish,
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
                                  'Get Started',
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

/*class OnboardingThirdScreen extends StatelessWidget {
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
*/
