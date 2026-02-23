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
                      return Card(
                        child: ListTile(
                          title: Text(action.itemName),
                          subtitle: Text(
                            '${action.itemCategory} • ${DateFormat('yyyy-MM-dd HH:mm').format(action.pledgedAt.toLocal())}',
                          ),
                          trailing: _statusChip(action),
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
}
