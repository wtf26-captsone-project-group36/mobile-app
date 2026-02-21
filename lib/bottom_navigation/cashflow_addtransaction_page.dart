import 'package:flutter/material.dart';
import 'package:hervest_ai/widgets/app_input_styles.dart';

class AddTransactionPage extends StatelessWidget {
  final bool isExpense;
  const AddTransactionPage({super.key, required this.isExpense});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isExpense ? "Add Expense" : "Add Income")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildAmountInput(),
              const SizedBox(height: 24),
              _buildTextField("Category", "Select a category"),
              const SizedBox(height: 16),
              _buildTextField("Date", "Today, Feb 10"),
              const Spacer(),
              _buildSubmitButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return TextField(
      decoration: AppInputStyles.decoration(labelText: 'Amount'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  Widget _buildTextField(String label, String hint) {
    return TextField(
      decoration: AppInputStyles.decoration(labelText: label, hintText: hint),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return ElevatedButton(onPressed: () {}, child: const Text('Submit'));
  }
}
