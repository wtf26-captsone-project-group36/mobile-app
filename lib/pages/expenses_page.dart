import 'package:flutter/material.dart';
import 'package:hervest_ai/provider/app_state_controller_mock.dart';
import 'package:hervest_ai/provider/profile_controller.dart';
import 'package:provider/provider.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppStateController>().loadExpensesFromBackend();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateController>();
    final role = context.watch<ProfileController>().role.toLowerCase();
    final canReview = role == 'owner' || role == 'manager';

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSubmitDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Submit Expense'),
      ),
      body: SafeArea(
        child: Column(
        children: [
          if (state.expenseSummary.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Card(
                child: ListTile(
                  title: const Text('Expense Summary'),
                  subtitle: Text(state.expenseSummary.toString()),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.expenses.length,
              itemBuilder: (context, index) {
                final row = state.expenses[index];
                final id = row.id;
                final title = row.title.isNotEmpty ? row.title : row.category;
                final amount = row.amount.toString();
                final status = row.status.toLowerCase();
                return Card(
                  child: ListTile(
                    title: Text(title),
                    subtitle: Text('NGN $amount • ${status.toUpperCase()}'),
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        if (status == 'pending' && canReview)
                          TextButton(
                            onPressed: id.isEmpty
                                ? null
                                : () async => state.reviewExpense(
                                      id: id,
                                      decision: 'approve',
                                    ),
                            child: const Text('Approve'),
                          ),
                        if (status == 'pending' && canReview)
                          TextButton(
                            onPressed: id.isEmpty
                                ? null
                                : () async => state.reviewExpense(
                                      id: id,
                                      decision: 'reject',
                                    ),
                            child: const Text('Reject'),
                          ),
                        if (status == 'pending')
                          TextButton(
                            onPressed: id.isEmpty
                                ? null
                                : () async => state.cancelExpense(id),
                            child: const Text('Cancel'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _openSubmitDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final categoryController = TextEditingController();
    final descController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Submit Expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text.trim()) ?? 0;
                await context.read<AppStateController>().submitExpense(
                  title: titleController.text.trim(),
                  amount: amount,
                  category: categoryController.text.trim(),
                  description: descController.text.trim(),
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Expense submitted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}
