import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hervest_ai/features/rescue/data/rescue_local_db.dart';
import 'package:hervest_ai/features/rescue/models/rescue_models.dart';
import 'package:hervest_ai/features/rescue/services/rescue_suggestion_service.dart';
import 'package:hervest_ai/models/inventory_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RescueProvider extends ChangeNotifier {
  static const String _actionsKey = 'rescue_actions_v1';
  static const String _badgeKey = 'rescue_badges_v1';

  static const List<RescueBadge> availableBadges = [
    RescueBadge(code: 'rescue_starter', title: 'Rescue Starter', threshold: 5),
    RescueBadge(code: 'rescue_hero', title: 'Rescue Hero', threshold: 10),
    RescueBadge(
      code: 'community_champion',
      title: 'Community Champion',
      threshold: 20,
    ),
    RescueBadge(code: 'impact_leader', title: 'Impact Leader', threshold: 35),
    RescueBadge(code: 'waste_warrior', title: 'Waste Warrior', threshold: 50),
  ];

  List<RescueSuggestion> _suggestions = const [];
  List<RescueAction> _actions = const [];
  Set<String> _earnedBadgeCodes = <String>{};
  RescueBadge? _latestBadgeAward;
  bool _isReady = false;
  bool _usePrefsFallback = false;
  bool _assistantOpenRequested = false;

  List<RescueSuggestion> get suggestions => _suggestions;
  List<RescueAction> get actions => _actions;
  Set<String> get earnedBadgeCodes => _earnedBadgeCodes;
  RescueBadge? get latestBadgeAward => _latestBadgeAward;
  bool get isReady => _isReady;
  bool get assistantOpenRequested => _assistantOpenRequested;

  ImpactMetrics get impactMetrics {
    final completed = _actions.where((action) => action.isCompleted).toList();
    final donations = completed
        .where((action) => action.finalPath == RescuePath.donation)
        .toList();
    final surplusSales = completed
        .where((action) => action.finalPath == RescuePath.surplusSale)
        .toList();

    final co2 = completed.fold<double>(
      0,
      (sum, action) => sum + (action.quantity * action.co2FactorPerUnit),
    );
    final value = completed.fold<double>(
      0,
      (sum, action) => sum + action.estimatedValue,
    );

    return ImpactMetrics(
      totalCompletedRescues: completed.length,
      totalDonations: donations.length,
      totalSurplusSales: surplusSales.length,
      totalCo2AvoidedKg: co2,
      totalValueRecovered: value,
    );
  }

  int get nextBadgeThreshold {
    final donations = impactMetrics.totalDonations;
    for (final badge in availableBadges) {
      if (donations < badge.threshold) return badge.threshold;
    }
    return availableBadges.last.threshold;
  }

  Future<void> initialize() async {
    if (_isReady) return;
    if (kIsWeb) {
      _usePrefsFallback = true;
      await _loadFromPrefs();
    } else {
      try {
        final db = RescueLocalDb.instance;
        await db.database;
        _actions = await db.loadActions();
        _earnedBadgeCodes = await db.loadBadgeCodes();
        await _migrateLegacyPrefsIfNeeded();
      } catch (_) {
        _usePrefsFallback = true;
        await _loadFromPrefs();
      }
    }
    _isReady = true;
    notifyListeners();
  }

  void syncInventory(List<InventoryItem> items) {
    _suggestions = RescueSuggestionService.buildSuggestions(items);
    notifyListeners();
  }

  RescueAction? latestActionForItem(String itemId) {
    final matches = _actions
        .where((action) => action.itemId == itemId)
        .toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) => b.pledgedAt.compareTo(a.pledgedAt));
    return matches.first;
  }

  bool hasPendingCompletion(String itemId) {
    final action = latestActionForItem(itemId);
    return action != null && !action.isCompleted;
  }

  Future<void> pledge({
    required RescueSuggestion suggestion,
    RescuePath? overridePath,
    RescueEntityCategory? overrideEntity,
    String? note,
    String? handoverDetails,
  }) async {
    final now = DateTime.now();
    final latest = latestActionForItem(suggestion.itemId);
    final finalPath = overridePath ?? suggestion.recommendedPath;
    final finalEntity = overrideEntity ?? suggestion.bestEntityCategory;
    final overridden =
        finalPath != suggestion.recommendedPath ||
        finalEntity != suggestion.bestEntityCategory;

    final action = RescueAction(
      id: latest == null ? now.microsecondsSinceEpoch.toString() : latest.id,
      itemId: suggestion.itemId,
      itemName: suggestion.itemName,
      itemCategory: suggestion.itemCategory,
      suggestedPath: suggestion.recommendedPath,
      finalPath: finalPath,
      suggestedEntityCategory: suggestion.bestEntityCategory,
      finalEntityCategory: finalEntity,
      wasOverridden: overridden,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      handoverDetails: handoverDetails?.trim().isEmpty == true
          ? null
          : handoverDetails?.trim(),
      pledgedAt: latest == null ? now : latest.pledgedAt,
      completedAt: null,
      quantity: suggestion.quantity,
      estimatedValue: suggestion.estimatedValue,
      co2FactorPerUnit: suggestion.co2FactorPerUnit,
      isCompleted: false,
    );

    if (latest == null) {
      _actions = [..._actions, action];
    } else {
      _actions = _actions
          .map((entry) => entry.id == latest.id ? action : entry)
          .toList();
    }
    await _persist();
    notifyListeners();
  }

  Future<void> complete({
    required String itemId,
    String? completionNote,
    String? handoverDetails,
  }) async {
    final latest = latestActionForItem(itemId);
    if (latest == null || latest.isCompleted) return;
    final completed = latest.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
      note: completionNote?.trim().isNotEmpty == true
          ? completionNote!.trim()
          : latest.note,
      handoverDetails: handoverDetails?.trim().isNotEmpty == true
          ? handoverDetails!.trim()
          : latest.handoverDetails,
    );
    _actions = _actions
        .map((entry) => entry.id == latest.id ? completed : entry)
        .toList();
    _awardBadgesIfNeeded();
    await _persist();
    notifyListeners();
  }

  void clearLatestBadgeAward() {
    _latestBadgeAward = null;
    notifyListeners();
  }

  void requestAssistantOpen() {
    _assistantOpenRequested = true;
    notifyListeners();
  }

  bool consumeAssistantOpenRequest() {
    if (!_assistantOpenRequested) return false;
    _assistantOpenRequested = false;
    return true;
  }

  String answerAssistantQuery(String query, List<InventoryItem> items) {
    final q = query.toLowerCase().trim();
    final currentSuggestions = RescueSuggestionService.buildSuggestions(items);
    final critical = currentSuggestions
        .where((entry) => entry.daysToExpiry <= 2)
        .length;
    final metrics = impactMetrics;

    if (q.contains('what should i rescue today') ||
        q.contains('rescue today')) {
      if (currentSuggestions.isEmpty) {
        return 'No items are in Near-Expiry or Critical range today. Inventory looks stable.';
      }
      final top = currentSuggestions
          .take(3)
          .map((entry) {
            final path = RescueSuggestionService.pathLabel(
              entry.recommendedPath,
            );
            final entity = RescueSuggestionService.entityLabel(
              entry.bestEntityCategory,
            );
            return '${entry.itemName} (${entry.daysToExpiry}d): $path -> $entity';
          })
          .join(' | ');
      return 'Top rescue priorities: $top';
    }

    if (q.contains('critical') || q.contains('urgent')) {
      return 'You currently have $critical critical item(s) due in 0-2 days.';
    }

    if (q.contains('impact') || q.contains('co2')) {
      return 'Impact so far: ${metrics.totalCompletedRescues} completed rescues, ${metrics.totalDonations} donations, ${metrics.totalCo2AvoidedKg.toStringAsFixed(1)}kg CO2 avoided.';
    }

    if (q.contains('badge') || q.contains('milestone')) {
      final remaining = nextBadgeThreshold - metrics.totalDonations;
      return remaining <= 0
          ? 'You have reached the current top badge threshold.'
          : 'You are $remaining donation(s) away from your next badge at $nextBadgeThreshold donations.';
    }

    if (q.contains('sale') || q.contains('surplus')) {
      final sales = currentSuggestions
          .where((entry) => entry.recommendedPath == RescuePath.surplusSale)
          .length;
      return '$sales item(s) currently fit Surplus Sale based on value and time window.';
    }

    return 'Ask about: "What should I rescue today?", "Any critical items?", "Show my impact", or "How close am I to my next badge?"';
  }

  void _awardBadgesIfNeeded() {
    final donations = impactMetrics.totalDonations;
    for (final badge in availableBadges) {
      if (donations >= badge.threshold &&
          !_earnedBadgeCodes.contains(badge.code)) {
        _earnedBadgeCodes.add(badge.code);
        _latestBadgeAward = badge;
      }
    }
  }

  Future<void> _persist() async {
    if (_usePrefsFallback) {
      await _saveToPrefs();
      return;
    }
    try {
      final db = RescueLocalDb.instance;
      await db.replaceActions(_actions);
      await db.replaceBadgeCodes(_earnedBadgeCodes);
      await db.upsertImpactMetrics(impactMetrics);
    } catch (_) {
      _usePrefsFallback = true;
      await _saveToPrefs();
    }
  }

  Future<void> _migrateLegacyPrefsIfNeeded() async {
    if (_actions.isNotEmpty || _earnedBadgeCodes.isNotEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final rawActions = prefs.getString(_actionsKey);
    final badges = prefs.getStringList(_badgeKey) ?? const <String>[];
    if ((rawActions == null || rawActions.isEmpty) && badges.isEmpty) {
      return;
    }

    if (rawActions != null && rawActions.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawActions) as List<dynamic>;
        _actions = decoded
            .map(
              (entry) => RescueAction.fromJson(entry as Map<String, dynamic>),
            )
            .toList();
      } catch (_) {
        _actions = const [];
      }
    }
    _earnedBadgeCodes = badges.toSet();
    await _persist();
    await prefs.remove(_actionsKey);
    await prefs.remove(_badgeKey);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final rawActions = prefs.getString(_actionsKey);
    if (rawActions != null && rawActions.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawActions) as List<dynamic>;
        _actions = decoded
            .map(
              (entry) => RescueAction.fromJson(entry as Map<String, dynamic>),
            )
            .toList();
      } catch (_) {
        _actions = const [];
      }
    } else {
      _actions = const [];
    }
    final badges = prefs.getStringList(_badgeKey) ?? const <String>[];
    _earnedBadgeCodes = badges.toSet();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedActions = jsonEncode(
      _actions.map((entry) => entry.toJson()).toList(),
    );
    await prefs.setString(_actionsKey, encodedActions);
    await prefs.setStringList(_badgeKey, _earnedBadgeCodes.toList());
  }
}
