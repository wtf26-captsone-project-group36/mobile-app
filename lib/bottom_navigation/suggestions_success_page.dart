import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SuggestionSuccessPage extends StatelessWidget {
  const SuggestionSuccessPage({super.key});

  final Color primaryGreen = const Color(0xFF006B4D);
  final Color creamBg = const Color(0xFFFDFBF7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Celebration Graphic
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Icon(Icons.celebration, size: 60, color: Colors.blue),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                "Handshake Confirmed!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "The partner has been notified. Your inventory will be updated automatically once the pickup is confirmed.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 40),
              
              // Impact Reward Card
              _buildImpactRewardCard(),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => context.go('/dashboard'),
                  child: const Text("Return to Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.push('/impact-stats'),
                child: Text("View Lifetime Impact", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImpactRewardCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars, color: Colors.amber, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Social Credit Earned", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const Text("+50 Points", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                Text("You've helped 20+ people today", style: TextStyle(fontSize: 11, color: Colors.blue.shade700)),
              ],
            ),
          )
        ],
      ),
    );
  }
}