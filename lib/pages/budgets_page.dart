import 'package:flutter/material.dart';
import 'package:hervest_ai/provider/app_state_controller_mock.dart';
import 'package:provider/provider.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppStateController>().loadBudgetsFromBackend();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Budget'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: state.budgets.length,
        itemBuilder: (context, index) {
          final row = state.budgets[index];
          final id = (row['id'] ?? row['budget_id'] ?? '').toString();
          final name = (row['name'] ?? row['title'] ?? 'Budget').toString();
          final amount = (row['amount'] ?? row['limit'] ?? row['budget_amount'] ?? 0)
              .toString();
          final category = (row['category'] ?? 'General').toString();
          return Card(
            child: ListTile(
              title: Text(name),
              subtitle: Text('$category • NGN $amount'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (id.isEmpty) return;
                  if (value == 'delete') {
                    await state.deleteBudget(id);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openCreateDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final categoryController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text.trim()) ?? 0;
                await context.read<AppStateController>().createBudget(
                  name: nameController.text.trim(),
                  amount: amount,
                  category: categoryController.text.trim(),
                );
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
