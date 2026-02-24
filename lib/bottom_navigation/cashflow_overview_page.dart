import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CashflowOverviewPage extends StatelessWidget {
  const CashflowOverviewPage({super.key});

  // palette
  final Color primaryGreen = const Color(0xFF006B4D);
  final Color bgCream = const Color(0xFFFDFBF7);
  final Color cardWhite = Colors.white;

  @override
  Widget build(BuildContext context) {
    // Media Query
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildAppBar(),
              const SizedBox(height: 24),
              _buildBalanceCard(width),
              const SizedBox(height: 20),
              _buildRunwayCard(),
              const SizedBox(height: 24),
              _buildIncomeExpenseSummary(),
              const SizedBox(height: 32),
              _buildRecentTransactionsHeader(context),
              _buildTransactionList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Cashflow Setting",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          "Your business financial health at a glance",
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Updated today", 
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("₦ 250,000", 
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              Icon(Icons.visibility_outlined, color: Colors.white.withOpacity(0.7)),
            ],
          ),
          const SizedBox(height: 4),
          const Text("Available balance", 
              style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRunwayCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, color: Colors.green),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Cash runway", style: TextStyle(fontSize: 12, color: Colors.black54)),
                Text("42 days remaining", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Based on your average daily spending", style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.arrow_upward, size: 12, color: Colors.green),
                Text(" Improving", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseSummary() {
    return Row(
      children: [
        Expanded(child: _summaryBox("Income", "₦ 85,000", true)),
        const SizedBox(width: 16),
        Expanded(child: _summaryBox("Expenses", "₦ 150,000", false)),
      ],
    );
  }

  Widget _summaryBox(String label, String amount, bool isIncome) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isIncome ? const Color(0xFFE0F2F1) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isIncome ? Icons.trending_up : Icons.trending_down, 
                  size: 14, color: isIncome ? Colors.green : Colors.red),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Text("This month", style: TextStyle(fontSize: 10, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Recent Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: () => context.push('/cashflow/transactions'),
          child: const Text("View all"),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: Colors.grey.shade100,
            child: const Icon(Icons.bolt, color: Colors.red),
          ),
          title: const Text("Electricity", style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text("Utilities • 3/2/26"),
          trailing: const Text("₦ 10,000", style: TextStyle(fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}
