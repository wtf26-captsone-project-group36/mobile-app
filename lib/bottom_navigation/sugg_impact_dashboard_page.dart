import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/features/rescue/models/rescue_models.dart';
import 'package:hervest_ai/provider/rescue_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ImpactDashboardPage extends StatelessWidget {
  const ImpactDashboardPage({super.key});

  static const Color _primaryGreen = Color(0xFF006B4D);
  static const Color _creamBg = Color(0xFFFDFBF7);

  @override
  Widget build(BuildContext context) {
    final rescue = context.watch<RescueProvider>();
    final metrics = rescue.impactMetrics;
    final badges = rescue.earnedBadgeCodes;

    return Scaffold(
      backgroundColor: _creamBg,
      appBar: AppBar(
        title: const Text(
          'Sustainability Impact',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: !rescue.isReady
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(metrics),
                  const SizedBox(height: 22),
                  const Text(
                    'Detailed Metrics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  _buildMetricGrid(metrics),
                  const SizedBox(height: 24),
                  _buildMilestoneCard(metrics, rescue.nextBadgeThreshold),
                  const SizedBox(height: 20),
                  const Text(
                    'Earned Badges',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildBadgeList(badges),
                ],
              ),
            ),
    );
  }

  Widget _buildHero(ImpactMetrics metrics) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primaryGreen,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Text(
            'Total Value Recovered',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'NGN ${NumberFormat('#,##0.00').format(metrics.totalValueRecovered)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${metrics.totalCompletedRescues} completed rescues',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGrid(ImpactMetrics metrics) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _metricCard(
          label: 'CO2 Avoided',
          value: '${metrics.totalCo2AvoidedKg.toStringAsFixed(1)} kg',
          icon: Icons.cloud_done_outlined,
          color: Colors.blue,
        ),
        _metricCard(
          label: 'Donations',
          value: metrics.totalDonations.toString(),
          icon: Icons.favorite_border,
          color: Colors.redAccent,
        ),
        _metricCard(
          label: 'Surplus Sales',
          value: metrics.totalSurplusSales.toString(),
          icon: Icons.sell_outlined,
          color: Colors.deepOrange,
        ),
        _metricCard(
          label: 'Total Rescues',
          value: metrics.totalCompletedRescues.toString(),
          icon: Icons.inventory_2_outlined,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(ImpactMetrics metrics, int nextBadgeThreshold) {
    final remaining = nextBadgeThreshold - metrics.totalDonations;
    final progress = nextBadgeThreshold == 0
        ? 1.0
        : (metrics.totalDonations / nextBadgeThreshold).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Donation Milestone',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            remaining <= 0
                ? 'You reached this milestone.'
                : '$remaining donation(s) to next badge at $nextBadgeThreshold.',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            color: Colors.amber,
            backgroundColor: Colors.amber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(999),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeList(Set<String> earnedBadgeCodes) {
    return Column(
      children: RescueProvider.allBadges.map((badge) {
        final earned = earnedBadgeCodes.contains(badge.code);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: earned
                  ? Colors.amber.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              child: Icon(
                earned ? Icons.workspace_premium_rounded : Icons.lock_outline,
                color: earned ? Colors.amber.shade800 : Colors.black45,
              ),
            ),
            title: Text(badge.title),
            subtitle: Text('${badge.threshold} completed donations'),
            trailing: Text(
              earned ? 'Earned' : 'Locked',
              style: TextStyle(
                color: earned ? Colors.green : Colors.black45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
