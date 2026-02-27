import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hervest_ai/models/api_response_models.dart';
import 'package:hervest_ai/provider/app_state_controller_mock.dart';

class AiInsightsPage extends StatelessWidget {
  const AiInsightsPage({super.key});

  final Color _bgCream = const Color(0xFFFDFBF7);
  final Color _primaryGreen = const Color(0xFF006B4D);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateController>();
    final cashflowPred = state.cashflowPrediction;
    final inventoryPred = state.inventoryPrediction;

    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        title: const Text("AI Business Insights", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: state.isLoadingInsights
          ? Center(child: CircularProgressIndicator(color: _primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Real-time risk assessment based on your business data.",
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Cashflow Forecast"),
                  _buildCashflowCard(cashflowPred),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Inventory Health"),
                  _buildInventoryCard(inventoryPred),
                  const SizedBox(height: 24),
                  if (state.anomalies.isNotEmpty) ...[
                    _buildSectionTitle("Detected Anomalies"),
                    ...state.anomalies.map(_buildAnomalyTile),
                  ] else if (cashflowPred == null && inventoryPred == null)
                    _buildErrorCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_outlined, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Could not load AI insights. Please check your internet connection and try again later.",
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCashflowCard(CashflowPrediction? data) {
    final riskLevel = (data?.riskLevel ?? 'Unknown').toUpperCase();
    final days = data?.daysUntilBroke ?? 0;
    final confidence = (data?.confidenceScore ?? 0.0) * 100;

    Color riskColor = Colors.green;
    if (riskLevel == 'MEDIUM') riskColor = Colors.orange;
    if (riskLevel == 'HIGH') riskColor = Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Risk Level", style: TextStyle(color: Colors.grey)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: riskColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(riskLevel, style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat("Runway", "$days Days", Icons.timer_outlined),
              _buildStat("Confidence", "${confidence.toStringAsFixed(0)}%", Icons.analytics_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(InventoryPrediction? data) {
    final valueAtRisk = data?.totalValueAtRisk ?? 0.0;
    final critical = data?.criticalItems ?? 0;
    final currency = NumberFormat.currency(symbol: '₦', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primaryGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Total Value at Risk", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(currency.format(valueAtRisk), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
              const SizedBox(width: 8),
              Text("$critical Critical Items need attention", style: const TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 16, color: Colors.grey), const SizedBox(width: 4), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAnomalyTile(Anomaly anomaly) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(anomaly.message, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}