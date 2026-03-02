import 'package:flutter/material.dart';
import 'package:hervest_ai/core/config/demo_flags.dart';
import 'package:hervest_ai/core/network/activity_api_service.dart';
import 'package:hervest_ai/core/network/alerts_api_service.dart';
import 'package:hervest_ai/core/network/audit_api_service.dart';
import 'package:hervest_ai/core/network/budget_api_service.dart';
import 'package:hervest_ai/core/storage/cashflow_fallback_store.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';
import 'package:hervest_ai/core/network/cashflow_api_service.dart';
import 'package:hervest_ai/core/network/expense_api_service.dart';
import 'package:hervest_ai/core/network/predictions_api_service.dart';
import 'package:hervest_ai/models/api_response_models.dart';

class AppStateController extends ChangeNotifier {
  String userName = 'John Doe';
  bool expiryAlertsEnabled = true;
  bool cashflowUpdatesEnabled = false;
  bool lowStockEnabled = true;
  final CashflowApiService _cashflowApi = const CashflowApiService();
  final AlertsApiService _alertsApi = const AlertsApiService();
  final PredictionsApiService _predictionsApi = const PredictionsApiService();
  final ActivityApiService _activityApi = const ActivityApiService();
  final BudgetApiService _budgetApi = const BudgetApiService();
  final ExpenseApiService _expenseApi = const ExpenseApiService();
  final AuditApiService _auditApi = const AuditApiService();
  final CashflowFallbackStore _fallbackStore = CashflowFallbackStore.instance;
  Map<String, dynamic> cashflowReport = {};
  CashflowReport? cashflowReportTyped;
  Map<String, dynamic> latestPredictions = {};
  CashflowPrediction? cashflowPrediction;
  InventoryPrediction? inventoryPrediction;
  Map<String, dynamic> expenseSummary = {};
  List<Anomaly> anomalies = [];
  List<Alert> alerts = [];
  List<Activity> activities = [];
  List<Budget> budgets = [];
  List<Expense> expenses = [];
  List<AuditLog> auditLogs = [];
  int unreadAlerts = 0;
  int criticalAlerts = 0;
  bool _isLoadingInsights = true;

  bool get isLoadingInsights => _isLoadingInsights;

  AppStateController() {
    _initializeUserName();
    loadTransactionsFromBackend();
    loadCashflowReport();
    loadInsightsFromBackend();
  }

  Future<void> _initializeUserName() async {
    final storedName = await AppSessionStore.instance.getUserName();
    if (storedName != null && storedName.isNotEmpty) {
      userName = storedName;
      notifyListeners();
    }
  }

  void setUserName(String name) {
    if (name.isNotEmpty) {
      userName = name;
      AppSessionStore.instance.setUserName(name);
      notifyListeners();
    }
  }

  // Mock Inventory Data (Page 1-4)
  List<Map<String, dynamic>> inventory = [
    {'id': '1', 'name': 'Golden Penny Beans', 'qty': '20 Units', 'expiry': 7},
    {'id': '2', 'name': 'Mama Gold Rice', 'qty': '15 Bags', 'expiry': 45},
    {'id': '3', 'name': 'Peak Milk', 'qty': '10 Cartons', 'expiry': 3},
  ];

  // Mock Transaction Data (Page 8-11)
  List<Map<String, dynamic>> transactions = [];

  Future<void> addTransaction({
    required String title,
    required String amount,
    required String type,
    required String date,
    String? note,
  }) async {
    final tx = {
      'title': title,
      'amount': amount,
      'type': type,
      'date': date,
    };
    transactions.insert(0, tx);
    notifyListeners();

    final token = await AppSessionStore.instance.getAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      final parsedAmount = _parseAmount(amount);
      final created = await _cashflowApi.createTransaction(
        accessToken: token,
        body: {
          'type': type.toLowerCase(),
          'amount': parsedAmount,
          'category': title,
          'description': note ?? '',
          'transaction_date': date,
        },
      );

      final mapped = _mapApiTransactionTyped(created);
      if (mapped.isNotEmpty) {
        transactions
          ..remove(tx)
          ..insert(0, mapped);
        notifyListeners();
      }
    } catch (_) {
      await _fallbackStore.addTransaction(
        type: type.toLowerCase(),
        amount: _parseAmount(amount),
        category: title,
        description: note,
        date: DateTime.tryParse(date),
      );
    }
  }

  Future<void> loadTransactionsFromBackend() async {
    final token = await AppSessionStore.instance.getAccessToken();
    final fallbackRows = await _fallbackStore.getTransactions();

    if (token == null || token.isEmpty) {
      transactions = fallbackRows.map(_mapLocalTransaction).toList();
      notifyListeners();
      return;
    }

    try {
      final rows = await _cashflowApi.getTransactions(accessToken: token);
      final backend = rows.map(_mapApiTransactionTyped).where((e) => e.isNotEmpty).toList();
      final local = fallbackRows.map(_mapLocalTransaction).toList();
      transactions = _mergeUiTransactions(backend, local);
      notifyListeners();
    } catch (_) {
      transactions = fallbackRows.map(_mapLocalTransaction).toList();
      notifyListeners();
    }
  }

  Future<void> loadCashflowReport() async {
    final token = await AppSessionStore.instance.getAccessToken();
    if (token == null || token.isEmpty) return;
    try {
      final report = await _cashflowApi.getCashflowReport(accessToken: token);
      cashflowReportTyped = report;
      // Keep legacy support
      cashflowReport = report.toJson();
      notifyListeners();
    } catch (_) {
      // Keep local fallback data.
    }
  }

  Future<void> loadInsightsFromBackend() async {
    final token = await AppSessionStore.instance.getAccessToken();
    if (token == null || token.isEmpty) {
      _isLoadingInsights = false;
      notifyListeners();
      return;
    }

    try {
      try {
        final alertsData = await _alertsApi.getAlerts(accessToken: token);
        if (alertsData.isNotEmpty) {
          alerts = alertsData;
          unreadAlerts = alerts.where((a) => a.isUnread).length;
          criticalAlerts = alerts
              .where((a) => a.severity == 'critical' || a.severity == 'high')
              .length;
        }
      } catch (_) {
        // Keep fallback counters.
      }

      try {
        final predictions = await _predictionsApi.getLatestPredictions(
          accessToken: token,
        );
        cashflowPrediction =
            predictions['cashflow_prediction'] as CashflowPrediction?;
        inventoryPrediction =
            predictions['inventory_prediction'] as InventoryPrediction?;
        latestPredictions = predictions; // Keep for any legacy consumers
      } catch (_) {
        // Keep fallback values.
      }

      try {
        anomalies = await _predictionsApi.getAnomalies(accessToken: token);
      } catch (_) {
        // Keep fallback values.
      }

      try {
        activities = await _activityApi.getActivities(accessToken: token);
      } catch (_) {
        // Keep fallback values.
      }
    } finally {
      _isLoadingInsights = false;
      notifyListeners();
    }
  }

  Future<void> markAlertRead(String alertId) async {
    final token = await AppSessionStore.instance.getAccessToken();
    if (token == null || token.isEmpty) return;
    try {
      await _alertsApi.markAlertRead(accessToken: token, alertId: alertId);
      await loadInsightsFromBackend();
    } catch (_) {
      // Ignore to avoid breaking UI flow.
    }
  }

  Future<void> resolveAlert(String alertId) async {
    final token = await AppSessionStore.instance.getAccessToken();
    if (token == null || token.isEmpty) return;
    try {
      await _alertsApi.resolveAlert(accessToken: token, alertId: alertId);
      await loadInsightsFromBackend();
    } catch (_) {
      // Ignore to avoid breaking UI flow.
    }
  }

  Future<void> loadBudgetsFromBackend() async {
    final token = await AppSessionStore.instance.getAccessToken();
    final fallbackRows = await _fallbackStore.getBudgets();
    final localBudgets = fallbackRows.map((e) => Budget.fromJson(e)).toList();
    if (token == null || token.isEmpty) {
      budgets = localBudgets;
      notifyListeners();
      return;
    }
    try {
      final backend = await _budgetApi.getBudgets(accessToken: token);
      budgets = [...backend, ...localBudgets.where((b) => !_containsBudget(backend, b.id))];
      notifyListeners();
    } catch (_) {
      budgets = localBudgets;
      notifyListeners();
    }
  }

  Future<void> createBudget({
    required String name,
    required double amount,
    String? category,
    String? startDate,
    String? endDate,
  }) async {
    final token = await AppSessionStore.instance.getAccessToken();
    if (token == null || token.isEmpty) return;
    try {
      await _budgetApi.createBudget(
        accessToken: token,
        body: {
          'name': name,
          'amount': amount,
          if (category != null && category.isNotEmpty) 'category': category,
          if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
          if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
        },
      );
      await loadBudgetsFromBackend();
    } catch (_) {
      if (DemoFlags.presentationMode) {
        await _fallbackStore.addBudget(
          category: category ?? name,
          allocatedAmount: amount,
        );
        await loadBudgetsFromBackend();
      }
    }
  }

  Future<void> updateBudget({
    required String id,
    String? name,
    double? amount,
    String? category,
  }) async {
    final token = await AppSessionStore.instance.getAccessToken();
    if (token == null || token.isEmpty) return;
    try {
      await _budgetApi.updateBudget(
        accessToken: token,
        id: id,
        body: {
          if (name != null && name.isNotEmpty) 'name': name,
          if (amount != null) 'amount': amount,
          if (category != null && category.isNotEmpty) 'category': category,
        },
      );
      await loadBudgetsFromBackend();
    } catch (_) {
      // Keep fallback values.
    }
  }

  Future<void> deleteBudget(String id) async {
    final token = await AppSessionStore.instance.getAccessToken();
    if (token == null || token.isEmpty) return;
    try {
      await _budgetApi.deleteBudget(accessToken: token, id: id);
      await loadBudgetsFromBackend();
    } catch (_) {
      if (DemoFlags.presentationMode) {
        await _fallbackStore.removeBudget(id);
        await loadBudgetsFromBackend();
      }
    }
  }

  Future<void> loadExpensesFromBackend() async {
    final token = await AppSessionStore.instance.getAccessToken();
    final fallbackRows = await _fallbackStore.getExpenses();
    final localExpenses = fallbackRows.map((e) => Expense.fromJson(e)).toList();
    if (token == null || token.isEmpty) {
      expenses = localExpenses;
      expenseSummary = _buildExpenseSummary(localExpenses);
      notifyListeners();
      return;
    }
    try {
      final backend = await _expenseApi.getExpenses(accessToken: token);
      expenses = [...backend, ...localExpenses.where((e) => !_containsExpense(backend, e.id))];
    } catch (_) {
      expenses = localExpenses;
    }
    try {
      expenseSummary = await _expenseApi.getExpenseSummary(accessToken: token);
    } catch (_) {
      expenseSummary = _buildExpenseSummary(expenses);
    }
    notifyListeners();
  }

  Future<void> submitExpense({
    required String title,
    required double amount,
    String? category,
    String? description,
  }) async {
    final token = await AppSessionStore.instance.getAccessToken();
    if (token == null || token.isEmpty) return;
    try {
      await _expenseApi.submitExpense(
        accessToken: token,
        body: {
          'title': title,
          'amount': amount,
          if (category != null && category.isNotEmpty) 'category': category,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );
      await loadExpensesFromBackend();
    } catch (_) {
      if (DemoFlags.presentationMode) {
        await _fallbackStore.addExpense(
          title: title,
          amount: amount,
          category: (category != null && category.isNotEmpty) ? category : 'General',
          description: description,
          status: 'pending',
        );
        await loadExpensesFromBackend();
      }
    }
  }

  Future<void> reviewExpense({
    required String id,
    required String decision,
    String? note,
  }) async {
    final token = await AppSessionStore.instance.getAccessToken();
    if (token == null || token.isEmpty) return;
    try {
      await _expenseApi.reviewExpense(
        accessToken: token,
        id: id,
        decision: decision,
        note: note,
      );
      await loadExpensesFromBackend();
    } catch (_) {
      // Keep fallback values.
    }
  }

  Future<void> cancelExpense(String id) async {
    final token = await AppSessionStore.instance.getAccessToken();
    if (token == null || token.isEmpty) return;
    try {
      await _expenseApi.cancelExpense(accessToken: token, id: id);
      await loadExpensesFromBackend();
    } catch (_) {
      // Keep fallback values.
    }
  }

  Future<void> loadAuditLogsFromBackend() async {
    final token = await AppSessionStore.instance.getAccessToken();
    if (token == null || token.isEmpty) return;
    try {
      auditLogs = await _auditApi.getAuditLogs(accessToken: token);
      notifyListeners();
    } catch (_) {
      // Keep fallback values.
    }
  }

  // --- Master Search Logic ---
  List<Map<String, dynamic>> searchResults = [];

  void performSearch(String query) {
    if (query.isEmpty) {
      searchResults = [];
    } else {
      final invResults = inventory
          .where((item) => item['name'].toLowerCase().contains(query.toLowerCase()))
          .map((item) => {...item, 'source': 'Inventory', 'icon': Icons.inventory_2})
          .toList();

      final transResults = transactions
          .where((t) => t['title'].toLowerCase().contains(query.toLowerCase()))
          .map((t) => {...t, 'source': 'Transaction', 'icon': Icons.receipt_long})
          .toList();

      searchResults = [...invResults, ...transResults];
    }
    notifyListeners();
  }

  void toggleExpiryAlerts(bool val) {
    expiryAlertsEnabled = val;
    notifyListeners();
  }

  void toggleCashflowUpdates(bool val) {
    cashflowUpdatesEnabled = val;
    notifyListeners();
  }

  void toggleLowStock(bool val) {
    lowStockEnabled = val;
    notifyListeners();
  }

  void updateUserName(String name) {
    userName = name;
    notifyListeners();
  }

  Map<String, dynamic> _mapApiTransactionTyped(Transaction tx) {
    return {
      'title': tx.category,
      'amount': 'NGN ${_formatAmount(tx.amount)}',
      'type': tx.type == 'income' ? 'Income' : 'Expense',
      'date': _formatDateForUi(tx.date.toIso8601String()),
    };
  }

  Map<String, dynamic> _mapLocalTransaction(Map<String, dynamic> row) {
    final amount = (row['amount'] as num?)?.toDouble() ?? 0;
    final type = (row['type'] ?? 'expense').toString().toLowerCase();
    final dateRaw = (row['date'] ?? '').toString();
    return {
      'title': (row['category'] ?? 'Other').toString(),
      'amount': 'NGN ${_formatAmount(amount)}',
      'type': type == 'income' ? 'Income' : 'Expense',
      'date': _formatDateForUi(dateRaw),
    };
  }

  List<Map<String, dynamic>> _mergeUiTransactions(
    List<Map<String, dynamic>> backend,
    List<Map<String, dynamic>> local,
  ) {
    final seen = <String>{};
    final merged = <Map<String, dynamic>>[];
    for (final row in [...backend, ...local]) {
      final key = '${row['title']}|${row['amount']}|${row['type']}|${row['date']}';
      if (seen.add(key)) merged.add(row);
    }
    return merged;
  }

  bool _containsBudget(List<Budget> list, String id) {
    return list.any((b) => b.id == id);
  }

  bool _containsExpense(List<Expense> list, String id) {
    return list.any((e) => e.id == id);
  }

  Map<String, dynamic> _buildExpenseSummary(List<Expense> rows) {
    double submitted = 0;
    double approved = 0;
    double pending = 0;
    double rejected = 0;
    double cancelled = 0;

    for (final e in rows) {
      submitted += e.amount;
      if (e.status == 'approved') approved += e.amount;
      if (e.status == 'pending') pending += e.amount;
      if (e.status == 'rejected') rejected += e.amount;
      if (e.status == 'cancelled') cancelled += e.amount;
    }

    return {
      'total_submitted': submitted,
      'total_approved': approved,
      'total_pending': pending,
      'total_rejected': rejected,
      'total_cancelled': cancelled,
      'count': rows.length,
    };
  }

  String _formatDateForUi(String raw) {
    if (raw.isEmpty) return 'Today';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final month = _monthName(parsed.month);
    return '$month ${parsed.day}';
  }

  String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (month < 1 || month > 12) return 'Unknown';
    return names[month - 1];
  }

  double _parseAmount(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  String _formatAmount(double value) {
    final intValue = value.round();
    final str = intValue.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final position = str.length - i;
      buffer.write(str[i]);
      if (position > 1 && position % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }
}
