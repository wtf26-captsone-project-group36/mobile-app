import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hervest_ai/models/inventory_model.dart';

class SuggestionsLogisticsPage extends StatelessWidget {
  final InventoryItem item;
  final String suggestedDonee;

  const SuggestionsLogisticsPage({
    super.key, 
    required this.item, 
    required this.suggestedDonee
  });

  final Color primaryGreen = const Color(0xFF006B4D);
  final Color creamBg = const Color(0xFFFDFBF7);

  // Source: Simplified CO2e factors (kg CO2e per kg of food) based on industry averages.
  // In a full-scale app, this could be fetched from a remote configuration.
  static const Map<String, double> _co2eFactors = {
    'Fresh Produce': 0.5,
    'Beverages': 0.8,
    'Grains & Cereals': 0.7,
    'Meat & Poultry': 7.5, // Higher impact
    'Dairy': 3.2,
    'Baked Goods': 1.0,
    'Frozen Foods': 1.5,
    'Canned Goods': 1.2,
    'Spices & Seasonings': 0.9,
    'Oils & Sauces': 2.0,
    'Snacks': 1.8,
    'Other': 1.5, // A general average
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBg,
      appBar: AppBar(
        title: const Text("Confirm Donation", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 32),
              const Text("Pickup Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildPickupOption(
                title: "NGO Pickup",
                subtitle: "The partner will come to your location.",
                icon: Icons.local_shipping_outlined,
                isSelected: true,
              ),
              _buildPickupOption(
                title: "Self-Drop",
                subtitle: "You deliver to the partner's hub.",
                icon: Icons.storefront_outlined,
                isSelected: false,
              ),
              const SizedBox(height: 32),
              _buildImpactPreview(),
              const SizedBox(height: 40),
              _buildActionButtons(context),
            ],
        ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: Colors.grey),
              const SizedBox(width: 12),
              Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 30),
          _buildRow("Quantity", "${item.quantity} ${item.unit}"),
          _buildRow("Destination", suggestedDonee),
          _buildRow("Estimated Value", "₦${NumberFormat('#,###').format(item.purchasePrice ?? 0)}"),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPickupOption({required String title, required String subtitle, required IconData icon, required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? primaryGreen.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? primaryGreen : Colors.grey.shade200, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: isSelected ? primaryGreen : Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          if (isSelected) Icon(Icons.check_circle, color: primaryGreen),
        ],
      ),
    );
  }

  Widget _buildImpactPreview() {
    final co2Savings = _calculateCo2Savings(item);
    final message = co2Savings != null
        ? "By donating, you are preventing carbon emissions equivalent to ${co2Savings.toStringAsFixed(1)}kg of CO2."
        : "Donating this item helps reduce food waste and its environmental impact.";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.volunteer_activism, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1565C0)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => context.go('/inventory/donation-success', extra: item),
        child: const Text("Confirm & Notify Partner", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  /// Calculates the estimated CO2 savings in kg.
  /// Returns null if a reliable calculation cannot be made.
  double? _calculateCo2Savings(InventoryItem item) {
    double? weightInKg;
    final unit = item.unit.toLowerCase();

    if (unit.contains('kg')) {
      weightInKg = item.quantity;
    } else if (unit == 'g' || unit == 'grams') {
      weightInKg = item.quantity / 1000.0;
    }

    // If weight cannot be determined, we can't calculate CO2 savings.
    if (weightInKg == null) {
      return null;
    }

    final factor = _co2eFactors[item.category] ?? _co2eFactors['Other']!;
    return weightInKg * factor;
  }
}