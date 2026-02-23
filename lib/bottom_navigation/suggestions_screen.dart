import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/features/rescue/models/rescue_models.dart';
import 'package:hervest_ai/features/rescue/services/rescue_suggestion_service.dart';
import 'package:hervest_ai/provider/rescue_provider.dart';
import 'package:hervest_ai/widgets/rescue_ai_assistant.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  static const Color _primaryGreen = Color(0xFF006B4D);
  static const Color _creamBg = Color(0xFFFDFBF7);
  late final ConfettiController _tileConfettiController;

  @override
  void initState() {
    super.initState();
    _tileConfettiController = ConfettiController(
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _tileConfettiController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final rescue = context.read<RescueProvider>();
    if (rescue.consumeAssistantOpenRequest()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        openRescueAssistantSheet(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rescue = context.watch<RescueProvider>();
    final suggestions = rescue.suggestions;
    final pendingBadge = rescue.latestBadgeAward;
    if (pendingBadge != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        rescue.clearLatestBadgeAward();
        _showBadgeDialog(pendingBadge);
      });
    }

    return Scaffold(
      backgroundColor: _creamBg,
      appBar: AppBar(
        title: const Text(
          'Rescue Suggestions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () => context.push('/suggestions/pledges'),
            icon: const Icon(Icons.history),
            tooltip: 'Pledges History',
          ),
        ],
      ),
      body: Stack(
        children: [
          !rescue.isReady
              ? const Center(child: CircularProgressIndicator())
              : suggestions.isEmpty
              ? _buildEmptyState()
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAIBanner(suggestions),
                      const SizedBox(height: 14),
                      const Text(
                        'Recommended Rescue Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: suggestions.length,
                          itemBuilder: (_, index) =>
                              _buildSuggestionCard(suggestions[index]),
                        ),
                      ),
                    ],
                  ),
                ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _tileConfettiController,
                blastDirection: pi / 2,
                emissionFrequency: 0.12,
                numberOfParticles: 18,
                maxBlastForce: 16,
                minBlastForce: 8,
                shouldLoop: false,
                gravity: 0.28,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: const RescueAIAssistantButton(),
    );
  }

  Widget _buildAIBanner(List<RescueSuggestion> suggestions) {
    final critical = suggestions
        .where((entry) => entry.daysToExpiry <= 2)
        .length;
    final nearExpiry = suggestions.length - critical;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _primaryGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'AI Rescue Engine found ${suggestions.length} candidates ($critical critical, $nearExpiry near-expiry).',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(RescueSuggestion suggestion) {
    final rescue = context.watch<RescueProvider>();
    final action = rescue.latestActionForItem(suggestion.itemId);
    final pending = action != null && !action.isCompleted && !action.isDeferred;
    final deferred = action?.isDeferred == true;
    final completed = action?.isCompleted == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    suggestion.itemName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _urgencyPill(suggestion),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${suggestion.quantity.toStringAsFixed(1)} ${suggestion.unit} • ${suggestion.itemCategory}',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 10),
            _infoRow(
              title: 'Best Match',
              value:
                  '${RescueSuggestionService.entityLabel(suggestion.bestEntityCategory)} (${RescueSuggestionService.pathLabel(suggestion.recommendedPath)})',
            ),
            _infoRow(title: 'Why', value: suggestion.reason),
            _infoRow(
              title: 'Match Score',
              value: '${suggestion.matchScore}/100',
            ),
            _infoRow(
              title: 'Est. Value',
              value:
                  'NGN ${NumberFormat('#,##0.00').format(suggestion.estimatedValue)}',
            ),
            if (action?.note != null && action!.note!.isNotEmpty)
              _infoRow(title: 'Note', value: action.note!),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: completed
                      ? null
                      : () => _openPledgeDialog(suggestion),
                  style: FilledButton.styleFrom(backgroundColor: _primaryGreen),
                  child: Text(
                    pending
                        ? 'Update Pledge'
                        : suggestion.recommendedPath == RescuePath.donation
                        ? 'Pledge to Donate'
                        : 'Pledge for Sale',
                  ),
                ),
                OutlinedButton(
                  onPressed: completed
                      ? null
                      : () =>
                            _openPledgeDialog(suggestion, forceOverride: true),
                  child: const Text('Override'),
                ),
                if (pending)
                  OutlinedButton.icon(
                    onPressed: () => _markCompleted(suggestion.itemId),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Mark Completed'),
                  ),
                if (pending)
                  OutlinedButton.icon(
                    onPressed: () => _markDeferred(suggestion.itemId),
                    icon: const Icon(Icons.schedule_outlined, size: 18),
                    label: const Text('Mark Considered'),
                  ),
                if (completed)
                  Chip(
                    avatar: const Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: Colors.green,
                    ),
                    label: const Text('Completed'),
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                  ),
                if (deferred)
                  Chip(
                    avatar: const Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.orange,
                    ),
                    label: const Text('Considered'),
                    backgroundColor: Colors.orange.withValues(alpha: 0.12),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _urgencyPill(RescueSuggestion suggestion) {
    final isCritical = suggestion.urgency == RescueSuggestionUrgency.critical;
    final color = isCritical ? Colors.red : Colors.orange;
    final label = isCritical
        ? 'Critical • ${suggestion.daysToExpiry}d left'
        : 'Near-Expiry • ${suggestion.daysToExpiry}d left';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _infoRow({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt_rounded, size: 62, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            'No rescue candidates right now',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Items are outside Near-Expiry/Critical windows.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Future<void> _openPledgeDialog(
    RescueSuggestion suggestion, {
    bool forceOverride = false,
  }) async {
    RescuePath selectedPath = suggestion.recommendedPath;
    RescueEntityCategory selectedEntity = suggestion.bestEntityCategory;
    final noteController = TextEditingController();
    final handoverController = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      forceOverride
                          ? 'Override Rescue Path'
                          : 'Confirm Rescue Pledge',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<RescuePath>(
                      initialValue: selectedPath,
                      decoration: const InputDecoration(
                        labelText: 'Rescue Path',
                      ),
                      items: RescuePath.values
                          .map(
                            (path) => DropdownMenuItem(
                              value: path,
                              child: Text(
                                RescueSuggestionService.pathLabel(path),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => selectedPath = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<RescueEntityCategory>(
                      initialValue: selectedEntity,
                      decoration: const InputDecoration(
                        labelText: 'Entity Category',
                      ),
                      items: RescueEntityCategory.values
                          .map(
                            (entity) => DropdownMenuItem(
                              value: entity,
                              child: Text(
                                RescueSuggestionService.entityLabel(entity),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => selectedEntity = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: handoverController,
                      decoration: const InputDecoration(
                        labelText: 'Handover Details (optional)',
                        hintText: 'Date/time, contact, location',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Note to self (optional)',
                        hintText: 'Reason for override or handover note',
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: _primaryGreen,
                        ),
                        child: const Text('Save Pledge'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      await context.read<RescueProvider>().pledge(
        suggestion: suggestion,
        overrideEntity: selectedEntity,
        overridePath: selectedPath,
        note: noteController.text,
        handoverDetails: handoverController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rescue pledge saved.')));
    }
    noteController.dispose();
    handoverController.dispose();
  }

  Future<void> _markCompleted(String itemId) async {
    final noteController = TextEditingController();
    final detailsController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Completion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tick this after donation/sale handover is complete.'),
              const SizedBox(height: 10),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(
                  labelText: 'Handover Details',
                  hintText: 'Date, location, receiver',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Completion Note',
                  hintText: 'Optional confirmation details',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: _primaryGreen),
              child: const Text('Mark Completed'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      await context.read<RescueProvider>().complete(
        itemId: itemId,
        completionNote: noteController.text,
        handoverDetails: detailsController.text,
      );
      if (!mounted) return;
      _tileConfettiController.play();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rescue marked as completed.')),
      );
    }
    noteController.dispose();
    detailsController.dispose();
  }

  Future<void> _markDeferred(String itemId) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mark as Considered'),
          content: TextField(
            controller: reasonController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              hintText: 'Partner unavailable, rescheduled, etc.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: _primaryGreen),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (confirm == true && mounted) {
      await context.read<RescueProvider>().defer(
        itemId: itemId,
        reason: reasonController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Marked as considered.')));
    }
    reasonController.dispose();
  }

  Future<void> _showBadgeDialog(RescueBadge badge) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return _BadgeCelebrationDialog(
          badge: badge,
          primaryGreen: _primaryGreen,
        );
      },
    );
  }
}

class _BadgeCelebrationDialog extends StatefulWidget {
  final RescueBadge badge;
  final Color primaryGreen;

  const _BadgeCelebrationDialog({
    required this.badge,
    required this.primaryGreen,
  });

  @override
  State<_BadgeCelebrationDialog> createState() =>
      _BadgeCelebrationDialogState();
}

class _BadgeCelebrationDialogState extends State<_BadgeCelebrationDialog> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 1800),
    )..play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCommitmentBadge =
        widget.badge.code == RescueProvider.commitmentBadge.code;
    final reason = isCommitmentBadge
        ? 'You reached ${widget.badge.threshold} pledges.'
        : 'You reached ${widget.badge.threshold} completed donations.';

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        AlertDialog(
          title: const Text('Badge Unlocked'),
          content: Text('You earned "${widget.badge.title}". $reason'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: widget.primaryGreen,
              ),
              child: const Text('Nice'),
            ),
          ],
        ),
        IgnorePointer(
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            emissionFrequency: 0.06,
            numberOfParticles: 28,
            maxBlastForce: 18,
            minBlastForce: 8,
            shouldLoop: false,
            gravity: 0.25,
          ),
        ),
      ],
    );
  }
}
