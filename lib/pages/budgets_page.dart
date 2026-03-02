import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/core/config/demo_flags.dart';
import 'package:hervest_ai/core/network/budget_api_service.dart';
import 'package:hervest_ai/core/storage/cashflow_fallback_store.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';
import 'package:hervest_ai/models/api_response_models.dart';
import 'package:intl/intl.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  final BudgetApiService _budgetService = BudgetApiService();
  final CashflowFallbackStore _fallbackStore = CashflowFallbackStore.instance;
  final Color _primaryGreen = const Color(0xFF006B4D);
  final Color _bgCream = const Color(0xFFFDFBF7);

  bool _isLoading = true;
  List<Budget> _budgets = [];

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() => _isLoading = true);
    try {
      final token = await AppSessionStore.instance.getAccessToken();
      final local = (await _fallbackStore.getBudgets())
          .map((e) => Budget.fromJson(e))
          .toList();
      if (token != null) {
        final data = await _budgetService.getBudgets(accessToken: token);
        if (mounted) {
          setState(() {
            _budgets = [...data, ...local.where((b) => !data.any((r) => r.id == b.id))];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _budgets = local;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        final local = (await _fallbackStore.getBudgets())
            .map((row) => Budget.fromJson(row))
            .toList();
        setState(() {
          _budgets = local;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCreateBudget(String category, double amount) async {
    try {
      final token = await AppSessionStore.instance.getAccessToken();
      if (token == null) return;

      await _budgetService.createBudget(
        accessToken: token,
        body: {
          'category': category,
          'total_amount': amount,
          'period': 'monthly',
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget set successfully')),
        );
        Navigator.of(context).pop(); // Close dialog
        _loadBudgets(); // Refresh history
      }
    } catch (e) {
      if (mounted) {
        if (_isRoleDeniedError(e)) {
          final raw = e.toString().replaceFirst('Exception: ', '').trim();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                raw.isEmpty ? 'Your role cannot set budgets.' : raw,
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (DemoFlags.presentationMode) {
          final now = DateTime.now();
          final start = DateTime(now.year, now.month, 1);
          final end = DateTime(now.year, now.month + 1, 0);
          setState(() {
            _budgets.insert(
              0,
              Budget(
                id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
                category: category,
                allocatedAmount: amount,
                spentAmount: 0,
                remainingAmount: amount,
                period: 'monthly',
                isActive: true,
                createdAt: start,
                updatedAt: end,
              ),
            );
          });
          await _fallbackStore.addBudget(
            category: category,
            allocatedAmount: amount,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget set successfully')),
          );
          Navigator.of(context).pop();
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not set budget')),
        );
      }
    }
  }

  Future<void> _deleteBudget(String id) async {
    try {
      final token = await AppSessionStore.instance.getAccessToken();
      if (token == null) return;

      await _budgetService.deleteBudget(accessToken: token, id: id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget removed')),
        );
        _loadBudgets();
      }
    } catch (e) {
      if (mounted) {
        if (_isRoleDeniedError(e)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your role cannot delete budgets.'),
              backgroundColor: Colors.red,
            ),
          );
          _loadBudgets();
          return;
        }

        if (DemoFlags.presentationMode) {
          await _fallbackStore.removeBudget(id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget removed')),
          );
          _loadBudgets();
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete budget')),
        );
      }
    }
  }

  bool _isRoleDeniedError(Object e) {
    final raw = e.toString().toLowerCase();
    return raw.contains('access denied') ||
        raw.contains('required_roles') ||
        raw.contains('403');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Monthly Budgets",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryGreen))
          : _budgets.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _budgets.length,
                  itemBuilder: (context, index) => _buildBudgetCard(_budgets[index]),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBudgetDialog(context),
        backgroundColor: _primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Set Budget", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.savings_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "No budgets set yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          const Text(
            "Set limits for categories like 'Food' or 'Transport'",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(Budget budget) {
    final category = budget.category;
    final total = budget.allocatedAmount;
    final remaining = budget.remainingAmount;
    final spent = budget.spentAmount;
    final progress = total > 0 ? spent / total : 0.0;
    final isCritical = progress > 0.9;

    return Dismissible(
      key: Key(budget.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => await _confirmDelete(context),
      onDismissed: (_) => _deleteBudget(budget.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    "₦${NumberFormat('#,##0').format(remaining)} left",
                    style: TextStyle(
                      color: isCritical ? Colors.red : _primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade100,
                color: isCritical ? Colors.red : (progress > 0.7 ? Colors.orange : _primaryGreen),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text(
                "Spent ₦${NumberFormat('#,##0').format(spent)} of ₦${NumberFormat('#,##0').format(total)}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Budget?"),
        content: const Text("This will remove the spending limit for this category."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
        ],
      ),
    );
  }

  void _showAddBudgetDialog(BuildContext context) {
    final categoryController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("New Budget"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: "Category (e.g., Food)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: "Monthly Limit (₦)"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen),
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (categoryController.text.isNotEmpty && amount > 0) {
                _handleCreateBudget(categoryController.text.trim(), amount);
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
