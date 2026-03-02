import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hervest_ai/provider/app_state_controller_mock.dart';

class CashflowScreen extends StatefulWidget {
  const CashflowScreen({super.key});

  @override
  State<CashflowScreen> createState() => _CashflowScreenState();
}

class _CashflowScreenState extends State<CashflowScreen> {
  final Color _bgCream = const Color(0xFFFDFBF7);
  final Color _primaryGreen = const Color(0xFF006B4D);
  final NumberFormat _currency = NumberFormat.currency(symbol: 'NGN ', decimalDigits: 0);

  DateTime _lastUpdated = DateTime.now();
  bool _isLoading = false;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
  }

  Future<void> _refreshData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final state = context.read<AppStateController>();
      await Future.wait([
        state.loadCashflowReport(),
        state.loadTransactionsFromBackend(),
        state.loadInsightsFromBackend(),
        state.loadExpensesFromBackend(),
        state.loadBudgetsFromBackend(),
      ]);
    } finally {
      if (mounted) {
        setState(() {
          _lastUpdated = DateTime.now();
          _isLoading = false;
          _isFirstLoad = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      body: SafeArea(
        child: _isFirstLoad
            ? Center(child: CircularProgressIndicator(color: _primaryGreen))
            : Consumer<AppStateController>(
                builder: (context, state, _) {
                  final totals = _totalsFromState(state);
                  final risk = _effectiveRisk(state, totals);
                  final runwayDays = state.cashflowPrediction?.daysUntilBroke ?? 0;
                  final expenseSummary = state.expenseSummary;
                  final pendingExpense = (expenseSummary['total_pending'] as num?)?.toDouble() ?? 0;
                  final approvedExpense = (expenseSummary['total_approved'] as num?)?.toDouble() ?? 0;
                  final fallbackSignal = _fallbackSignal(totals, pendingExpense);
                  final alertsCount = state.alerts.isNotEmpty
                      ? state.alerts.length
                      : (fallbackSignal.isEmpty ? 0 : 1);
                  final criticalAlerts = state.alerts.isNotEmpty
                      ? state.alerts.where((a) => a.severity == 'critical' || a.severity == 'high').length
                      : (fallbackSignal == 'critical' || fallbackSignal == 'high' ? 1 : 0);

                  return RefreshIndicator(
                    onRefresh: _refreshData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 14),
                          _buildBalanceHero(totals, risk, runwayDays),
                          const SizedBox(height: 12),
                          _buildMetricRow(totals),
                          const SizedBox(height: 14),
                          _buildQuickActions(),
                          const SizedBox(height: 12),
                          _buildFinanceTools(),
                          const SizedBox(height: 14),
                          _buildExpensePipeline(pendingExpense, approvedExpense),
                          const SizedBox(height: 12),
                          _buildSignalCard(
                            title: 'Risk Signals',
                            subtitle: '$alertsCount active alerts • $criticalAlerts high severity',
                            icon: Icons.warning_amber_rounded,
                            color: criticalAlerts > 0 ? Colors.red : Colors.orange,
                            onTap: () => context.push('/ai-insights'),
                          ),
                          if (state.anomalies.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _buildSignalCard(
                              title: 'Anomaly Watch',
                              subtitle: state.anomalies.first.message,
                              icon: Icons.insights_outlined,
                              color: Colors.deepOrange,
                              onTap: () => context.push('/ai-insights'),
                            ),
                          ] else if (fallbackSignal.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _buildSignalCard(
                              title: 'Local Risk Signal',
                              subtitle: _fallbackSignalMessage(fallbackSignal, totals, pendingExpense),
                              icon: Icons.assessment_outlined,
                              color: _riskColor(fallbackSignal),
                              onTap: () => context.push('/ai-insights'),
                            ),
                          ],
                          const SizedBox(height: 18),
                          _buildSectionHeader('Recent Transactions', 'View all', '/cashflow/transactions'),
                          _buildTransactionList(state.transactions),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Cashflow Command',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.2),
          ),
        ),
        IconButton(
          onPressed: _isLoading ? null : _refreshData,
          icon: Icon(_isLoading ? Icons.sync : Icons.refresh_rounded),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildBalanceHero(_CashflowTotals totals, String risk, int runwayDays) {
    final riskColor = _riskColor(risk);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push('/cashflow/transactions'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00543D), Color(0xFF007255)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Balance',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              _currency.format(totals.net),
              style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: riskColor.withValues(alpha: 0.8)),
                  ),
                  child: Text(
                    'Risk ${risk.toUpperCase()}',
                    style: TextStyle(color: riskColor, fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                if (runwayDays > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Text(
                      'Runway $runwayDays days',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Updated ${DateFormat('MMM d • h:mm a').format(_lastUpdated)}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(_CashflowTotals totals) {
    return Row(
      children: [
        Expanded(
          child: _metricCard(
            'Income',
            _currency.format(totals.income),
            Icons.north_east_rounded,
            const Color(0xFF1B9E5A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(
            'Expense',
            _currency.format(totals.expense),
            Icons.south_east_rounded,
            const Color(0xFFD94848),
          ),
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            label: 'Add Income',
            icon: Icons.add_circle_outline,
            color: const Color(0xFFE0F5EC),
            textColor: const Color(0xFF006B4D),
            onTap: () async {
              final result = await context.push<bool>('/cashflow/add-income');
              if (result == true && mounted) _refreshData();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            label: 'Add Expense',
            icon: Icons.remove_circle_outline,
            color: const Color(0xFFFDE9E9),
            textColor: const Color(0xFFD94848),
            onTap: () async {
              final result = await context.push<bool>('/cashflow/add-expense');
              if (result == true && mounted) _refreshData();
            },
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceTools() {
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
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/cashflow/expenses'),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Expenses'),
          ),
        ),
      ],
    );
  }

  Widget _buildExpensePipeline(double pending, double approved) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _pipelineTile('Pending Requests', _currency.format(pending), Colors.orange),
          ),
          Container(width: 1, height: 44, color: Colors.black12),
          Expanded(
            child: _pipelineTile('Approved', _currency.format(approved), Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _pipelineTile(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSignalCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String actionLabel, String path) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        TextButton(
          onPressed: () => context.push(path),
          child: Text(actionLabel),
        ),
      ],
    );
  }

  Widget _buildTransactionList(List<Map<String, dynamic>> transactions) {
    if (transactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: const Text('No transactions yet.', style: TextStyle(color: Colors.black54)),
      );
    }

    final recent = transactions.take(4).toList();
    return Column(
      children: recent.map((tx) {
        final isIncome = (tx['type'] as String).toLowerCase() == 'income';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isIncome ? const Color(0xFFE0F5EC) : const Color(0xFFFDE9E9),
                child: Icon(
                  isIncome ? Icons.north_east_rounded : Icons.south_east_rounded,
                  color: isIncome ? const Color(0xFF1B9E5A) : const Color(0xFFD94848),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx['date'] as String,
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                tx['amount'] as String,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  _CashflowTotals _totalsFromState(AppStateController state) {
    final typed = state.cashflowReportTyped;
    if (typed != null) {
      return _CashflowTotals(
        income: typed.totalIncome,
        expense: typed.totalExpense,
        net: typed.balance,
      );
    }

    final report = state.cashflowReport;
    if (report.isNotEmpty) {
      final income = (report['total_income'] as num?)?.toDouble() ?? 0;
      final expense =
          (report['total_expense'] as num?)?.toDouble() ??
          (report['total_expenses'] as num?)?.toDouble() ??
          0;
      final net =
          (report['balance'] as num?)?.toDouble() ??
          (report['net_balance'] as num?)?.toDouble() ??
          (income - expense);
      return _CashflowTotals(income: income, expense: expense, net: net);
    }

    return _totalsFromTransactions(state.transactions);
  }

  _CashflowTotals _totalsFromTransactions(List<Map<String, dynamic>> transactions) {
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

  double _parseAmount(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  Color _riskColor(String riskLevel) {
    final risk = riskLevel.toLowerCase();
    if (risk == 'critical' || risk == 'high') return Colors.redAccent;
    if (risk == 'medium') return Colors.orangeAccent;
    if (risk == 'low') return Colors.lightGreenAccent;
    return Colors.white70;
  }

  String _effectiveRisk(AppStateController state, _CashflowTotals totals) {
    final backendRisk = state.cashflowPrediction?.riskLevel;
    if (backendRisk != null && backendRisk.trim().isNotEmpty) return backendRisk;
    final pending = (state.expenseSummary['total_pending'] as num?)?.toDouble() ?? 0;
    return _fallbackSignal(totals, pending);
  }

  String _fallbackSignal(_CashflowTotals totals, double pendingExpense) {
    if (totals.net < 0 || totals.expense > (totals.income * 1.25)) return 'high';
    if (pendingExpense > 0 && pendingExpense > (totals.income * 0.4)) return 'medium';
    if (totals.income > 0 || totals.expense > 0) return 'low';
    return '';
  }

  String _fallbackSignalMessage(String level, _CashflowTotals totals, double pendingExpense) {
    if (level == 'high') {
      return 'Expenses are outpacing income. Keep close watch on outgoing cash.';
    }
    if (level == 'medium') {
      return 'Pending expenses are rising; approvals may pressure current cashflow.';
    }
    return 'Cashflow trend is stable from current local records.';
  }
}

class _CashflowTotals {
  const _CashflowTotals({
    required this.income,
    required this.expense,
    required this.net,
  });

  final double income;
  final double expense;
  final double net;
}
