import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/widgets/app_input_styles.dart';

class AddIncomePage extends StatefulWidget {
  const AddIncomePage({super.key});

  @override
  State<AddIncomePage> createState() => _AddIncomePageState();
}

class _AddIncomePageState extends State<AddIncomePage> {
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
        title: const Text("Add Income", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Center(
                  child: Text("Record a new business income.", 
                    style: TextStyle(color: Colors.black54, fontSize: 14)),
                ),
                const SizedBox(height: 30),
                
                // Hero Amount View
                _buildHeroAmountInput(),
                
                const SizedBox(height: 32),
                
                _buildLabel("Date"),
                _buildTextField("Today, Feb 10", null, suffixIcon: Icons.calendar_today_outlined),
                
                const SizedBox(height: 20),
                _buildLabel("Source"),
                _buildTextField("What was this income from?", "e.g., Direct Sales, Refund, Grant"),
                
                const SizedBox(height: 20),
                _buildLabel("Description (Optional)"),
                _buildTextField("Add details about this income", null, maxLines: 3),
                
                const SizedBox(height: 40),
                
                // Save Button
                _buildSaveButton(),
                const SizedBox(height: 20),
              ],
            ),
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
        color: primaryGreen.withOpacity(0.1),
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
