import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';
import 'package:hervest_ai/provider/inventory_provider.dart';
import 'package:hervest_ai/models/inventory_model.dart';

class InventoryPageOne extends StatefulWidget {
  const InventoryPageOne({super.key});

  @override
  State<InventoryPageOne> createState() => _InventoryPageOneState();
}

class _InventoryPageOneState extends State<InventoryPageOne> {
  final Color creamBg = const Color(0xFFFDFBF7);
  final Color primaryGreen = const Color(0xFF006B4D);
  final Color errorRed = const Color(0xFFD32F2F);
  final Color warningOrange = Colors.orange.shade700;

  Future<void> _handleAddItemFlow(BuildContext context) async {
    final isGuest = await AppSessionStore.instance.isGuest();
    
    if (isGuest) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: primaryGreen,
            content: const Text("You're exploring as a guest — sign up to save."),
            action: SnackBarAction(
              label: 'Sign Up',
              textColor: Colors.white,
              onPressed: () => context.push('/signup'),
            ),
          ),
        );
      }
      return;
    }
    context.push('/inventory/add'); 
  }

  @override
  Widget build(BuildContext context) {
    // 1. Watch the provider for changes in the 50+ items list
    final inventoryProvider = context.watch<InventoryProvider>();
    final items = inventoryProvider.items;

    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: creamBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(context, items.length),
            Expanded(
              child: items.isEmpty 
                ? _buildEmptyState(context, width, height) 
                : _buildListView(items, inventoryProvider),
            ),
          ],
        ),
      ),
      floatingActionButton: items.isNotEmpty 
        ? FloatingActionButton(
            backgroundColor: primaryGreen,
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _handleAddItemFlow(context),
          )
        : null,
    );
  }

  Widget _buildCustomAppBar(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
          Text(
            "Inventory ($count)", // Dynamic count from Provider
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<InventoryItem> items, InventoryProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          SearchBar(
            hintText: "Search 50+ items...",
            elevation: WidgetStateProperty.all(0),
            backgroundColor: WidgetStateProperty.all(Colors.white),
            shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            leading: const Icon(Icons.search, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
              itemBuilder: (context, index) {
                final item = items[index];
                
                // Smart Logic: Determine trailing color and icon based on status
                Color statusColor = Colors.grey;
                IconData? statusIcon;

                if (item.status == ItemStatus.error) {
                  statusColor = errorRed;
                  statusIcon = Icons.warning_amber_rounded;
                } else if (item.status == ItemStatus.warning) {
                  statusColor = warningOrange;
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  title: Text(
                    item.name, 
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)
                  ),
                  subtitle: Text(
                    item.category, 
                    style: const TextStyle(fontSize: 12, color: Colors.black54)
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${item.quantity} ${item.unit}", 
                        style: TextStyle(
                          color: statusColor, 
                          fontWeight: FontWeight.bold,
                          fontSize: 14
                        )
                      ),
                      if (statusIcon != null)
                        Icon(statusIcon, size: 16, color: errorRed),
                    ],
                  ),
                  onTap: () {
                    // Navigate to Page 3 if item has errors
                    if (item.status == ItemStatus.error) {
                      context.push('/inventory/review');
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, double width, double height) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: width * 0.1),
        child: Column(
          children: [
            const Text(
              "You haven't added any inventory yet.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              "Start tracking your stock to avoid losses and expired items.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => _handleAddItemFlow(context),
                child: const Text(
                  "Add your first item",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}