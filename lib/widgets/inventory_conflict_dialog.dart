import 'package:flutter/material.dart';
import 'package:hervest_ai/provider/inventory_provider.dart';
import 'package:provider/provider.dart';

/// Dialog to resolve inventory conflicts when the same item is edited on multiple devices
class InventoryConflictDialog extends StatelessWidget {
  final String itemId;
  final ConflictResolution conflict;

  const InventoryConflictDialog({
    super.key,
    required this.itemId,
    required this.conflict,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF006B4D);

    return AlertDialog(
      title: const Text(
        '⚠️ Conflict Detected',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 204, 85, 0),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item was edited on another device',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildConflictInfo(
              label: 'Item:',
              value: conflict.itemName,
            ),
            const SizedBox(height: 8),
            _buildConflictInfo(
              label: 'Your version:',
              value: 'v${conflict.localVersion}',
            ),
            const SizedBox(height: 8),
            _buildConflictInfo(
              label: 'Server version:',
              value: 'v${conflict.remoteVersion}',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Choose which version to keep. '
                'Using server version will discard your changes. '
                'Forcing local changes will overwrite the server version.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton.icon(
          onPressed: () {
            _resolveWithServer(context);
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.cloud_download_outlined),
          label: const Text('Use Server Version'),
        ),
        FilledButton.icon(
          onPressed: () {
            _resolveWithLocal(context);
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.check_circle_outlined),
          label: const Text('Keep My Changes'),
        ),
      ],
    );
  }

  Widget _buildConflictInfo({
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  void _resolveWithServer(BuildContext context) {
    final provider = context.read<InventoryProvider>();
    provider.resolveConflictWithServerVersion(itemId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Using server version. Your changes were discarded.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _resolveWithLocal(BuildContext context) {
    final provider = context.read<InventoryProvider>();
    provider.resolveConflictForceLocal(itemId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Keeping your changes. Server will be updated.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Helper to show conflict dialog if there is an active conflict
  static void showIfConflict(
    BuildContext context,
    InventoryProvider provider,
    String itemId,
  ) {
    final conflict = provider.getConflict(itemId);
    if (conflict != null) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => InventoryConflictDialog(
          itemId: itemId,
          conflict: conflict,
        ),
      );
    }
  }
}
