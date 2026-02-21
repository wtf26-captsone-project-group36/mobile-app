import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ImpactDashboardPage extends StatelessWidget {
  const ImpactDashboardPage({super.key});

  final Color primaryGreen = const Color(0xFF006B4D);
  final Color creamBg = const Color(0xFFFDFBF7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBg,
      appBar: AppBar(
        title: const Text("Sustainability Impact", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroStats(),
            const SizedBox(height: 24),
            const Text("Detailed Metrics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildMetricGrid(),
            const SizedBox(height: 32),
            const Text("Beneficiary Partners", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildPartnerList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: const NetworkImage('https://www.transparenttextures.com/patterns/leaf.png'),
          opacity: 0.1,
          repeat: ImageRepeat.repeat,
        ),
      ),
      child: Column(
        children: [
          const Text("Total Food Value Saved", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          const Text("₦1,240,500", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
            child: const Text("Top 5% of Sustainable Retailers", style: TextStyle(color: Colors.white, fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildMetricGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildSmallStatCard("CO2 Avoided", "420 kg", Icons.cloud_done_outlined, Colors.blue),
        _buildSmallStatCard("Meals Provided", "1,850", Icons.restaurant, Colors.orange),
        _buildSmallStatCard("Waste Diverted", "92%", Icons.recycling, Colors.green),
        _buildSmallStatCard("Social Credits", "2,400", Icons.stars, Colors.amber),
      ],
    );
  }

  Widget _buildSmallStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildPartnerList() {
    final partners = [
      {"name": "Lagos Food Bank", "count": "12 Donations"},
      {"name": "Hope IDP Camp", "count": "5 Donations"},
      {"name": "GreenLife Kitchen", "count": "8 Donations"},
    ];

    return Column(
      children: partners.map((p) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: const CircleAvatar(backgroundColor: Color(0xFFE0F2F1), child: Icon(Icons.business, color: Color(0xFF006B4D))),
          title: Text(p['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(p['count']!, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, size: 16),
        ),
      )).toList(),
    );
  }
}