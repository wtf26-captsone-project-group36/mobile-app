import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:hervest_ai/provider/app_state_controller_mock.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  final Color primaryGreen = const Color(0xFF006B4D);
  final Color bgCream = const Color(0xFFFDFBF7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Transactions",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<AppStateController>(
          builder: (context, state, child) {
            final transactions = state.transactions;
            if (transactions.isEmpty) {
              return const Center(
                child: Text(
                  "No transactions yet.",
                  style: TextStyle(color: Colors.black54),
                ),
              );
            }

            final grouped = _groupByDate(transactions);
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: grouped.entries.expand((entry) {
                final date = entry.key;
                final items = entry.value;
                return [
                  _buildDateSection(date),
                  ...items.map(_buildTransactionItem).toList(),
                  const SizedBox(height: 12),
                ];
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDateSection(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        date,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> t) {
    final isIncome = (t['type'] as String).toLowerCase() == 'income';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isIncome ? const Color(0xFFE0F2F1) : const Color(0xFFFFEBEE),
            child: Icon(
              isIncome ? Icons.swap_horiz : Icons.shopping_bag_outlined,
              color: isIncome ? primaryGreen : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(t['type'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text(
            t['amount'] as String,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(
    List<Map<String, dynamic>> transactions,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final t in transactions) {
      final date = (t['date'] as String?) ?? 'Unknown date';
      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add(t);
    }
    return grouped;
  }
}
