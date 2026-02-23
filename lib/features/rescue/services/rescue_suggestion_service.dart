import 'package:hervest_ai/features/rescue/models/rescue_models.dart';
import 'package:hervest_ai/models/inventory_model.dart';

class RescueSuggestionService {
  static const int nearExpiryMaxDays = 7;
  static const int nearExpiryMinDays = 3;
  static const int criticalMaxDays = 2;

  static final Map<String, double> _categoryCo2Factor = {
    'Dairy': 3.2,
    'Grains & Cereals': 1.2,
    'Fresh Produce': 0.8,
    'Proteins': 4.1,
    'Bakery': 1.6,
    'default': 1.5,
  };

  static final Map<String, int> _perishabilityScore = {
    'Dairy': 5,
    'Fresh Produce': 5,
    'Proteins': 5,
    'Bakery': 4,
    'Grains & Cereals': 2,
    'default': 3,
  };

  static final Map<RescueEntityCategory, Set<String>> _acceptedCategories = {
    RescueEntityCategory.school: {
      'Dairy',
      'Grains & Cereals',
      'Fresh Produce',
      'Bakery',
    },
    RescueEntityCategory.prison: {'Grains & Cereals', 'Proteins', 'Bakery'},
    RescueEntityCategory.foodKitchen: {
      'Fresh Produce',
      'Proteins',
      'Dairy',
      'Bakery',
    },
    RescueEntityCategory.orphanage: {
      'Dairy',
      'Fresh Produce',
      'Grains & Cereals',
    },
    RescueEntityCategory.church: {
      'Fresh Produce',
      'Bakery',
      'Grains & Cereals',
      'Dairy',
    },
  };

  static final Map<RescueEntityCategory, int> _urgencyCapacity = {
    RescueEntityCategory.school: 4,
    RescueEntityCategory.prison: 3,
    RescueEntityCategory.foodKitchen: 5,
    RescueEntityCategory.orphanage: 4,
    RescueEntityCategory.church: 3,
  };

  static int daysToExpiry(DateTime? expiryDate) {
    if (expiryDate == null) return 9999;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  static bool isRescueCandidate(InventoryItem item) {
    final daysLeft = daysToExpiry(item.expiryDate);
    return daysLeft >= 0 && daysLeft <= nearExpiryMaxDays;
  }

  static RescueSuggestion? buildSuggestion(InventoryItem item) {
    if (!isRescueCandidate(item)) return null;

    final daysLeft = daysToExpiry(item.expiryDate);
    final urgency = daysLeft <= criticalMaxDays
        ? RescueSuggestionUrgency.critical
        : RescueSuggestionUrgency.nearExpiry;

    final perishability = _scorePerishability(item.category);
    final bestEntity = _chooseBestEntity(
      category: item.category,
      perishability: perishability,
      daysLeft: daysLeft,
      quantity: item.quantity,
    );
    final path = _choosePath(
      daysLeft: daysLeft,
      perishability: perishability,
      estimatedValue: (item.purchasePrice ?? 0) * item.quantity,
    );
    final reason = _buildReason(
      itemName: item.name,
      itemCategory: item.category,
      entity: bestEntity,
      daysLeft: daysLeft,
    );
    final score = _calculateEntityScore(
      entity: bestEntity,
      category: item.category,
      perishability: perishability,
      daysLeft: daysLeft,
      quantity: item.quantity,
    );
    final co2 =
        _categoryCo2Factor[item.category] ?? _categoryCo2Factor['default']!;

    return RescueSuggestion(
      itemId: item.id,
      itemName: item.name,
      itemCategory: item.category,
      quantity: item.quantity,
      unit: item.unit,
      daysToExpiry: daysLeft,
      urgency: urgency,
      recommendedPath: path,
      bestEntityCategory: bestEntity,
      reason: reason,
      matchScore: score,
      estimatedValue: (item.purchasePrice ?? 0) * item.quantity,
      co2FactorPerUnit: co2,
    );
  }

  static List<RescueSuggestion> buildSuggestions(List<InventoryItem> items) {
    final suggestions = items
        .map(buildSuggestion)
        .whereType<RescueSuggestion>()
        .toList();
    suggestions.sort((a, b) {
      final daysCompare = a.daysToExpiry.compareTo(b.daysToExpiry);
      if (daysCompare != 0) return daysCompare;
      return b.matchScore.compareTo(a.matchScore);
    });
    return suggestions;
  }

  static String entityLabel(RescueEntityCategory entity) {
    switch (entity) {
      case RescueEntityCategory.school:
        return 'School';
      case RescueEntityCategory.prison:
        return 'Prison';
      case RescueEntityCategory.foodKitchen:
        return 'Food Kitchen';
      case RescueEntityCategory.orphanage:
        return 'Orphanage';
      case RescueEntityCategory.church:
        return 'Church';
    }
  }

  static String pathLabel(RescuePath path) {
    switch (path) {
      case RescuePath.donation:
        return 'Donation';
      case RescuePath.surplusSale:
        return 'Surplus Sale';
    }
  }

  static int _scorePerishability(String category) {
    return _perishabilityScore[category] ?? _perishabilityScore['default']!;
  }

  static RescuePath _choosePath({
    required int daysLeft,
    required int perishability,
    required double estimatedValue,
  }) {
    if (daysLeft <= criticalMaxDays || perishability >= 4) {
      return RescuePath.donation;
    }
    if (estimatedValue >= 10000 && daysLeft >= nearExpiryMinDays) {
      return RescuePath.surplusSale;
    }
    return RescuePath.donation;
  }

  static RescueEntityCategory _chooseBestEntity({
    required String category,
    required int perishability,
    required int daysLeft,
    required double quantity,
  }) {
    RescueEntityCategory best = RescueEntityCategory.foodKitchen;
    var bestScore = -1;
    for (final entity in RescueEntityCategory.values) {
      final score = _calculateEntityScore(
        entity: entity,
        category: category,
        perishability: perishability,
        daysLeft: daysLeft,
        quantity: quantity,
      );
      if (score > bestScore) {
        best = entity;
        bestScore = score;
      }
    }
    return best;
  }

  static int _calculateEntityScore({
    required RescueEntityCategory entity,
    required String category,
    required int perishability,
    required int daysLeft,
    required double quantity,
  }) {
    final acceptsCategory = _acceptedCategories[entity]!.contains(category);
    final categoryMatch = acceptsCategory ? 45 : 0;
    final urgencyNeed = daysLeft <= criticalMaxDays ? 5 : 3;
    final urgencyFit =
        (5 - (urgencyNeed - _urgencyCapacity[entity]!).abs()) * 5;
    final perishabilityFit =
        (5 - (perishability - _urgencyCapacity[entity]!).abs()) * 4;
    final quantityFit = quantity >= 20 ? 10 : 7;
    return categoryMatch + urgencyFit + perishabilityFit + quantityFit;
  }

  static String _buildReason({
    required String itemName,
    required String itemCategory,
    required RescueEntityCategory entity,
    required int daysLeft,
  }) {
    final entityName = entityLabel(entity);
    final urgencyPhrase = daysLeft <= criticalMaxDays
        ? 'This item is in the critical window'
        : 'This item is near expiry';

    if (itemCategory == 'Dairy') {
      return '$urgencyPhrase and $entityName can distribute dairy quickly to support calcium-rich meals.';
    }
    if (itemCategory == 'Grains & Cereals') {
      return '$urgencyPhrase and $entityName can use grains in predictable bulk feeding plans with minimal processing.';
    }
    if (itemCategory == 'Fresh Produce') {
      return '$urgencyPhrase and $entityName can turn produce into same-day meals, reducing spoilage risk.';
    }
    if (itemCategory == 'Proteins') {
      return '$urgencyPhrase and $entityName has high urgency capacity to handle perishable protein safely.';
    }
    return '$urgencyPhrase. $entityName is the best category fit for $itemName based on acceptance and urgency capacity.';
  }
}
