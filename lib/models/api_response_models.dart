// ============================================================================
// API Response Models - HerVest AI
// Location: lib/models/api_response_models.dart
// Purpose: Strongly-typed Dart models for all API endpoints
// Generated: February 2026
// ============================================================================

// ============================================================================
// EXPENSE MODEL
// ============================================================================
class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String? description;
  final String status; // pending, approved, rejected
  final DateTime submittedAt;
  final DateTime createdAt;
  final String? receiptUrl;
  final String submittedBy;
  final String? reviewedBy;
  final String? reviewNote;
  final DateTime? reviewedAt;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    this.description,
    required this.status,
    required this.submittedAt,
    required this.createdAt,
    this.receiptUrl,
    required this.submittedBy,
    this.reviewedBy,
    this.reviewNote,
    this.reviewedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: (json['expense_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      category: (json['category'] ?? '').toString(),
      description: json['description']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'].toString())
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      receiptUrl: json['receipt_url']?.toString(),
      submittedBy: (json['submitted_by'] ?? '').toString(),
      reviewedBy: json['reviewed_by']?.toString(),
      reviewNote: json['review_note']?.toString(),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'expense_id': id,
    'title': title,
    'amount': amount,
    'category': category,
    'description': description,
    'status': status,
    'submitted_at': submittedAt.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'receipt_url': receiptUrl,
    'submitted_by': submittedBy,
    'reviewed_by': reviewedBy,
    'review_note': reviewNote,
    'reviewed_at': reviewedAt?.toIso8601String(),
  };

  String get statusEmoji => {
    'pending': '⏳',
    'approved': '✅',
    'rejected': '❌'
  }[status] ?? '❓';

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}

// ============================================================================
// BUDGET MODEL
// ============================================================================
class Budget {
  final String id;
  final String category;
  final double allocatedAmount;
  final double spentAmount;
  final double remainingAmount;
  final String period; // monthly, quarterly, annual
  final int? month;
  final int? year;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget({
    required this.id,
    required this.category,
    required this.allocatedAmount,
    required this.spentAmount,
    required this.remainingAmount,
    required this.period,
    this.month,
    this.year,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: (json['budget_id'] ?? json['id'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      allocatedAmount: (json['allocated_amount'] as num?)?.toDouble() ?? 0,
      spentAmount: (json['spent_amount'] as num?)?.toDouble() ?? 0,
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0,
      period: (json['period'] ?? 'monthly').toString(),
      month: json['month'] as int?,
      year: json['year'] as int?,
      isActive: json['is_active'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'budget_id': id,
    'category': category,
    'allocated_amount': allocatedAmount,
    'spent_amount': spentAmount,
    'remaining_amount': remainingAmount,
    'period': period,
    'month': month,
    'year': year,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  double get percentageUsed =>
      allocatedAmount > 0 ? (spentAmount / allocatedAmount) * 100 : 0;

  bool get isOverBudget => spentAmount > allocatedAmount;

  String get statusEmoji => isOverBudget ? '⚠️' : '✅';
}

// ============================================================================
// SURPLUS OWNER & SURPLUS MODEL
// ============================================================================
class SurplusOwner {
  final String fullName;
  final String businessName;
  final String businessType;

  SurplusOwner({
    required this.fullName,
    required this.businessName,
    required this.businessType,
  });

  factory SurplusOwner.fromJson(Map<String, dynamic> json) {
    return SurplusOwner(
      fullName: (json['full_name'] ?? '').toString(),
      businessName: (json['business_name'] ?? '').toString(),
      businessType: (json['business_type'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'business_name': businessName,
    'business_type': businessType,
  };
}

class Surplus {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final String? category;
  final String? description;
  final bool isFree;
  final double price;
  final DateTime? expiryDate;
  final String location;
  final String status; // available, claimed, expired
  final SurplusOwner owner;
  final String? claimedBy;
  final DateTime? claimedAt;
  final String? inventoryId;
  final DateTime createdAt;

  Surplus({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.category,
    this.description,
    required this.isFree,
    required this.price,
    this.expiryDate,
    required this.location,
    required this.status,
    required this.owner,
    this.claimedBy,
    this.claimedAt,
    this.inventoryId,
    required this.createdAt,
  });

  factory Surplus.fromJson(Map<String, dynamic> json) {
    return Surplus(
      id: (json['surplus_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unit: (json['unit'] ?? 'units').toString(),
      category: json['category']?.toString(),
      description: json['description']?.toString(),
      isFree: json['is_free'] == true,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'].toString())
          : null,
      location: (json['location'] ?? '').toString(),
      status: (json['status'] ?? 'available').toString(),
      owner: SurplusOwner.fromJson(json['owner'] ?? {}),
      claimedBy: json['claimed_by']?.toString(),
      claimedAt: json['claimed_at'] != null
          ? DateTime.parse(json['claimed_at'].toString())
          : null,
      inventoryId: json['inventory_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'surplus_id': id,
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'category': category,
    'description': description,
    'is_free': isFree,
    'price': price,
    'expiry_date': expiryDate?.toIso8601String(),
    'location': location,
    'status': status,
    'owner': owner.toJson(),
    'claimed_by': claimedBy,
    'claimed_at': claimedAt?.toIso8601String(),
    'inventory_id': inventoryId,
    'created_at': createdAt.toIso8601String(),
  };

  bool get isClaimed => status == 'claimed';
  bool get isExpired => status == 'expired';
  bool get isAvailable => status == 'available';
}

// ============================================================================
// CASHFLOW PREDICTION MODELS
// ============================================================================
class CashflowPrediction {
  final String id;
  final String businessId;
  final String riskLevel; // low, medium, high, critical
  final int daysUntilBroke;
  final double confidenceScore; // 0.0 to 1.0
  final DateTime createdAt;

  CashflowPrediction({
    required this.id,
    required this.businessId,
    required this.riskLevel,
    required this.daysUntilBroke,
    required this.confidenceScore,
    required this.createdAt,
  });

  factory CashflowPrediction.fromJson(Map<String, dynamic> json) {
    return CashflowPrediction(
      id: (json['prediction_id'] ?? json['id'] ?? '').toString(),
      businessId: (json['business_id'] ?? '').toString(),
      riskLevel: (json['risk_level'] ?? 'medium').toString(),
      daysUntilBroke: json['days_until_broke'] as int? ?? 0,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'prediction_id': id,
    'business_id': businessId,
    'risk_level': riskLevel,
    'days_until_broke': daysUntilBroke,
    'confidence_score': confidenceScore,
    'created_at': createdAt.toIso8601String(),
  };

  String get riskEmoji => {
    'low': '🟢',
    'medium': '🟡',
    'high': '🔴',
    'critical': '⚫'
  }[riskLevel] ?? '❓';

  bool get isCritical => riskLevel == 'critical';
}

class InventoryPrediction {
  final String id;
  final String businessId;
  final int criticalItems;
  final int warningItems;
  final double totalValueAtRisk;
  final DateTime createdAt;

  InventoryPrediction({
    required this.id,
    required this.businessId,
    required this.criticalItems,
    required this.warningItems,
    required this.totalValueAtRisk,
    required this.createdAt,
  });

  factory InventoryPrediction.fromJson(Map<String, dynamic> json) {
    return InventoryPrediction(
      id: (json['prediction_id'] ?? json['id'] ?? '').toString(),
      businessId: (json['business_id'] ?? '').toString(),
      criticalItems: json['critical_items'] as int? ?? 0,
      warningItems: json['warning_items'] as int? ?? 0,
      totalValueAtRisk: (json['total_value_at_risk'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'prediction_id': id,
    'business_id': businessId,
    'critical_items': criticalItems,
    'warning_items': warningItems,
    'total_value_at_risk': totalValueAtRisk,
    'created_at': createdAt.toIso8601String(),
  };

  int get totalAtRiskItems => criticalItems + warningItems;

  bool get hasRisk => totalAtRiskItems > 0;
}

// ============================================================================
// ANOMALY MODEL
// ============================================================================
class Anomaly {
  final String id;
  final String transactionId;
  final String anomalyLevel; // low, medium, high
  final double zScore;
  final double deviationPercentage;
  final String message;
  final DateTime createdAt;

  Anomaly({
    required this.id,
    required this.transactionId,
    required this.anomalyLevel,
    required this.zScore,
    required this.deviationPercentage,
    required this.message,
    required this.createdAt,
  });

  factory Anomaly.fromJson(Map<String, dynamic> json) {
    return Anomaly(
      id: (json['anomaly_id'] ?? json['id'] ?? '').toString(),
      transactionId: (json['transaction_id'] ?? '').toString(),
      anomalyLevel: (json['anomaly_level'] ?? 'low').toString(),
      zScore: (json['z_score'] as num?)?.toDouble() ?? 0,
      deviationPercentage: (json['deviation_percentage'] as num?)?.toDouble() ?? 0,
      message: (json['message'] ?? '').toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'anomaly_id': id,
    'transaction_id': transactionId,
    'anomaly_level': anomalyLevel,
    'z_score': zScore,
    'deviation_percentage': deviationPercentage,
    'message': message,
    'created_at': createdAt.toIso8601String(),
  };

  bool get isUnusual => zScore.abs() > 2.0;

  String get levelEmoji => {
    'low': '🔵',
    'medium': '🟡',
    'high': '🔴'
  }[anomalyLevel] ?? '❓';
}

// ============================================================================
// ALERT MODELS
// ============================================================================
class AlertInventory {
  final String itemName;
  final double quantity;
  final String unit;

  AlertInventory({
    required this.itemName,
    required this.quantity,
    required this.unit,
  });

  factory AlertInventory.fromJson(Map<String, dynamic> json) {
    return AlertInventory(
      itemName: (json['item_name'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unit: (json['unit'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'item_name': itemName,
    'quantity': quantity,
    'unit': unit,
  };
}

class Alert {
  final String id;
  final String alertType; // low_stock, expiry_warning, overstock, surplus_available
  final String severity; // low, medium, high, critical
  final String message;
  final AlertInventory? inventory;
  final bool isRead;
  final DateTime createdAt;

  Alert({
    required this.id,
    required this.alertType,
    required this.severity,
    required this.message,
    this.inventory,
    required this.isRead,
    required this.createdAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: (json['alert_id'] ?? json['id'] ?? '').toString(),
      alertType: (json['alert_type'] ?? '').toString(),
      severity: (json['severity'] ?? 'medium').toString(),
      message: (json['message'] ?? '').toString(),
      inventory: json['inventory'] != null
          ? AlertInventory.fromJson(json['inventory'])
          : null,
      isRead: json['is_read'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'alert_id': id,
    'alert_type': alertType,
    'severity': severity,
    'message': message,
    'inventory': inventory?.toJson(),
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
  };

  String get severityEmoji => {
    'low': '🟢',
    'medium': '🟡',
    'high': '🔴',
    'critical': '⚫'
  }[severity] ?? '❓';

  bool get isUnread => !isRead;
}

// ============================================================================
// ACTIVITY MODEL
// ============================================================================
class Activity {
  final String id;
  final String userId;
  final String action;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> details;
  final DateTime createdAt;

  Activity({
    required this.id,
    required this.userId,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.details,
    required this.createdAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: (json['activity_id'] ?? json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      entityType: (json['entity_type'] ?? '').toString(),
      entityId: (json['entity_id'] ?? '').toString(),
      details: (json['details'] as Map<String, dynamic>?) ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'activity_id': id,
    'user_id': userId,
    'action': action,
    'entity_type': entityType,
    'entity_id': entityId,
    'details': details,
    'created_at': createdAt.toIso8601String(),
  };

  String get actionLabel => action.replaceAll('.', ' ').toUpperCase();

  String get actionEmoji => {
    'inventory.insert': '➕',
    'inventory.update': '✏️',
    'inventory.delete': '🗑️',
    'transaction.insert': '💰',
    'surplus.create': '📦',
    'alert.create': '🔔',
  }[action] ?? '📝';
}

// ============================================================================
// AUDIT LOG MODEL
// ============================================================================
class AuditLog {
  final String id;
  final String userId;
  final String action;
  final String resource;
  final String resourceId;
  final Map<String, dynamic> changes;
  final DateTime timestamp;
  final String? ipAddress;

  AuditLog({
    required this.id,
    required this.userId,
    required this.action,
    required this.resource,
    required this.resourceId,
    required this.changes,
    required this.timestamp,
    this.ipAddress,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: (json['audit_log_id'] ?? json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      resource: (json['resource'] ?? '').toString(),
      resourceId: (json['resource_id'] ?? '').toString(),
      changes: (json['changes'] as Map<String, dynamic>?) ?? {},
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'].toString())
          : DateTime.now(),
      ipAddress: json['ip_address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'audit_log_id': id,
    'user_id': userId,
    'action': action,
    'resource': resource,
    'resource_id': resourceId,
    'changes': changes,
    'timestamp': timestamp.toIso8601String(),
    'ip_address': ipAddress,
  };
}

// ============================================================================
// CASHFLOW REPORT MODEL
// ============================================================================
class CashflowReport {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int cashRunwayDays;
  final double averageDailyBurn;
  final String period; // current_month, current_quarter, current_year
  final int transactionsCount;

  CashflowReport({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.cashRunwayDays,
    required this.averageDailyBurn,
    required this.period,
    required this.transactionsCount,
  });

  factory CashflowReport.fromJson(Map<String, dynamic> json) {
    return CashflowReport(
      totalIncome: (json['total_income'] as num?)?.toDouble() ?? 0,
      totalExpense: (json['total_expense'] as num?)?.toDouble() ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      cashRunwayDays: json['cash_runway_days'] as int? ?? 0,
      averageDailyBurn: (json['average_daily_burn'] as num?)?.toDouble() ?? 0,
      period: (json['period'] ?? 'current_month').toString(),
      transactionsCount: json['transactions_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'total_income': totalIncome,
    'total_expense': totalExpense,
    'balance': balance,
    'cash_runway_days': cashRunwayDays,
    'average_daily_burn': averageDailyBurn,
    'period': period,
    'transactions_count': transactionsCount,
  };

  double get netCashflow => totalIncome - totalExpense;

  bool get isHealthy => cashRunwayDays > 60;

  bool get isAtRisk => cashRunwayDays < 30;

  String get healthStatus {
    if (cashRunwayDays < 7) return 'CRITICAL';
    if (cashRunwayDays < 30) return 'AT RISK';
    if (cashRunwayDays < 60) return 'WARNING';
    return 'HEALTHY';
  }

  String get healthEmoji => {
    'CRITICAL': '⚫',
    'AT RISK': '🔴',
    'WARNING': '🟡',
    'HEALTHY': '🟢'
  }[healthStatus] ?? '❓';
}

// ============================================================================
// TRANSACTION MODEL
// ============================================================================
class Transaction {
  final String id;
  final String type; // income, expense, refund, adjustment
  final double amount;
  final String category;
  final String? description;
  final DateTime date;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    this.description,
    required this.date,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: (json['transaction_id'] ?? json['id'] ?? '').toString(),
      type: (json['type'] ?? 'expense').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      category: (json['category'] ?? 'Other').toString(),
      description: json['description']?.toString(),
      date: json['date'] != null || json['transaction_date'] != null
          ? DateTime.parse(
              (json['date'] ?? json['transaction_date']).toString())
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'transaction_id': id,
    'type': type,
    'amount': amount,
    'category': category,
    'description': description,
    'date': date.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  bool get isIncome => type == 'income';

  bool get isExpense => type == 'expense';

  String get typeEmoji => {
    'income': '📈',
    'expense': '📉',
    'refund': '↩️',
    'adjustment': '🔧'
  }[type] ?? '❓';
}

// ============================================================================
// SALE & PURCHASE MODELS
// ============================================================================
class Sale {
  final String id;
  final String inventoryId;
  final String itemName;
  final double quantitySold;
  final double unitPrice;
  final double totalAmount;
  final String? buyer;
  final String paymentStatus; // paid, pending, failed
  final DateTime saleDate;

  Sale({
    required this.id,
    required this.inventoryId,
    required this.itemName,
    required this.quantitySold,
    required this.unitPrice,
    required this.totalAmount,
    this.buyer,
    required this.paymentStatus,
    required this.saleDate,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: (json['sale_id'] ?? json['id'] ?? '').toString(),
      inventoryId: (json['inventory_id'] ?? '').toString(),
      itemName: (json['item_name'] ?? '').toString(),
      quantitySold: (json['quantity_sold'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      buyer: json['buyer']?.toString(),
      paymentStatus: (json['payment_status'] ?? 'pending').toString(),
      saleDate: json['sale_date'] != null
          ? DateTime.parse(json['sale_date'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'sale_id': id,
    'inventory_id': inventoryId,
    'item_name': itemName,
    'quantity_sold': quantitySold,
    'unit_price': unitPrice,
    'total_amount': totalAmount,
    'buyer': buyer,
    'payment_status': paymentStatus,
    'sale_date': saleDate.toIso8601String(),
  };

  bool get isPaid => paymentStatus == 'paid';

  String get statusEmoji => {
    'paid': '✅',
    'pending': '⏳',
    'failed': '❌'
  }[paymentStatus] ?? '❓';
}

class Purchase {
  final String id;
  final String inventoryId;
  final String itemName;
  final double quantityPurchased;
  final double unitCost;
  final double totalCost;
  final String? supplier;
  final DateTime purchaseDate;

  Purchase({
    required this.id,
    required this.inventoryId,
    required this.itemName,
    required this.quantityPurchased,
    required this.unitCost,
    required this.totalCost,
    this.supplier,
    required this.purchaseDate,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: (json['purchase_id'] ?? json['id'] ?? '').toString(),
      inventoryId: (json['inventory_id'] ?? '').toString(),
      itemName: (json['item_name'] ?? '').toString(),
      quantityPurchased: (json['quantity_purchased'] as num?)?.toDouble() ?? 0,
      unitCost: (json['unit_cost'] as num?)?.toDouble() ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0,
      supplier: json['supplier']?.toString(),
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'purchase_id': id,
    'inventory_id': inventoryId,
    'item_name': itemName,
    'quantity_purchased': quantityPurchased,
    'unit_cost': unitCost,
    'total_cost': totalCost,
    'supplier': supplier,
    'purchase_date': purchaseDate.toIso8601String(),
  };
}

// ============================================================================
// HEALTH STATUS MODEL (Optional - for diagnostics)
// ============================================================================
class HealthStatus {
  final String status; // ok, degraded, down
  final DateTime timestamp;
  final String? environment;

  HealthStatus({
    required this.status,
    required this.timestamp,
    this.environment,
  });

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    return HealthStatus(
      status: (json['status'] ?? 'unknown').toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'].toString())
          : DateTime.now(),
      environment: json['environment']?.toString(),
    );
  }

  bool get isHealthy => status == 'ok';
  bool get isDegraded => status == 'degraded';
  bool get isDown => status == 'down';
}
