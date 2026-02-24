import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hervest_ai/provider/sales_provider.dart';

/// Reusable widget for displaying sales success/error feedback
class SaleFeedbackWidget extends StatefulWidget {
  const SaleFeedbackWidget({Key? key}) : super(key: key);

  @override
  State<SaleFeedbackWidget> createState() => _SaleFeedbackWidgetState();
}

class _SaleFeedbackWidgetState extends State<SaleFeedbackWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SalesProvider>(
      builder: (context, salesProvider, child) {
        // Show success message
        if (salesProvider.successMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showSuccessSnackBar(context, salesProvider.successMessage!);
            salesProvider.clearSuccess();
          });
        }

        // Show error message
        if (salesProvider.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showErrorDialog(context, salesProvider.errorMessage!);
          });
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sale Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SalesProvider>().clearError();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Dialog for selling inventory items
class SellInventoryDialog extends StatefulWidget {
  final String inventoryId;
  final String itemName;
  final double availableQuantity;
  final double? lastSellingPrice;

  const SellInventoryDialog({
    Key? key,
    required this.inventoryId,
    required this.itemName,
    required this.availableQuantity,
    this.lastSellingPrice,
  }) : super(key: key);

  @override
  State<SellInventoryDialog> createState() => _SellInventoryDialogState();
}

class _SellInventoryDialogState extends State<SellInventoryDialog> {
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _categoryController;
  
  String? _quantityError;
  String? _priceError;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
    _priceController = TextEditingController(
      text: widget.lastSellingPrice?.toString() ?? '',
    );
    _categoryController = TextEditingController(text: 'Sales');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _validateInputs() {
    _quantityError = null;
    _priceError = null;

    final qty = double.tryParse(_quantityController.text);
    if (qty == null || qty <= 0) {
      _quantityError = 'Enter a positive quantity';
    } else if (qty > widget.availableQuantity) {
      _quantityError = 'Cannot exceed available quantity (${widget.availableQuantity})';
    }

    final price = double.tryParse(_priceController.text);
    if (price == null || price < 0) {
      _priceError = 'Enter a valid price (≥ 0)';
    }
  }

  Future<void> _processSale(SalesProvider salesProvider) async {
    _validateInputs();
    setState(() {});

    if (_quantityError != null || _priceError != null) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final success = await salesProvider.sellItem(
        inventoryId: widget.inventoryId,
        quantitySold: double.parse(_quantityController.text),
        sellingPrice: double.parse(_priceController.text),
        transactionCategory: _categoryController.text,
        transactionDescription: 'Sale of ${widget.itemName}',
      );

      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sell ${widget.itemName}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Available Quantity Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  'Available: ${widget.availableQuantity} units',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Quantity Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quantity to Sell',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                    enabled: !_isProcessing,
                    decoration: InputDecoration(
                      hintText: 'Enter quantity',
                      errorText: _quantityError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Price Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selling Price (per unit)',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                    enabled: !_isProcessing,
                    decoration: InputDecoration(
                      hintText: 'Enter price',
                      errorText: _priceError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category (Optional)',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _categoryController,
                    enabled: !_isProcessing,
                    decoration: InputDecoration(
                      hintText: 'Sales, Direct Sales, etc.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Consumer<SalesProvider>(
                builder: (context, salesProvider, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isProcessing
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : () => _processSale(salesProvider),
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Complete Sale'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget for displaying transaction validation warnings
class TransactionWarningBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final bool isError;

  const TransactionWarningBanner({
    Key? key,
    required this.message,
    this.onDismiss,
    this.isError = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isError ? Colors.red.shade50 : Colors.orange.shade50,
        border: Border(
          left: BorderSide(
            color: isError ? Colors.red : Colors.orange,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.warning_amber,
            color: isError ? Colors.red : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? Colors.red.shade900 : Colors.orange.shade900,
                fontSize: 14,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
              iconSize: 16,
            ),
        ],
      ),
    );
  }
}

/// Loading overlay for processing transactions
class TransactionLoadingOverlay extends StatelessWidget {
  final bool isVisible;
  final String message;

  const TransactionLoadingOverlay({
    Key? key,
    required this.isVisible,
    this.message = 'Processing transaction...',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Material(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
