import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hervest_ai/provider/inventory_provider.dart';

class InventoryPageFour extends StatelessWidget {
  const InventoryPageFour({super.key});

  final Color creamBg = const Color(0xFFFDFBF7);
  final Color primaryGreen = const Color(0xFF006B4D);

  @override
  Widget build(BuildContext context) {
    // 1. Access the real-time financial data from the provider
    final provider = context.watch<InventoryProvider>();
    final int totalItems = provider.items.length;
    final double totalValue = provider.totalLedgerValue;
    final int optimizationCount = provider.donationSuggestions.length;

    // Currency formatter for Naira
    final currencyFormat = NumberFormat.currency(symbol: '₦', decimalDigits: 0);

    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: creamBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Graphic
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, size: 80, color: primaryGreen),
              ),
              const SizedBox(height: 32),
              
              const Text(
                "Inventory Updated!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              // 2. Dynamic message based on AI Optimization logic
              Text(
                optimizationCount > 0 
                  ? "Your smart ledger is synced. We've identified $optimizationCount items for immediate donation or use."
                  : "Your smart ledger is synchronized and your stock levels look healthy!",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 16, height: 1.5),
              ),
              
              const SizedBox(height: 40),
              
              // 3. Impact Card using Provider data
              _buildImpactCard(width, totalItems, currencyFormat.format(totalValue)),
              
              const SizedBox(height: 40),
              
              // Primary Action
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => context.go('/dashboard'),
                  child: const Text(
                    "Back to Dashboard",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 4. Conditional AI Suggestion Button
              if (optimizationCount > 0)
                TextButton(
                  onPressed: () => context.go('/suggestions'),
                  child: Text(
                    "View $optimizationCount AI Suggestions",
                    style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImpactCard(double width, int itemCount, String value) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn("Total Items", "$itemCount"),
          Container(height: 40, width: 1, color: Colors.grey.shade200),
          _buildStatColumn("Ledger Value", value),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: primaryGreen, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}