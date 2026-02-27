import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hervest_ai/core/network/budget_api_service.dart';
import 'package:hervest_ai/core/network/expense_api_service.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';
import 'package:hervest_ai/models/api_response_models.dart';
import 'package:hervest_ai/widgets/app_input_styles.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final Color primaryGreen = const Color(0xFF006B4D);
  final Color bgCream = const Color(0xFFFDFBF7);
  final Color expenseRed = Colors.red.shade700;

  // API Services
  final BudgetApiService _budgetService = BudgetApiService();
  final ExpenseApiService _expenseService = ExpenseApiService();
  final ImagePicker _imagePicker = ImagePicker();

  // State
  bool _isSubmitting = false;
  List<Budget> _budgets = [];
  Budget? _selectedCategoryBudget;
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _dateController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  XFile? _pickedFile;

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
              _budgets.isEmpty
                  ? _buildTextField(
                      controller: _categoryController,
                      hint: "Enter category (e.g., Food)",
                      helper: "No budgets found. You can still add an expense.",
                      onChanged: _onCategoryChanged,
                    )
                  : _buildCategoryDropdown(),
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

              _buildFileUploadSection(),

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
        color: Colors.red.shade50,
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
              color: expenseRed,
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

  Widget _buildFileUploadSection() {
    if (_pickedFile != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.attach_file, color: Colors.black54, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _pickedFile!.name,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _pickedFile = null),
            )
          ],
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: _pickFile,
      icon: Icon(Icons.cloud_upload_outlined, color: primaryGreen, size: 20),
      label: const Text("Upload receipt (optional)",
          style: TextStyle(color: Colors.black87)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(color: primaryGreen.withOpacity(0.2)),
        backgroundColor: primaryGreen.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<Budget>(
      value: _selectedCategoryBudget,
      hint: const Text("Select a category"),
      items: _budgets.map((budget) {
        return DropdownMenuItem<Budget>(value: budget, child: Text(budget.category));
      }).toList(),
      onChanged: (Budget? newValue) => _onCategoryChanged(newValue?.category ?? ''),
      decoration: AppInputStyles.decoration(hintText: "Select a category"),
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
        const SnackBar(content: Text("Please provide a category.")),
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
      // NOTE: File upload would be handled here, likely with a multipart request.
      // For this example, we are only saving the text data.
      await _expenseService.submitExpense(accessToken: token, body: body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Expense saved successfully!"), backgroundColor: Colors.green),
      );
      context.pop(true); // Return true to signal success to the previous screen
    } catch (e) {
      if (!mounted) return;
      String errorTitle = "Error";
      String errorMessage;

      if (e.toString().contains("Expense exceeds remaining budget") && _selectedCategoryBudget != null) {
        errorTitle = "Budget Exceeded";
        final remaining = _selectedCategoryBudget!.remainingAmount;
        errorMessage = "You only have ₦${_formatAmount(remaining)} left in your budget for this category.";
      } else {
        // Generic error for other cases. In a real app, you might log 'e' for debugging.
        errorMessage = "Could not save the expense. Please check your connection and try again.";
      }
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(title: Text(errorTitle), content: Text(errorMessage), actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
        ]),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildBudgetIndicator(Budget budget) {
    final total = budget.allocatedAmount;
    final remaining = budget.remainingAmount;
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

  Future<void> _pickFile() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;
      setState(() {
        _pickedFile = image;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick file: $e')),
      );
    }
  }
  void _onCategoryChanged(String categoryName) {
    final budget = _budgets.firstWhere(
      (b) => b.category.toLowerCase() == categoryName.trim().toLowerCase(),
      orElse: () => Budget(
        id: '',
        category: '',
        allocatedAmount: 0,
        spentAmount: 0,
        remainingAmount: 0,
        period: 'monthly',
        isActive: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    setState(() {
      _selectedCategoryBudget = budget.id.isNotEmpty ? budget : null;
      _categoryController.text = categoryName;
    });
  }
}
