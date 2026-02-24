import 'package:flutter/material.dart';
import 'package:hervest_ai/features/rescue/models/rescue_models.dart';
import 'package:hervest_ai/provider/rescue_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum _PledgeFilter { all, pending, considered, completed }

class RescuePledgesHistoryPage extends StatefulWidget {
  const RescuePledgesHistoryPage({super.key});

  @override
  State<RescuePledgesHistoryPage> createState() =>
      _RescuePledgesHistoryPageState();
}

class _RescuePledgesHistoryPageState extends State<RescuePledgesHistoryPage> {
  _PledgeFilter _filter = _PledgeFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RescueProvider>().loadMarketplaceSurplus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rescue = context.watch<RescueProvider>();
    final actions = rescue.actions.where((action) {
      switch (_filter) {
        case _PledgeFilter.pending:
          return !action.isCompleted && !action.isDeferred;
        case _PledgeFilter.considered:
          return action.isDeferred;
        case _PledgeFilter.completed:
          return action.isCompleted;
        case _PledgeFilter.all:
          return true;
      }
    }).toList()..sort((a, b) => b.pledgedAt.compareTo(a.pledgedAt));

    return Scaffold(
      appBar: AppBar(title: const Text('Pledges History')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _filterChip('All', _PledgeFilter.all),
                _filterChip('Pending', _PledgeFilter.pending),
                _filterChip('Considered', _PledgeFilter.considered),
                _filterChip('Completed', _PledgeFilter.completed),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: actions.isEmpty
                ? const Center(child: Text('No pledge records yet.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: actions.length,
                    itemBuilder: (_, index) {
                      final action = actions[index];
                      final backend = _backendStatus(rescue, action);
                      return Card(
                        child: ListTile(
                          title: Text(action.itemName),
                          subtitle: Text(
                            '${action.itemCategory} • ${action.finalPath.name}\n'
                            '${DateFormat('yyyy-MM-dd HH:mm').format(action.pledgedAt.toLocal())}\n'
                            'Backend: ${backend.$1}${backend.$2.isEmpty ? '' : ' (${backend.$2})'}'
                            '${backend.$3.isEmpty ? '' : '\nSurplus ID: ${backend.$3}'}',
                          ),
                          isThreeLine: true,
                          trailing: _buildTrailing(rescue, action, backend),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, _PledgeFilter value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  Widget _statusChip(RescueAction action) {
    if (action.isCompleted) {
      return Chip(
        label: const Text('Completed'),
        backgroundColor: Colors.green.withValues(alpha: 0.12),
      );
    }
    if (action.isDeferred) {
      return Chip(
        label: const Text('Considered'),
        backgroundColor: Colors.orange.withValues(alpha: 0.12),
      );
    }
    return Chip(
      label: const Text('Pending'),
      backgroundColor: Colors.blue.withValues(alpha: 0.12),
    );
  }

  Widget _buildTrailing(
    RescueProvider rescue,
    RescueAction action,
    (String, String, String) backend,
  ) {
    final canClaim = _canMarkClaimed(action, backend);
    if (!canClaim) return _statusChip(action);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _statusChip(action),
        const SizedBox(height: 6),
        SizedBox(
          height: 28,
          child: OutlinedButton(
            onPressed: () async {
              final ok = await rescue.markActionSurplusClaimed(action);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Marked as claimed' : 'Failed to mark as claimed'),
                ),
              );
            },
            child: const Text('Mark Claimed'),
          ),
        ),
      ],
    );
  }

  bool _canMarkClaimed(RescueAction action, (String, String, String) backend) {
    if (action.finalPath != RescuePath.surplusSale) return false;
    if (action.isCompleted) return false;
    final status = backend.$2.toLowerCase().trim();
    if (status == 'claimed' || status == 'completed') return false;
    return true;
  }

  (String, String, String) _backendStatus(
    RescueProvider rescue,
    RescueAction action,
  ) {
    if (action.finalPath != RescuePath.surplusSale) {
      return ('Not required', '', '');
    }

    final id = (action.backendSurplusId ?? '').trim();
    if (id.isEmpty) {
      return ('Not synced', '', '');
    }

    for (final row in rescue.mySurplus) {
      final rowId = (row['id'] ?? '').toString();
      if (rowId == id) {
        final status = (row['status'] ?? 'unknown').toString();
        return ('Synced', status, id);
      }
    }

    if (action.isCompleted) {
      return ('Synced', 'completed', id);
    }
    return ('Synced', 'not-visible', id);
  }
}
