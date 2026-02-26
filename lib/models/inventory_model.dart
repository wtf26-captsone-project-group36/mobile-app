enum ItemStatus { normal, warning, expired, error }

class InventoryItem {
  final String id;
  String name;
  String category;
  double quantity;
  String unit;
  DateTime? dateReceived;
  DateTime? expiryDate;
  double? purchasePrice;
  ItemStatus status;
  String? errorMessage;
  
  // Version tracking for conflict detection
  int version;
  DateTime? updatedAt;
  DateTime? syncedAt;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    this.dateReceived,
    this.expiryDate,
    this.purchasePrice,
    this.status = ItemStatus.normal,
    this.errorMessage,
    this.version = 1,
    this.updatedAt,
    this.syncedAt,
  });
}