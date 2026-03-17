import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/core/config/demo_flags.dart';
import 'package:hervest_ai/core/network/budget_api_service.dart';
import 'package:hervest_ai/core/network/predictions_api_service.dart';
import 'package:hervest_ai/core/storage/cashflow_fallback_store.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';
import 'package:hervest_ai/models/api_response_models.dart';
import 'package:intl/intl.dart';

/// Enhanced BudgetsPage with predictions, better UX, and proper theme
/// Theme: Cream background (0xFFFDFBF7) with Green accents (0xFF006B4D)
class BudgetsPageEnhanced extends StatefulWidget {
  const BudgetsPageEnhanced({super.key});

  @override
  State<BudgetsPageEnhanced> createState() => _BudgetsPageEnhancedState();
}

class _BudgetsPageEnhancedState extends State<BudgetsPageEnhanced> {
  final BudgetApiService _budgetService = BudgetApiService();
  final PredictionsApiService _predictionsService = PredictionsApiService();
  final CashflowFallbackStore _fallbackStore = CashflowFallbackStore.instance;

  // Theme Colors - App consistent
  static const Color _primaryGreen = Color(0xFF006B4D);
  static const Color _bgCream = Color(0xFFFDFBF7);
  static const Color _accentGreen = Color(0xFF2E7D32);
  static const Color _warningOrange = Color(0xFFFF9500);
  static const Color _criticalRed = Color(0xFFDC2626);
  static const Color _successGreen = Color(0xFF10B981);

  bool _isLoading = true;
  List<Budget> _budgets = [];
  Map<String, dynamic>? _predictions;
  double _totalAllocated = 0;
  double _totalSpent = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final token = await AppSessionStore.instance.getAccessToken();

      // Load budgets
      List<Budget> budgetData = [];
      final localBudgets = (await _fallbackStore.getBudgets())
          .map((e) => Budget.fromJson(e))
          .toList();

      if (token != null) {
        try {
          final remoteBudgets = await _budgetService.getBudgets(accessToken: token);
          budgetData = [
            ...remoteBudgets,
            ...localBudgets.where((b) => !remoteBudgets.any((r) => r.id == b.id))
          ];
        } catch (_) {
          budgetData = localBudgets;
        }
      } else {
        budgetData = localBudgets;
      }

      // Load predictions if available
      if (token != null) {
        try {
          _predictions = await _predictionsService.getLatestPredictions(
            accessToken: token,
          );
        } catch (_) {
          // Predictions not available
        }
      }

      // Calculate totals
      _totalAllocated = budgetData.fold(0, (sum, b) => sum + b.allocatedAmount);
      _totalSpent = budgetData.fold(0, (sum, b) => sum + b.spentAmount);

      if (mounted) {
        setState(() {
          _budgets = budgetData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final localBudgets = (await _fallbackStore.getBudgets())
            .map((e) => Budget.fromJson(e))
            .toList();
        _totalAllocated =
            localBudgets.fold(0, (sum, b) => sum + b.allocatedAmount);
        _totalSpent = localBudgets.fold(0, (sum, b) => sum + b.spentAmount);
        setState(() {
          _budgets = localBudgets;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCreateBudget(String category, double amount) async {
    try {
      final token = await AppSessionStore.instance.getAccessToken();
      if (token == null) {
        // Fall back to demo mode
        if (DemoFlags.presentationMode) {
          _createBudgetDemo(category, amount);
          return;
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')),
        );
        return;
      }

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
          const SnackBar(
            content: Text('✓ Budget set successfully'),
            backgroundColor: _successGreen,
          ),
        );
        Navigator.pop(context);
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        if (_isRoleDeniedError(e)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Role restriction: ${e.toString()}'),
              backgroundColor: _criticalRed,
            ),
          );
          return;
        }

        if (DemoFlags.presentationMode) {
          _createBudgetDemo(category, amount);
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: _criticalRed,
          ),
        );
      }
    }
  }

  void _createBudgetDemo(String category, double amount) {
    final now = DateTime.now();
    setState(() {
      _budgets.insert(
        0,
        Budget(
          id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
          category: category,
          allocatedAmount: amount,
          spentAmount: (amount * (0.3 + ((now.microsecond % 100) / 100))).ceil().toDouble(),
          remainingAmount: (amount * (0.3 + ((now.microsecond % 100) / 100))).ceil().toDouble(),
          period: 'monthly',
          month: now.month,
          year: now.year,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      );
    });
    _totalAllocated += amount;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Budget set (demo mode)'),
        backgroundColor: _successGreen,
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _deleteBudget(String id) async {
    try {
      final token = await AppSessionStore.instance.getAccessToken();
      if (token == null) {
        if (DemoFlags.presentationMode) {
          setState(() => _budgets.removeWhere((b) => b.id == id));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Budget removed')),
          );
          return;
        }
        return;
      }

      await _budgetService.deleteBudget(accessToken: token, id: id);
      if (mounted) {
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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

  Color _getProgressColor(double progress) {
    if (progress >= 0.9) return _criticalRed;
    if (progress >= 0.7) return _warningOrange;
    return _primaryGreen;
  }

  String _getRiskLevel(double progress) {
    if (progress >= 0.9) return "CRITICAL";
    if (progress >= 0.7) return "WARNING";
    return "HEALTHY";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Monthly Budgets",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadData,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child:
                    CircularProgressIndicator(color: _primaryGreen),
              )
            : RefreshIndicator(
                color: _primaryGreen,
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      if (_budgets.isNotEmpty) ...[
                        _buildSummaryCard(),
                        const SizedBox(height: 20),
                        if (_predictions != null)
                          _buildPredictionCard(),
                      ],
                      _budgets.isEmpty
                          ? _buildEmptyState()
                          : _buildBudgetsList(),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBudgetDialog(context),
        backgroundColor: _primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Set Budget",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final utilization = _totalAllocated > 0 ? (_totalSpent / _totalAllocated) : 0;
    final utilizationPercent = (utilization * 100).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryGreen, _accentGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primaryGreen.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Overall Budget Status",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "₦${NumberFormat('#,##0').format(_totalAllocated)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Total Allocated",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "$utilizationPercent%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Utilization",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (utilization.clamp(0, 1)).toDouble(),
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.3),
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Spent: ₦${NumberFormat('#,##0').format(_totalSpent)}",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard() {
    final cashflowPred = _predictions?['cashflow_prediction'];
    if (cashflowPred == null) return const SizedBox.shrink();

    final riskLevel = cashflowPred.riskLevel?.toUpperCase() ?? 'UNKNOWN';
    final daysUntilCrisis = cashflowPred.daysUntilBroke ?? 0;
    final confidence = ((cashflowPred.confidenceScore ?? 0) * 100).toInt();

    Color riskColor = _successGreen;
    if (riskLevel == 'HIGH') riskColor = _criticalRed;
    else if (riskLevel == 'MEDIUM') riskColor = _warningOrange;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: riskColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                riskLevel == 'HIGH'
                    ? Icons.warning_rounded
                    : riskLevel == 'MEDIUM'
                        ? Icons.info_rounded
                        : Icons.check_circle_rounded,
                color: riskColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "AI Prediction: $riskLevel Risk",
                    style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    daysUntilCrisis > 0
                        ? "Est. $daysUntilCrisis days until budget concerns ($confidence% confidence)"
                        : "Budget healthy (${confidence}% confidence)",
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.savings_outlined,
                size: 40,
                color: _primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "No Budgets Yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Set spending limits for different categories\nto track and manage finances effectively.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(
          _budgets.length,
          (index) {
            final budget = _budgets[index];
            final progress = (budget.allocatedAmount > 0
                ? budget.spentAmount / budget.allocatedAmount
                : 0).toDouble();
            final riskLevel = _getRiskLevel(progress);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Dismissible(
                key: Key(budget.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Delete Budget?"),
                      content: Text(
                          "This will remove the ${budget.category} budget limit."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                            foregroundColor: _criticalRed,
                          ),
                          child: const Text("Delete"),
                        ),
                      ],
                    ),
                  ) ??
                  false;
                },
                onDismissed: (_) => _deleteBudget(budget.id),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: _criticalRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: _buildBudgetCard(budget, progress, riskLevel),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBudgetCard(Budget budget, double progress, String riskLevel) {
    final progressColor = _getProgressColor(progress);
    final progressPercent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: progressColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category & Risk Level
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                budget.category,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  riskLevel,
                  style: TextStyle(
                    color: progressColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 8,
              backgroundColor: Colors.grey.shade100,
              color: progressColor,
            ),
          ),
          const SizedBox(height: 10),

          // Spent / Remaining
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "₦${NumberFormat('#,##0').format(budget.spentAmount)} spent",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    "of ₦${NumberFormat('#,##0').format(budget.allocatedAmount)}",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "$progressPercent%",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                  Text(
                    "₦${NumberFormat('#,##0').format(budget.remainingAmount)} left",
                    style: TextStyle(
                      fontSize: 11,
                      color: progressColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddBudgetDialog(BuildContext context) {
    final categoryController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _bgCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Set a New Budget",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Define spending limits for your categories",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),

                // Category
                const Text(
                  "Category",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: categoryController,
                  decoration: InputDecoration(
                    hintText: "e.g., Equipment, Operations, Marketing",
                    hintStyle: const TextStyle(color: Colors.black45),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: _primaryGreen, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Amount
                const Text(
                  "Monthly Limit (₦)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "100000",
                    hintStyle: const TextStyle(color: Colors.black45),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: _primaryGreen, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side:
                              const BorderSide(color: Colors.black12),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          final category = categoryController.text.trim();
                          final amount = double.tryParse(
                                  amountController.text.trim()) ??
                              0;

                          if (category.isEmpty || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Please enter category and amount'),
                                backgroundColor: _criticalRed,
                              ),
                            );
                            return;
                          }

                          _handleCreateBudget(category, amount);
                        },
                        child: const Text(
                          "Save Budget",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
