import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 24),
              _buildBalanceCard(width),
              const SizedBox(height: 20),
              _buildRunwayCard(),
              const SizedBox(height: 20),
              _buildActionButtons(context),
              const SizedBox(height: 32),
              _buildRecentTransactionsHeader(context),
              _buildTransactionList(),
            ],
          ),
        ),
      ),
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
          const Text("Updated today", style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          const Text("₦ 250,000", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
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

  Widget _actionButton({required String label, required IconData icon, required Color color, required Color textColor, required VoidCallback onTap}) {
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

  Widget _buildRunwayCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Text("Runway Card Placeholder"),
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

  Widget _buildTransactionList() {
    return const Text("Transaction List Placeholder");
  }
}