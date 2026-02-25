import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:hervest_ai/provider/app_state_controller_mock.dart';

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
        child: Consumer<AppStateController>(
          builder: (context, state, child) {
            final totals = _calculateTotals(state);
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildAppBar(),
                  const SizedBox(height: 24),
                  _buildBalanceCard(width, totals['net']!),
                  const SizedBox(height: 20),
                  _buildRunwayCard(totals['net']! >= 0),
                  const SizedBox(height: 24),
                  _buildIncomeExpenseSummary(totals['income']!, totals['expense']!),
                  const SizedBox(height: 32),
                  _buildRecentTransactionsHeader(context),
                  _buildTransactionList(state.transactions),
                ],
              ),
            );
          },
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

  Widget _buildBalanceCard(double width, double balance) {
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
              Text("₦ ${_formatAmount(balance)}", 
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              Icon(Icons.visibility_outlined, color: Colors.white.withValues(alpha: 0.7)),
            ],
          ),
          const SizedBox(height: 4),
          const Text("Available balance", 
              style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRunwayCard(bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: isPositive ? Colors.green : Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Cash runway", style: TextStyle(fontSize: 12, color: Colors.black54)),
                Text(isPositive ? "Healthy" : "Attention needed", style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text("Based on your average daily spending", style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          if (isPositive)
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

  Widget _buildIncomeExpenseSummary(double income, double expense) {
    return Row(
      children: [
        Expanded(child: _summaryBox("Income", "₦ ${_formatAmount(income)}", true)),
        const SizedBox(width: 16),
        Expanded(child: _summaryBox("Expenses", "₦ ${_formatAmount(expense)}", false)),
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

  Widget _buildTransactionList(List<Map<String, dynamic>> transactions) {
    if (transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 20),
        child: Text("No recent transactions", style: TextStyle(color: Colors.grey)),
      );
    }

    final recent = transactions.take(3).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recent.length,
      itemBuilder: (context, index) {
        final t = recent[index];
        final isIncome = (t['type'] as String).toLowerCase() == 'income';
        
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: isIncome ? const Color(0xFFE0F2F1) : const Color(0xFFFFEBEE),
            child: Icon(
              isIncome ? Icons.swap_horiz : Icons.shopping_bag_outlined,
              color: isIncome ? primaryGreen : Colors.red,
              size: 18,
            ),
          ),
          title: Text(t['title'] ?? 'Transaction', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("${t['type']} • ${t['date']}"),
          trailing: Text(t['amount'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  Map<String, double> _calculateTotals(AppStateController state) {
    // Use report if available, otherwise calculate from transactions
    if (state.cashflowReport.isNotEmpty) {
      return {
        'income': (state.cashflowReport['total_income'] as num?)?.toDouble() ?? 0.0,
        'expense': (state.cashflowReport['total_expenses'] as num?)?.toDouble() ?? 0.0,
        'net': (state.cashflowReport['net_balance'] as num?)?.toDouble() ?? 0.0,
      };
    }
    return {'income': 0.0, 'expense': 0.0, 'net': 0.0};
  }

  String _formatAmount(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}
