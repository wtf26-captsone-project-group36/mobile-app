import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hervest_ai/provider/app_state_controller_mock.dart';
import 'package:hervest_ai/widgets/app_input_styles.dart';

class AddIncomePage extends StatefulWidget {
  const AddIncomePage({super.key});

  @override
  State<AddIncomePage> createState() => _AddIncomePageState();
}

class _AddIncomePageState extends State<AddIncomePage> {
  final Color primaryGreen = const Color(0xFF006B4D);
  final Color bgCream = const Color(0xFFFDFBF7);

  final _amountController = TextEditingController();
  final _sourceController = TextEditingController();
  final _dateController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dateController.text = _formatDisplayDate(_selectedDate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
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
          "Add Income",
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
                  "Record a new business income.",
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
              _buildLabel("Date"),
              _buildTextField(
                controller: _dateController,
                hint: "Select date",
                helper: null,
                suffixIcon: Icons.calendar_today_outlined,
                readOnly: true,
                onTap: _pickDate,
                onSuffixTap: _pickDate,
              ),

              const SizedBox(height: 20),
              _buildLabel("Source"),
              _buildTextField(
                controller: _sourceController,
                hint: "What was this income from?",
                helper: "e.g., Direct Sales, Refund, Grant",
              ),

              const SizedBox(height: 20),
              _buildLabel("Description (Optional)"),
              _buildTextField(
                controller: _descriptionController,
                hint: "Add details about this income",
                helper: null,
                maxLines: 3,
              ),

              const SizedBox(height: 40),

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
        color: primaryGreen.withValues(alpha: 0.1),
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
          onChanged: (_) => setState(() {}),
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
        onPressed: () {
          final amount = _parseAmount(_amountController.text);
          if (amount <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Enter a valid amount.")),
            );
            return;
          }
          final title = _sourceController.text.trim().isNotEmpty
              ? _sourceController.text.trim()
              : "Income";
          final date = _dateController.text.trim().isNotEmpty
              ? _dateController.text.trim()
              : "Today";
          context.read<AppStateController>().addTransaction(
            title: title,
            amount: "NGN ${_formatAmount(amount)}",
            type: "Income",
            date: date,
          );
          context.pop();
        },
        child: const Text(
          "Save income",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  double _parseAmount(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(cleaned) ?? 0;
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
