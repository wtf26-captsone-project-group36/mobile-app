import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';
import 'package:hervest_ai/provider/inventory_provider.dart';
import 'package:hervest_ai/models/inventory_model.dart';

class InventoryPageThree extends StatefulWidget {
  const InventoryPageThree({super.key});

  @override
  State<InventoryPageThree> createState() => _InventoryPageThreeState();
}

class _InventoryPageThreeState extends State<InventoryPageThree> {
  final Color creamBg = const Color(0xFFFDFBF7);
  final Color primaryGreen = const Color(0xFF006B4D);
  final Color errorRed = const Color(0xFFE57373);
  final Color validGreen = const Color(0xFF4CAF50);

  Future<void> _handleFinalSave() async {
    final router = GoRouter.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final isGuest = await AppSessionStore.instance.isGuest();
    if (isGuest) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text("Guest access: Sign up to save these items permanently."),
          action: SnackBarAction(label: 'Sign Up', onPressed: () => router.push('/signup')),
        ),
      );
      return;
    }
    
    // Logic: Navigate to Page 4 (Success)
    router.go('/inventory/success');
  }

  @override
  Widget build(BuildContext context) {
    // 1. Listen to the provider to get the real status of the 50+ items
    final provider = context.watch<InventoryProvider>();
    final List<InventoryItem> allItems = provider.items;
    final int errorCount = provider.errorCount;

    return Scaffold(
      backgroundColor: creamBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Review Upload", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("Check your inventory data before saving", style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 20),
                    
                    // 2. Dynamic Banner showing real error counts from JSON
                    _buildErrorBanner(errorCount, allItems.length),
                    
                    const SizedBox(height: 24),
                    _buildTableHead(),
                    Expanded(child: _buildReviewList(allItems)),
                    const SizedBox(height: 20),
                    _buildFooterButtons(errorCount),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(int errors, int total) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: errors > 0 ? errorRed.withValues(alpha: 0.1) : validGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            errors > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline, 
            color: errors > 0 ? Colors.red : primaryGreen
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errors > 0 ? "Some rows need attention" : "All items validated", 
                  style: const TextStyle(fontWeight: FontWeight.bold)
                ),
                Text(
                  "$errors of $total items have missing data. Fix them to enable AI suggestions.", 
                  style: const TextStyle(fontSize: 12, color: Colors.black54)
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildReviewList(List<InventoryItem> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isError = item.status == ItemStatus.error;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              Expanded(flex: 1, child: Text("${item.quantity}", style: const TextStyle(fontSize: 13))),
              Expanded(
                flex: 2,
                child: Text(
                  item.expiryDate == null ? "Missing Expiry" : DateFormat('dd/MM/yyyy').format(item.expiryDate!),
                  style: TextStyle(fontSize: 11, color: isError ? Colors.red : Colors.black87),
                ),
              ),
              Expanded(
                flex: 1,
                child: _buildStatusBadge(item.status),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(ItemStatus status) {
    final bool isError = status == ItemStatus.error;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isError ? Colors.white : validGreen,
        borderRadius: BorderRadius.circular(4),
        border: isError ? Border.all(color: errorRed) : null,
      ),
      child: Center(
        child: Text(
          isError ? "FIX" : "VALID",
          style: TextStyle(
            color: isError ? errorRed : Colors.white, 
            fontSize: 9, 
            fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }

  // UI Helpers (AppBar, TableHead, Footer) remain mostly similar but reference logic
  Widget _buildFooterButtons(int errorCount) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.pop(),
            child: const Text("Add More", style: TextStyle(color: Colors.black)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _handleFinalSave,
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
            child: Text(
              errorCount > 0 ? "Save Valid Items" : "Confirm All", 
              style: const TextStyle(color: Colors.white)
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
          IconButton(icon: const Icon(Icons.help_outline, color: Colors.grey), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildTableHead() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: Colors.grey.shade200,
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text("Item", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 1, child: Text("Qty", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 2, child: Text("Expiry", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 1, child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        ],
      ),
    );
  }
}







/*import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';

class InventoryPageThree extends StatefulWidget {
  const InventoryPageThree({super.key});

  @override
  State<InventoryPageThree> createState() => _InventoryPageThreeState();
}

class _InventoryPageThreeState extends State<InventoryPageThree> {
  // Theme Colors
  final Color creamBg = const Color(0xFFFDFBF7);
  final Color primaryGreen = const Color(0xFF006B4D);
  final Color errorRed = const Color(0xFFE57373);
  final Color validGreen = const Color(0xFF4CAF50);

  // Mock data representing the "Review Table" from your mockup
  final List<Map<String, dynamic>> reviewItems = [
    {"name": "Flour", "qty": "50 kg", "expiry": "10/03/2026", "status": "Valid"},
    {"name": "Milk", "qty": "20", "expiry": "Missing Expiry date", "status": "Error"},
    {"name": "Tomatoes", "qty": "5", "expiry": "10/03/2026", "status": "Error"},
    {"name": "Chiken", "qty": "15", "expiry": "Invalid date format", "status": "Error"},
    {"name": "Egg", "qty": "100", "expiry": "07/03/2026", "status": "Valid"},
  ];

  Future<void> _handleFinalSave() async {
    final isGuest = await AppSessionStore.instance.isGuest();
    if (isGuest) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Guest access: Sign up to save these items permanently."),
            action: SnackBarAction(label: 'Sign Up', onPressed: () => context.push('/signup')),
          ),
        );
      }
      return;
    }
    
    // Logic: Navigate back to the main inventory list (Page 1) after success
    context.go('/inventory'); 
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: creamBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Review Upload",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Check your inventory data before saving",
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    _buildErrorBanner(),
                    const SizedBox(height: 24),
                    _buildTableHead(),
                    Expanded(child: _buildReviewList()),
                    const SizedBox(height: 20),
                    _buildFooterButtons(width),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
          IconButton(icon: const Icon(Icons.help_outline, color: Colors.grey), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            color: Colors.grey.shade300,
            child: const Icon(Icons.warning_amber_rounded, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Some rows need your attention", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("4 of 20 rows have errors. Fix them or continue with valid items.", style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTableHead() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: Colors.grey.shade300,
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text("Item Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 1, child: Text("Quantity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 2, child: Text("Expiry Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 1, child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildReviewList() {
    return ListView.builder(
      itemCount: reviewItems.length,
      itemBuilder: (context, index) {
        final item = reviewItems[index];
        final bool isError = item['status'] == "Error";

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text(item['name'], style: const TextStyle(fontSize: 13))),
              Expanded(flex: 1, child: Text(item['qty'], style: const TextStyle(fontSize: 13))),
              Expanded(
                flex: 2,
                child: Text(
                  item['expiry'],
                  style: TextStyle(fontSize: 12, color: isError ? errorRed : Colors.black87),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isError ? Colors.white : validGreen,
                    borderRadius: BorderRadius.circular(4),
                    border: isError ? Border.all(color: Colors.grey.shade400) : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['status'],
                        style: TextStyle(color: isError ? Colors.black : Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const Icon(Icons.arrow_forward, size: 10, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooterButtons(double width) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Save valid items", style: TextStyle(color: Colors.black)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _handleFinalSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Save valid items", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
} */