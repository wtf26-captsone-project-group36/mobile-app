import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CashflowFallbackStore {
  CashflowFallbackStore._();

  static final CashflowFallbackStore instance = CashflowFallbackStore._();

  static const String _transactionsKey = 'fallback_cashflow_transactions';
  static const String _expensesKey = 'fallback_cashflow_expenses';
  static const String _budgetsKey = 'fallback_cashflow_budgets';

  Future<void> addTransaction({
    required String type,
    required double amount,
    required String category,
    String? description,
    DateTime? date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rows = await _readList(prefs, _transactionsKey);
    rows.insert(0, {
      'transaction_id': 'local-tx-${DateTime.now().microsecondsSinceEpoch}',
      'type': type,
      'amount': amount,
      'category': category,
      'description': description ?? '',
      'date': (date ?? DateTime.now()).toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'is_local_fallback': true,
    });
    await _writeList(prefs, _transactionsKey, rows);
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    return _readList(prefs, _transactionsKey);
  }

  Future<void> addExpense({
    required String title,
    required double amount,
    required String category,
    String? description,
    String status = 'pending',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rows = await _readList(prefs, _expensesKey);
    rows.insert(0, {
      'expense_id': 'local-exp-${DateTime.now().microsecondsSinceEpoch}',
      'title': title,
      'amount': amount,
      'category': category,
      'description': description ?? '',
      'status': status,
      'submitted_at': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'submitted_by': 'local-user',
      'is_local_fallback': true,
    });
    await _writeList(prefs, _expensesKey, rows);
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    return _readList(prefs, _expensesKey);
  }

  Future<void> addBudget({
    required String category,
    required double allocatedAmount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rows = await _readList(prefs, _budgetsKey);
    final now = DateTime.now();
    rows.insert(0, {
      'budget_id': 'local-budget-${DateTime.now().microsecondsSinceEpoch}',
      'category': category,
      'allocated_amount': allocatedAmount,
      'spent_amount': 0,
      'remaining_amount': allocatedAmount,
      'period': 'monthly',
      'is_active': true,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'is_local_fallback': true,
    });
    await _writeList(prefs, _budgetsKey, rows);
  }

  Future<void> removeBudget(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final rows = await _readList(prefs, _budgetsKey);
    rows.removeWhere((row) => (row['budget_id'] ?? '').toString() == id);
    await _writeList(prefs, _budgetsKey, rows);
  }

  Future<List<Map<String, dynamic>>> getBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    return _readList(prefs, _budgetsKey);
  }

  Future<List<Map<String, dynamic>>> _readList(
    SharedPreferences prefs,
    String key,
  ) async {
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
    } catch (_) {
      return [];
    }
    return [];
  }

  Future<void> _writeList(
    SharedPreferences prefs,
    String key,
    List<Map<String, dynamic>> rows,
  ) async {
    await prefs.setString(key, jsonEncode(rows));
  }
}
