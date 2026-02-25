import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';
import 'package:hervest_ai/provider/inventory_provider.dart';
import 'package:hervest_ai/models/inventory_model.dart';
import 'package:hervest_ai/widgets/app_input_styles.dart';

class InventoryPageTwo extends StatefulWidget {
  const InventoryPageTwo({super.key});

  @override
  State<InventoryPageTwo> createState() => _InventoryPageTwoState();
}

class _InventoryPageTwoState extends State<InventoryPageTwo> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _priceController = TextEditingController(); // NEW: For financial tracking
  
  String? _selectedCategory;
  DateTime? _selectedDate;
  DateTime? _expiryDate;

  final Color creamBg = const Color(0xFFFDFBF7);
  final Color primaryGreen = const Color(0xFF006B4D);

  // Updated categories to match your Data Scientist's JSON
  final List<String> _categories = [
    'Fresh Produce', 
    'Beverages', 
    'Grains & Cereals', 
    'Meat & Poultry', 
    'Dairy'
  ];

  Future<void> _pickDate(BuildContext context, bool isExpiry) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: today,
      // If picking expiry, disable past dates. If picking received date, allow past.
      firstDate: isExpiry ? today : DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: primaryGreen)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isExpiry) _expiryDate = picked;
        else _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation: Ensure expiry date is selected and valid
    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an expiry date.")),
      );
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_expiryDate!.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot add items that are already expired.")),
      );
      return;
    }

    // Capture context-dependent members before the async gap.
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = GoRouter.of(context);
    final provider = Provider.of<InventoryProvider>(context, listen: false);

    // Check Guest Status
    final isGuest = await AppSessionStore.instance.isGuest();
    if (isGuest) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text("Guest users cannot save items permanently."),
          action: SnackBarAction(label: 'Sign Up', onPressed: () => navigator.push('/signup')),
        ),
      );
      return;
    }

    // 1. Create the item using your new model structure
    final newItem = InventoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      category: _selectedCategory ?? 'General',
      quantity: double.tryParse(_qtyController.text) ?? 0.0,
      unit: _unitController.text.trim(),
      purchasePrice: double.tryParse(_priceController.text) ?? 0.0, // Financial data
      dateReceived: _selectedDate,
      expiryDate: _expiryDate,
    );

    // 2. Push to Provider

        /* await provider.addItemFromApi(newItem);

    // 3. Navigate to Success (Page 4) or Review (Page 3)
    navigator.push('/inventory/success'); */
    
    try {
      await provider.addItemFromApi(newItem);
      // 3. Navigate to Success (Page 4) only if API succeeds
      navigator.push('/inventory/success');
    } catch (e) {
      // Handle permission error (e.g. Staff trying to add item)
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Failed to save item: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Item Details", 
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF006B4D))),
                      const SizedBox(height: 24),

                      _buildLabel("Item Name *"),
                      _buildTextField(_nameController, "e.g. Golden Penny Beans", "Item name is required"),

                      _buildLabel("Category *"),
                      _buildDropdown(),

                      _buildLabel("Purchase Price (₦)"),
                      _buildTextField(_priceController, "e.g. 7000", "Required for financial ledger", isNumber: true),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("Quantity *"),
                                _buildTextField(_qtyController, "e.g. 10", "Required", isNumber: true),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("Unit *"),
                                _buildTextField(_unitController, "e.g. kg, bags", "Required"),
                              ],
                            ),
                          ),
                        ],
                      ),

                      _buildLabel("Expiry Date *"),
                      _buildDatePickerField(
                        _expiryDate == null ? "Select date" : DateFormat('dd/MM/yyyy').format(_expiryDate!),
                        () => _pickDate(context, true),
                      ),
                      
                      const SizedBox(height: 40),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI Helpers (Labels, TextFields, Dropdowns) remain functionally similar 
  // but ensure they use the class-level primaryGreen for consistent branding.
  
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
          const Text("Add New Item", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(width: 48), // Spacer to balance the back button
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(text, style: AppInputStyles.labelStyle),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, String error, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: AppInputStyles.decoration(hintText: hint),
      validator: (value) => value == null || value.isEmpty ? error : null,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: AppInputStyles.decoration(),
      hint: const Text("Select category"),
      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (val) => setState(() => _selectedCategory = val),
      validator: (val) => val == null ? "Please choose a category" : null,
    );
  }

  Widget _buildDatePickerField(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppInputStyles.inputFill,
          border: Border.all(color: AppInputStyles.inputBorder, width: 1.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text, style: TextStyle(color: text.contains("Select") ? Colors.grey : Colors.black)),
            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Cancel", style: TextStyle(color: Colors.black)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Save item", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
