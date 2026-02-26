import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:hervest_ai/provider/app_state_controller_mock.dart';

class CashflowScreen extends StatelessWidget {
  const CashflowScreen({super.key});

  final Color primaryGreen = const Color(0xFF006B4D);
  final Color bgCream = const Color(0xFFFDFBF7);

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: Consumer<AppStateController>(
          builder: (context, state, child) {
            final totals = _totalsFromState(state);
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  // NEW: Show anomaly alert if present
                  if (state.anomalies.isNotEmpty)
                    _buildAnomalyBanner(context, state.anomalies.first),
                  
                  const SizedBox(height: 24),
                  _buildBalanceCard(width, totals.net),
                  const SizedBox(height: 20),
                  _buildRunwayCard(totals),
                  const SizedBox(height: 20),
                  _buildActionButtons(context),
                  const SizedBox(height: 16),
                  _buildFinanceTools(context),
                  const SizedBox(height: 32),
                  _buildAiInsightsLink(context), // NEW: Link to full insights
                  const SizedBox(height: 18),
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

  Widget _buildBalanceCard(double width, double netBalance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Updated today", style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            "₦ ${_formatAmount(netBalance)}",
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text("Available balance", style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            label: "Add income",
            icon: Icons.add,
            color: const Color(0xFFE0F2F1),
            textColor: primaryGreen,
            onTap: () => context.push('/cashflow/add-income'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            label: "Add expense",
            icon: Icons.remove,
            color: const Color(0xFFFFEBEE),
            textColor: Colors.red,
            onTap: () => context.push('/cashflow/add-expense'),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Text("Cashflow", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold));
  }

  // NEW: Anomaly Banner Widget
  Widget _buildAnomalyBanner(BuildContext context, Map<String, dynamic> anomaly) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              anomaly['message'] ?? "Unusual spending detected",
              style: TextStyle(color: Colors.red.shade900, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.red),
        ],
      ),
    );
  }

  // NEW: Link to AI Insights Page
  Widget _buildAiInsightsLink(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/ai-insights'), // Ensure this route is added to router
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD), // Light Blue
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("AI Business Insights", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                    Text("View forecasts & risk analysis", style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
                  ],
                ),
              ],
            ),
            Icon(Icons.arrow_forward, color: Colors.blue.shade700),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceTools(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/cashflow/budgets'),
            icon: const Icon(Icons.savings_outlined),
            label: const Text('Budgets'),
          ),
        ),
        const SizedBox(width: 10),
        /*Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/cashflow/expenses'),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Expenses'),
          ),
        ),
      */ ],
    );
  } 

  Widget _buildRunwayCard(_CashflowTotals totals) {
    final bool positive = totals.net >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            positive ? Icons.trending_up : Icons.trending_down,
            color: positive ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Cashflow Summary",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  positive ? "Net surplus" : "Net deficit",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Income ₦${_formatAmount(totals.income)} • Expenses ₦${_formatAmount(totals.expense)}",
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Recent Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(onPressed: () => context.push('/cashflow/transactions'), child: const Text("View all")),
      ],
    );
  }

  Widget _buildTransactionList(List<Map<String, dynamic>> transactions) {
    if (transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          "No transactions yet.",
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    final recent = transactions.take(3).toList();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recent.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
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
          title: Text(t['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(t['date'] as String),
          trailing: Text(
            t['amount'] as String,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  _CashflowTotals _calculateTotals(List<Map<String, dynamic>> transactions) {
    double income = 0;
    double expense = 0;
    for (final t in transactions) {
      final isIncome = (t['type'] as String).toLowerCase() == 'income';
      final amount = _parseAmount(t['amount'] as String);
      if (isIncome) {
        income += amount;
      } else {
        expense += amount;
      }
    }
    return _CashflowTotals(income: income, expense: expense, net: income - expense);
  }

  _CashflowTotals _totalsFromState(AppStateController state) {
    final report = state.cashflowReport;
    if (report.isNotEmpty) {
      final income = (report['total_income'] as num?)?.toDouble() ?? 0;
      final expense = (report['total_expenses'] as num?)?.toDouble() ?? 0;
      final net = (report['net_balance'] as num?)?.toDouble() ?? (income - expense);
      return _CashflowTotals(income: income, expense: expense, net: net);
    }
    return _calculateTotals(state.transactions);
  }

  double _parseAmount(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  String _formatAmount(double value) {
    final intValue = value.round();
    final str = intValue.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final position = str.length - i;
      buffer.write(str[i]);
      if (position > 1 && position % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }
}

class _CashflowTotals {
  _CashflowTotals({required this.income, required this.expense, required this.net});

  final double income;
  final double expense;
  final double net;
}
