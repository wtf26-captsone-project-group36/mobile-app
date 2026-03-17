/// Budget Integration Examples
/// File: lib/examples/budget_integration_examples.dart
/// Purpose: Copy-paste ready code snippets for common use cases

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/models/api_response_models.dart';
import 'package:hervest_ai/widgets/budget_widgets.dart';

// ============================================================================
// EXAMPLE 1: Add Budget Summary to Dashboard
// ============================================================================
/// Add this to your DashboardScreen/HomePage
class DashboardBudgetWidget extends StatelessWidget {
  final List<Budget> budgets;

  const DashboardBudgetWidget({super.key, required this.budgets});

  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) {
      return GestureDetector(
        onTap: () => context.push('/budgets'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF006B4D).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF006B4D).withOpacity(0.3),
            ),
          ),
          child: const Column(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: Color(0xFF006B4D)),
              SizedBox(height: 8),
              Text(
                "Set Budgets",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006B4D),
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Tap to set spending limits",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Budget Stats
        BudgetSummaryStats(budgets: budgets),

        const SizedBox(height: 12),

        // Budget Alerts
        ...budgets
            .where((b) =>
                (b.spentAmount / b.allocatedAmount) > 0.7)
            .map((budget) => BudgetAlertBanner(
              budget: budget,
              onViewDetails: () => context.push('/budgets'),
            )),

        const SizedBox(height: 12),

        // Quick View - Top 2 Budgets
        ...budgets.take(2).map((budget) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: HorizontalBudgetCard(
            budget: budget,
            onTap: () => context.push('/budgets'),
          ),
        )),

        // View All Button
        if (budgets.length > 2)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/budgets'),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text("View All Budgets"),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// EXAMPLE 2: Add Budget Check to Expense Entry Flow
// ============================================================================
/// Call this when user adds an expense to check budget impact
class BudgetCheckWarning extends StatelessWidget {
  final Budget budget;
  final double expenseAmount;
  final VoidCallback onProceed;
  final VoidCallback onCancel;

  const BudgetCheckWarning({
    super.key,
    required this.budget,
    required this.expenseAmount,
    required this.onProceed,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final newTotal = budget.spentAmount + expenseAmount;
    final newProgress = newTotal / budget.allocatedAmount;
    final wouldExceed = newTotal > budget.allocatedAmount;
    final willBeAtPercent = (newProgress * 100).toInt();

    if (!wouldExceed && newProgress < 0.9) {
      // No warning needed, auto-proceed
      onProceed();
      return const SizedBox.shrink();
    }

    return AlertDialog(
      title: Text(
        wouldExceed ? "⚠️ Budget Exceeded" : "⚠️ Warning",
        style: TextStyle(
          color: wouldExceed
              ? const Color(0xFFDC2626)
              : const Color(0xFFFF9500),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Adding ₦${expenseAmount.toInt()} to ${budget.category}",
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Budget Impact:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Current: ₦${budget.spentAmount.toInt()} / ₦${budget.allocatedAmount.toInt()}",
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  "After: ₦${newTotal.toInt()} / ₦${budget.allocatedAmount.toInt()} ($willBeAtPercent%)",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (wouldExceed)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                "🔴 This would exceed your ${budget.category} budget by ₦${(newTotal - budget.allocatedAmount).toInt()}",
                style: const TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 12,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                "🟠 You would be at $willBeAtPercent% of your budget",
                style: const TextStyle(
                  color: Color(0xFFFF9500),
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: wouldExceed
                ? const Color(0xFFDC2626)
                : const Color(0xFFFF9500),
          ),
          onPressed: onProceed,
          child: Text(
            wouldExceed ? "Proceed Anyway" : "Proceed",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// EXAMPLE 3: Monthly Budget Carousel for Dashboard
// ============================================================================
/// Show budgets in a horizontal scrollable view
class BudgetCarouselWidget extends StatelessWidget {
  final List<Budget> budgets;

  const BudgetCarouselWidget({super.key, required this.budgets});

  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Budget Status",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 160,
                  child: GestureDetector(
                    onTap: () => context.push('/budgets'),
                    child: CircularBudgetGauge(
                      budget: budgets[index],
                      size: 140,
                      showLabel: true,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// EXAMPLE 4: Budget Comparison View (Projected vs Actual)
// ============================================================================
/// Show how actual spending compares to AI predictions
class BudgetComparisonView extends StatelessWidget {
  final List<Budget> budgets;
  final Map<String, double> projectedAmounts;

  const BudgetComparisonView({
    super.key,
    required this.budgets,
    required this.projectedAmounts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: budgets.map((budget) {
        final projected = projectedAmounts[budget.id] ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BudgetComparisonCard(
            budget: budget,
            projectedSpend: projected,
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================================
// EXAMPLE 5: Inline Category Budget Check
// ============================================================================
/// Quick check for a specific category - use in transaction flows
class CategoryBudgetIndicator extends StatelessWidget {
  final String category;
  final double amount;
  final List<Budget> allBudgets;

  const CategoryBudgetIndicator({
    super.key,
    required this.category,
    required this.amount,
    required this.allBudgets,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final budget = allBudgets.firstWhere(
        (b) => b.category.toLowerCase() == category.toLowerCase(),
      );

      final newTotal = budget.spentAmount + amount;
      final progress = newTotal / budget.allocatedAmount;
      final wouldExceed = newTotal > budget.allocatedAmount;

      return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: wouldExceed
            ? const Color(0xFFDC2626).withOpacity(0.1)
            : const Color(0xFFFF9500).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: wouldExceed
              ? const Color(0xFFDC2626).withOpacity(0.3)
              : const Color(0xFFFF9500).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            wouldExceed ? Icons.error_rounded : Icons.warning_rounded,
            size: 16,
            color: wouldExceed
                ? const Color(0xFFDC2626)
                : const Color(0xFFFF9500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              wouldExceed
                  ? "Would exceed $category budget"
                  : "$category: ${(progress * 100).toInt()}% utilization",
              style: TextStyle(
                fontSize: 12,
                color: wouldExceed
                    ? const Color(0xFFDC2626)
                    : const Color(0xFFFF9500),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}

// ============================================================================
// EXAMPLE 6: Provider Integration (Recommended)
// ============================================================================
/// How to set up state management for budgets across the app

/*
import 'package:provider/provider.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetApiService _api = BudgetApiService();
  List<Budget> _budgets = [];
  bool _isLoading = false;

  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;

  Future<void> loadBudgets(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      _budgets = await _api.getBudgets(accessToken: token);
    } catch (e) {
      print('Error loading budgets: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createBudget(String token, String category, double amount) async {
    try {
      final newBudget = await _api.createBudget(
        accessToken: token,
        body: {'category': category, 'total_amount': amount, 'period': 'monthly'},
      );
      _budgets.add(newBudget);
      notifyListeners();
    } catch (e) {
      print('Error creating budget: $e');
      rethrow;
    }
  }

  Future<void> deleteBudget(String token, String id) async {
    try {
      await _api.deleteBudget(accessToken: token, id: id);
      _budgets.removeWhere((b) => b.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting budget: $e');
      rethrow;
    }
  }
}

// Usage in main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => BudgetProvider()),
    // ... other providers
  ],
  child: const MyApp(),
)

// Usage in widgets
Consumer<BudgetProvider>(
  builder: (context, budgetProvider, _) {
    return DashboardBudgetWidget(budgets: budgetProvider.budgets);
  },
)
*/

// ============================================================================
// EXAMPLE 7: Show Budget Warning in TextField
// ============================================================================
/// Add this to expense amount input widgets
class BudgetAwareAmountField extends StatefulWidget {
  final String? category;
  final List<Budget> budgets;
  final TextEditingController controller;

  const BudgetAwareAmountField({
    super.key,
    this.category,
    required this.budgets,
    required this.controller,
  });

  @override
  State<BudgetAwareAmountField> createState() =>
      _BudgetAwareAmountFieldState();
}

class _BudgetAwareAmountFieldState extends State<BudgetAwareAmountField> {
  double _warningThreshold = 0.8;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Amount (₦)",
            suffixText: _buildWarningText(),
            suffixStyle: _buildWarningStyle(),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  String _buildWarningText() {
    if (widget.category == null) return "";
    
    try {
      final budget = widget.budgets.firstWhere(
        (b) => b.category.toLowerCase() == widget.category!.toLowerCase(),
      );

      final amount = double.tryParse(widget.controller.text) ?? 0;
      final newTotal = budget.spentAmount + amount;
      final progress = newTotal / budget.allocatedAmount;

      if (progress > 1.0) {
        return " EXCEEDS";
      } else if (progress > _warningThreshold) {
        return " WARNING";
      }
      return "";
    } catch (_) {
      return "";
    }
  }

  TextStyle _buildWarningStyle() {
    final text = _buildWarningText();
    if (text.contains("EXCEEDS")) {
      return const TextStyle(color: Color(0xFFDC2626));
    } else if (text.contains("WARNING")) {
      return const TextStyle(color: Color(0xFFFF9500));
    }
    return const TextStyle();
  }
}

// ============================================================================
// USAGE SUMMARY
// ============================================================================
/*

1. ADD TO DASHBOARD:
   DashboardBudgetWidget(budgets: budgetsList)

2. PROTECT EXPENSE ENTRY:
   BudgetCheckWarning(...).show()

3. SHOW IN CAROUSEL:
   BudgetCarouselWidget(budgets: budgetsList)

4. COMPARE PROJECTIONS:
   BudgetComparisonView(budgets: list, projected: map)

5. QUICK INDICATOR:
   CategoryBudgetIndicator(category: cat, amount: amt, allBudgets: all)

6. FORM-AWARE INPUT:
   BudgetAwareAmountField(category: cat, budgets: all, controller: ctrl)

All examples use the theme colors and are fully functional out-of-the-box!
*/
