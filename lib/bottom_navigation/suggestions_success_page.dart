import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/models/inventory_model.dart';
import 'package:intl/intl.dart';

class SuggestionSuccessPage extends StatelessWidget {
  final InventoryItem? item;
  const SuggestionSuccessPage({super.key, this.item});

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
                      color: Colors.blue.withValues(alpha: 0.1),
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
    final double value = item?.purchasePrice ?? 0;
    // Simple formula: 1 point per 100 NGN of value, with a minimum of 5 points.
    final int points = value > 0 ? (value / 100).ceil().clamp(5, 1000) : 5;
    // Simple formula: 1 person helped per 5000 NGN value.
    final int peopleHelped = (value / 5000).floor();
    final currencyFormat = NumberFormat.currency(symbol: '₦', decimalDigits: 0);

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
                Text("+$points Points", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                Text(
                  peopleHelped > 0 ? "You've helped $peopleHelped+ people today!" : "Donation value: ${currencyFormat.format(value)}",
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}