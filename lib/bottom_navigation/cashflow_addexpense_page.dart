import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/widgets/app_input_styles.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final Color primaryGreen = const Color(0xFF006B4D);
  final Color bgCream = const Color(0xFFFDFBF7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text("Add Expense", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 20),
            onPressed: () {}, // Optional: Next step
          ),
        ],
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

              // 1. Hero Amount Input
              _buildHeroAmountInput(),

              const SizedBox(height: 32),

              // 2. Form Fields
              _buildLabel("Amount"),
              _buildTextField("Enter amount", "Must be greater than 0."),

              const SizedBox(height: 20),
              _buildLabel("Category"),
              _buildDropdownField("Select a category", "Must be greater than 0."),

              const SizedBox(height: 20),
              _buildLabel("Date"),
              _buildTextField(
                "Today",
                "Select when this expense occurred.",
                suffixIcon: Icons.calendar_today_outlined,
              ),

              const SizedBox(height: 20),
              _buildLabel("Description"),
              _buildTextField("Add details about this expense", null, maxLines: 3),

              const SizedBox(height: 24),

              // 3. File Upload Button
              _buildUploadButton(),

              const SizedBox(height: 32),

              // 4. Save Button
              _buildSaveButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroAmountInput() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text("Amount", style: TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 4),
          Text("₦20,000", style: TextStyle(color: primaryGreen, fontSize: 32, fontWeight: FontWeight.bold)),
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

  Widget _buildTextField(String hint, String? helper, {IconData? suffixIcon, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          maxLines: maxLines,
          decoration: AppInputStyles.decoration(
            hintText: hint,
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, size: 18, color: AppInputStyles.textMuted)
                : null,
          ),
        ),
        if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(helper, style: const TextStyle(color: Colors.black45, fontSize: 11)),
          ),
      ],
    );
  }

  Widget _buildDropdownField(String hint, String helper) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          readOnly: true,
          decoration: AppInputStyles.decoration(
            hintText: hint,
            suffixIcon: const Icon(Icons.keyboard_arrow_down, color: AppInputStyles.textMuted),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(helper, style: const TextStyle(color: Colors.black45, fontSize: 11)),
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
        backgroundColor: const Color(0xFFE0F2F1).withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => context.pop(),
        child: const Text("Save valid items", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
