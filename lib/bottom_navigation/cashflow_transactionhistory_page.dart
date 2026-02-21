import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        title: const Text("Transaction", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black), // Filter icon
            onPressed: () {}, 
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
              child: Text(
                "All income and expenses",
                style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 14),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildDateSection("Today, Feb 21"),
                  _buildTransactionItem(
                    label: "Bank Transfer",
                    sub: "Fresh product purchase",
                    amount: "₦ 10,000",
                    isIncome: true,
                  ),
                  _buildTransactionItem(
                    label: "Inventory Purchase",
                    sub: "Invoice #12345",
                    amount: "₦ 30,000",
                    isIncome: false,
                  ),
                  const SizedBox(height: 20),
                  _buildDateSection("Thursday, Jan 12"),
                  _buildTransactionItem(
                    label: "Electricity",
                    sub: "Utilities",
                    amount: "₦ 10,000",
                    isIncome: false,
                  ),
                  _buildTransactionItem(
                    label: "Rent",
                    sub: "Monthly Office",
                    amount: "₦ 120,000",
                    isIncome: false,
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildTransactionItem({
    required String label,
    required String sub,
    required String amount,
    required bool isIncome,
  }) {
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
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}