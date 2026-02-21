import 'package:flutter/material.dart';
import 'package:hervest_ai/provider/inventory_provider.dart';
import 'package:provider/provider.dart';

import 'package:hervest_ai/models/inventory_model.dart';

class SuggestionsScreen extends StatelessWidget {
  const SuggestionsScreen({super.key});

  final Color primaryGreen = const Color(0xFF006B4D);
  final Color creamBg = const Color(0xFFFDFBF7);
  final Color accentOrange = const Color(0xFFFF9800);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    // Logic: Filter items that are actually expiring or need action
    final expiringItems = provider.items.where((item) {
      if (item.expiryDate == null) return false;
      // Items expired or expiring in the next 7 days
      return item.expiryDate!.difference(DateTime.now()).inDays <= 7;
    }).toList();

    return Scaffold(
      backgroundColor: creamBg,
      appBar: AppBar(
        title: const Text("AI Suggestions", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: expiringItems.isEmpty
          ? _buildEmptyState()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAIBanner(expiringItems.length),
                  const SizedBox(height: 20),
                  const Text(
                    "Recommended Actions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: expiringItems.length,
                      itemBuilder: (context, index) {
                        return _buildSuggestionCard(expiringItems[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAIBanner(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Hervest AI found $count items that can be diverted to community partners to avoid 100% loss.",
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(InventoryItem item) {
    // Smart Logic: Assign a "Donee" based on the Category in the JSON
    String donee = "Local Food Bank";
    IconData doneeIcon = Icons.store_mall_directory;

    if (item.category == 'Grains & Cereals') {
      donee = "IDP Camp Central";
      doneeIcon = Icons.foundation;
    } else if (item.category == 'Fresh Produce') {
      donee = "Community Soup Kitchen";
      doneeIcon = Icons.soup_kitchen;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("${item.quantity} ${item.unit} • ${item.category}", 
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: accentOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text("Expiring Soon", style: TextStyle(color: accentOrange, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade100,
                  child: Icon(doneeIcon, color: primaryGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Suggested Donee", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text(donee, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {}, // Link to Logistics/Delivery later
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Donate", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No items at risk!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Text("Your current inventory is fresh and stable.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}


/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hervest_ai//provider/inventory_provider.dart';
import 'package:hervest_ai/features/inventory/services/suggestion_service.dart';

class SuggestionsPage extends StatelessWidget {
  const SuggestionsPage({super.key});

  final Color primaryGreen = const Color(0xFF006B4D);
  final Color creamBg = const Color(0xFFFDFBF7);

  @override
  Widget build(BuildContext context) {
    // Access the provider to see what is expiring soon
    final provider = Provider.of<InventoryProvider>(context);
    final itemsToDonate = provider.soonToExpire; // Our 3-day logic from earlier

    return Scaffold(
      backgroundColor: creamBg,
      appBar: AppBar(
        title: const Text("AI Suggestions", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: itemsToDonate.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: itemsToDonate.length,
              itemBuilder: (context, index) {
                final item = itemsToDonate[index];
                final donees = SuggestionService.getDoneesForCategory(item.category);

                return _buildSuggestionCard(item, donees);
              },
            ),
    );
  }

  Widget _buildSuggestionCard(item, List<String> donees) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFFFF3E0), child: Icon(Icons.auto_awesome, color: Colors.orange)),
            title: Text("Optimize ${item.name}", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Expiring in ${item.expiryDate?.difference(DateTime.now()).inDays} days"),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("AI Recommended Donees:", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                // Loop through the suggested beneficiaries for this category
                ...donees.map((center) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Color(0xFF006B4D)),
                      const SizedBox(width: 8),
                      Text(center, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
          // Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () {}, // Link to maps or logistics later
                child: const Text("Arrange Pickup", style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text("No immediate actions needed!", style: TextStyle(color: Colors.grey, fontSize: 16)),
          Text("Your inventory is currently optimized.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
} */