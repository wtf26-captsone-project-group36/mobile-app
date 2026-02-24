enum RescuePath { donation, surplusSale }

enum RescueEntityCategory { school, prison, foodKitchen, orphanage, church }

enum RescueSuggestionUrgency { nearExpiry, critical }

class RescueSuggestion {
  final String itemId;
  final String itemName;
  final String itemCategory;
  final double quantity;
  final String unit;
  final int daysToExpiry;
  final RescueSuggestionUrgency urgency;
  final RescuePath recommendedPath;
  final RescueEntityCategory bestEntityCategory;
  final String reason;
  final int matchScore;
  final double estimatedValue;
  final double co2FactorPerUnit;

  const RescueSuggestion({
    required this.itemId,
    required this.itemName,
    required this.itemCategory,
    required this.quantity,
    required this.unit,
    required this.daysToExpiry,
    required this.urgency,
    required this.recommendedPath,
    required this.bestEntityCategory,
    required this.reason,
    required this.matchScore,
    required this.estimatedValue,
    required this.co2FactorPerUnit,
  });
}

class RescueAction {
  final String id;
  final String itemId;
  final String itemName;
  final String itemCategory;
  final String unit;
  final RescuePath suggestedPath;
  final RescuePath finalPath;
  final RescueEntityCategory suggestedEntityCategory;
  final RescueEntityCategory finalEntityCategory;
  final String? backendSurplusId;
  final bool wasOverridden;
  final String? note;
  final String? handoverDetails;
  final DateTime pledgedAt;
  final DateTime? completedAt;
  final double quantity;
  final double estimatedValue;
  final double co2FactorPerUnit;
  final bool isCompleted;
  final bool isDeferred;

  const RescueAction({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.itemCategory,
    this.unit = 'units',
    required this.suggestedPath,
    required this.finalPath,
    required this.suggestedEntityCategory,
    required this.finalEntityCategory,
    this.backendSurplusId,
    required this.wasOverridden,
    required this.note,
    required this.handoverDetails,
    required this.pledgedAt,
    required this.completedAt,
    required this.quantity,
    required this.estimatedValue,
    required this.co2FactorPerUnit,
    required this.isCompleted,
    required this.isDeferred,
  });

  RescueAction copyWith({
    String? id,
    String? itemId,
    String? itemName,
    String? itemCategory,
    String? unit,
    RescuePath? suggestedPath,
    RescuePath? finalPath,
    RescueEntityCategory? suggestedEntityCategory,
    RescueEntityCategory? finalEntityCategory,
    String? backendSurplusId,
    bool? wasOverridden,
    String? note,
    String? handoverDetails,
    DateTime? pledgedAt,
    DateTime? completedAt,
    double? quantity,
    double? estimatedValue,
    double? co2FactorPerUnit,
    bool? isCompleted,
    bool? isDeferred,
  }) {
    return RescueAction(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      itemCategory: itemCategory ?? this.itemCategory,
      unit: unit ?? this.unit,
      suggestedPath: suggestedPath ?? this.suggestedPath,
      finalPath: finalPath ?? this.finalPath,
      suggestedEntityCategory:
          suggestedEntityCategory ?? this.suggestedEntityCategory,
      finalEntityCategory: finalEntityCategory ?? this.finalEntityCategory,
      backendSurplusId: backendSurplusId ?? this.backendSurplusId,
      wasOverridden: wasOverridden ?? this.wasOverridden,
      note: note ?? this.note,
      handoverDetails: handoverDetails ?? this.handoverDetails,
      pledgedAt: pledgedAt ?? this.pledgedAt,
      completedAt: completedAt ?? this.completedAt,
      quantity: quantity ?? this.quantity,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      co2FactorPerUnit: co2FactorPerUnit ?? this.co2FactorPerUnit,
      isCompleted: isCompleted ?? this.isCompleted,
      isDeferred: isDeferred ?? this.isDeferred,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'itemCategory': itemCategory,
      'unit': unit,
      'suggestedPath': suggestedPath.name,
      'finalPath': finalPath.name,
      'suggestedEntityCategory': suggestedEntityCategory.name,
      'finalEntityCategory': finalEntityCategory.name,
      'backendSurplusId': backendSurplusId,
      'wasOverridden': wasOverridden,
      'note': note,
      'handoverDetails': handoverDetails,
      'pledgedAt': pledgedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'quantity': quantity,
      'estimatedValue': estimatedValue,
      'co2FactorPerUnit': co2FactorPerUnit,
      'isCompleted': isCompleted,
      'isDeferred': isDeferred,
    };
  }

  static RescueAction fromJson(Map<String, dynamic> json) {
    return RescueAction(
      id: (json['id'] ?? '').toString(),
      itemId: (json['itemId'] ?? '').toString(),
      itemName: (json['itemName'] ?? '').toString(),
      itemCategory: (json['itemCategory'] ?? '').toString(),
      unit: (json['unit'] ?? 'units').toString(),
      suggestedPath: RescuePath.values.firstWhere(
        (value) => value.name == json['suggestedPath'],
        orElse: () => RescuePath.donation,
      ),
      finalPath: RescuePath.values.firstWhere(
        (value) => value.name == json['finalPath'],
        orElse: () => RescuePath.donation,
      ),
      suggestedEntityCategory: RescueEntityCategory.values.firstWhere(
        (value) => value.name == json['suggestedEntityCategory'],
        orElse: () => RescueEntityCategory.foodKitchen,
      ),
      finalEntityCategory: RescueEntityCategory.values.firstWhere(
        (value) => value.name == json['finalEntityCategory'],
        orElse: () => RescueEntityCategory.foodKitchen,
      ),
      backendSurplusId: json['backendSurplusId']?.toString(),
      wasOverridden: json['wasOverridden'] == true,
      note: json['note']?.toString(),
      handoverDetails: json['handoverDetails']?.toString(),
      pledgedAt:
          DateTime.tryParse((json['pledgedAt'] ?? '').toString()) ??
          DateTime.now(),
      completedAt: DateTime.tryParse((json['completedAt'] ?? '').toString()),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      estimatedValue: (json['estimatedValue'] as num?)?.toDouble() ?? 0,
      co2FactorPerUnit: (json['co2FactorPerUnit'] as num?)?.toDouble() ?? 0,
      isCompleted: json['isCompleted'] == true,
      isDeferred: json['isDeferred'] == true,
    );
  }
}

class RescueBadge {
  final String code;
  final String title;
  final int threshold;

  const RescueBadge({
    required this.code,
    required this.title,
    required this.threshold,
  });
}

class ImpactMetrics {
  final int totalCompletedRescues;
  final int totalDonations;
  final int totalSurplusSales;
  final double totalCo2AvoidedKg;
  final double totalValueRecovered;

  const ImpactMetrics({
    required this.totalCompletedRescues,
    required this.totalDonations,
    required this.totalSurplusSales,
    required this.totalCo2AvoidedKg,
    required this.totalValueRecovered,
  });

  static const ImpactMetrics empty = ImpactMetrics(
    totalCompletedRescues: 0,
    totalDonations: 0,
    totalSurplusSales: 0,
    totalCo2AvoidedKg: 0,
    totalValueRecovered: 0,
  );
}
