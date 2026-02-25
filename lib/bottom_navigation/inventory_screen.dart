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
    final router = GoRouter.of(context);
    final isGuest = await AppSessionStore.instance.isGuest();
    if (!context.mounted) return;
    
    if (isGuest) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: primaryGreen,
            content: const Text("You're exploring as a guest — sign up to save."),
            action: SnackBarAction(
              label: 'Sign Up',
              textColor: Colors.white,
              onPressed: () => router.push('/signup'),
            ),
          ),
        );
      }
      return;
    }
    router.push('/inventory/add'); 
  }

  Future<void> _showEditDialog(
    BuildContext context,
    InventoryProvider provider,
    InventoryItem item,
  ) async {
    final nameController = TextEditingController(text: item.name);
    final qtyController = TextEditingController(text: item.quantity.toString());
    final unitController = TextEditingController(text: item.unit);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: qtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (saved != true || !context.mounted) return;

    final qty = double.tryParse(qtyController.text.trim()) ?? item.quantity;
    await provider.updateItemFromApi(
      itemId: item.id,
      name: nameController.text.trim().isEmpty ? item.name : nameController.text.trim(),
      quantity: qty,
      unit: unitController.text.trim().isEmpty ? item.unit : unitController.text.trim(),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    InventoryProvider provider,
    InventoryItem item,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: Text('Delete "${item.name}" from inventory?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: errorRed),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !context.mounted) return;
    await provider.deleteItemFromApi(item.id);
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
            hintText: "Search ${items.length} item(s)...",
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
                  trailing: SizedBox(
                    width: 140,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "${item.quantity} ${item.unit}",
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (statusIcon != null)
                                Icon(statusIcon, size: 16, color: errorRed),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              await _showEditDialog(context, provider, item);
                            } else if (value == 'delete') {
                              await _confirmDelete(context, provider, item);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ],
                    ),
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
