import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hervest_ai/core/network/budget_api_service.dart';
import 'package:hervest_ai/core/network/expense_api_service.dart';
import 'package:hervest_ai/widgets/app_input_styles.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final Color primaryGreen = const Color(0xFF006B4D);
  final Color bgCream = const Color(0xFFFDFBF7);

  // API Services
  final BudgetApiService _budgetService = BudgetApiService();
  final ExpenseApiService _expenseService = ExpenseApiService();

  // State
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _budgets = [];
  Map<String, dynamic>? _selectedCategoryBudget;
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _dateController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dateController.text = _formatDisplayDate(_selectedDate);
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    final token = await AppSessionStore.instance.getAccessToken();
    if (token == null || !mounted) return;
    try {
      final budgets = await _budgetService.getBudgets(accessToken: token);
      if (mounted) {
        setState(() {
          _budgets = budgets;
        });
      }
    } catch (e) {
      // Silently fail or show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not load budgets.")),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = _parseAmount(_amountController.text);
    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Add Expense",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  "Record a new business expense.",
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ),
              const SizedBox(height: 30),

              _buildHeroAmountInput(amount),

              const SizedBox(height: 32),

              _buildLabel("Amount"),
              _buildTextField(
                controller: _amountController,
                hint: "Enter amount",
                helper: "Must be greater than 0.",
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),

              const SizedBox(height: 20),
              _buildLabel("Category"),
              _buildTextField(
                controller: _categoryController,
                hint: "Select a category",
                helper: "Required",
                onChanged: _onCategoryChanged,
              ),
              if (_selectedCategoryBudget != null)
                _buildBudgetIndicator(_selectedCategoryBudget!),

              const SizedBox(height: 20),
              _buildLabel("Date"),
              _buildTextField(
                controller: _dateController,
                hint: "Select date",
                helper: "Select when this expense occurred.",
                suffixIcon: Icons.calendar_today_outlined,
                readOnly: true,
                onTap: _pickDate,
                onSuffixTap: _pickDate,
              ),

              const SizedBox(height: 20),
              _buildLabel("Description"),
              _buildTextField(
                controller: _descriptionController,
                hint: "Add details about this expense",
                helper: null,
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              _buildUploadButton(),

              const SizedBox(height: 32),

              _buildSaveButton(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroAmountInput(double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            "Amount",
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            "NGN ${_formatAmount(amount)}",
            style: TextStyle(
              color: primaryGreen,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: AppInputStyles.labelStyle),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String? helper,
    IconData? suffixIcon,
    void Function(String)? onChanged,
    VoidCallback? onTap,
    VoidCallback? onSuffixTap,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          onChanged: onChanged ?? (_) => setState(() {}),
          decoration: AppInputStyles.decoration(
            hintText: hint,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    onPressed: onSuffixTap ?? onTap,
                    icon: Icon(
                      suffixIcon,
                      size: 18,
                      color: AppInputStyles.textMuted,
                    ),
                  )
                : null,
          ),
        ),
        if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              helper,
              style: const TextStyle(color: Colors.black45, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _buildUploadButton() {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(Icons.cloud_upload_outlined, color: primaryGreen, size: 20),
      label: const Text("Upload file", style: TextStyle(color: Colors.black87)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: Color(0xFFE0F2F1)),
        backgroundColor: const Color(0xFFE0F2F1).withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isSubmitting ? null : _saveExpense,
        child: _isSubmitting
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : const Text(
                "Save expense",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _saveExpense() async {
          final amount = _parseAmount(_amountController.text);
          if (amount <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Enter a valid amount.")),
            );
            return;
          }
    if (_categoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a category.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final token = await AppSessionStore.instance.getAccessToken();
    if (token == null || !mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authentication error. Please log in again.")),
      );
      return;
    }

    final body = {
      'type': 'expense',
      'amount': amount,
      'category': _categoryController.text.trim(),
      'description': _descriptionController.text.trim(),
      'transaction_date': _formatDisplayDate(_selectedDate),
    };

    try {
      await _expenseService.submitExpense(accessToken: token, body: body);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      String errorMessage = "Failed to save expense. Please try again.";
      if (e.toString().contains("Expense exceeds remaining budget")) {
        final remaining = _selectedCategoryBudget?['remaining_amount'] as num? ?? 0;
        errorMessage = "You only have ₦${_formatAmount(remaining.toDouble())} left in your budget for this category.";
      }
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(e.toString().contains("exceeds") ? "Budget Exceeded" : "Error"),
          content: Text(errorMessage),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildBudgetIndicator(Map<String, dynamic> budget) {
    final total = (budget['total_amount'] as num?)?.toDouble() ?? 0.0;
    final remaining = (budget['remaining_amount'] as num?)?.toDouble() ?? 0.0;
    final percent = total > 0 ? remaining / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget: ₦${_formatAmount(remaining)} / ₦${_formatAmount(total)} remaining',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              percent < 0.2 ? Colors.red : (percent < 0.5 ? Colors.orange : primaryGreen),
            ),
          ),
        ],
      ),
    );
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = picked;
      _dateController.text = _formatDisplayDate(picked);
    });
  }

  String _formatDisplayDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  void _onCategoryChanged(String categoryName) {
    final budget = _budgets.firstWhere(
      (b) => (b['category'] as String).toLowerCase() == categoryName.trim().toLowerCase(),
      orElse: () => {},
    );
    setState(() {
      _selectedCategoryBudget = budget.isNotEmpty ? budget : null;
    });
  }
}
