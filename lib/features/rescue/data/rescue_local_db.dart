import 'package:hervest_ai/features/rescue/models/rescue_models.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class RescueLocalDb {
  RescueLocalDb._();

  static final RescueLocalDb instance = RescueLocalDb._();

  static const String _dbName = 'hervest_rescue.db';
  static const int _dbVersion = 3;

  static const String rescueActionsTable = 'rescue_actions';
  static const String badgeEarningsTable = 'badge_earnings';
  static const String impactMetricsTable = 'impact_metrics';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final fullPath = path.join(dbPath, _dbName);
    return openDatabase(
      fullPath,
      version: _dbVersion,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE $rescueActionsTable (
            id TEXT PRIMARY KEY,
            item_id TEXT NOT NULL,
            item_name TEXT NOT NULL,
            item_category TEXT NOT NULL,
            unit TEXT NOT NULL DEFAULT 'units',
            suggested_path TEXT NOT NULL,
            final_path TEXT NOT NULL,
            suggested_entity_category TEXT NOT NULL,
            final_entity_category TEXT NOT NULL,
            backend_surplus_id TEXT,
            was_overridden INTEGER NOT NULL,
            note TEXT,
            handover_details TEXT,
            pledged_at TEXT NOT NULL,
            completed_at TEXT,
            quantity REAL NOT NULL,
            estimated_value REAL NOT NULL,
            co2_factor_per_unit REAL NOT NULL,
            is_completed INTEGER NOT NULL,
            is_deferred INTEGER NOT NULL DEFAULT 0
          );
        ''');

        await db.execute('''
          CREATE TABLE $badgeEarningsTable (
            code TEXT PRIMARY KEY,
            earned_at TEXT NOT NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE $impactMetricsTable (
            id INTEGER PRIMARY KEY CHECK(id = 1),
            total_completed_rescues INTEGER NOT NULL,
            total_donations INTEGER NOT NULL,
            total_surplus_sales INTEGER NOT NULL,
            total_co2_avoided_kg REAL NOT NULL,
            total_value_recovered REAL NOT NULL
          );
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            ALTER TABLE $rescueActionsTable
            ADD COLUMN is_deferred INTEGER NOT NULL DEFAULT 0;
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            ALTER TABLE $rescueActionsTable
            ADD COLUMN unit TEXT NOT NULL DEFAULT 'units';
          ''');
          await db.execute('''
            ALTER TABLE $rescueActionsTable
            ADD COLUMN backend_surplus_id TEXT;
          ''');
        }
      },
    );
  }

  Future<List<RescueAction>> loadActions() async {
    final db = await database;
    final rows = await db.query(rescueActionsTable, orderBy: 'pledged_at DESC');
    return rows.map(_actionFromRow).toList();
  }

  Future<void> replaceActions(List<RescueAction> actions) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(rescueActionsTable);
      for (final action in actions) {
        await txn.insert(rescueActionsTable, _actionToRow(action));
      }
    });
  }

  Future<Set<String>> loadBadgeCodes() async {
    final db = await database;
    final rows = await db.query(badgeEarningsTable);
    return rows.map((row) => (row['code'] ?? '').toString()).toSet();
  }

  Future<void> replaceBadgeCodes(Set<String> codes) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(badgeEarningsTable);
      final now = DateTime.now().toIso8601String();
      for (final code in codes) {
        await txn.insert(badgeEarningsTable, {'code': code, 'earned_at': now});
      }
    });
  }

  Future<void> upsertImpactMetrics(ImpactMetrics metrics) async {
    final db = await database;
    await db.insert(impactMetricsTable, {
      'id': 1,
      'total_completed_rescues': metrics.totalCompletedRescues,
      'total_donations': metrics.totalDonations,
      'total_surplus_sales': metrics.totalSurplusSales,
      'total_co2_avoided_kg': metrics.totalCo2AvoidedKg,
      'total_value_recovered': metrics.totalValueRecovered,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Map<String, dynamic> _actionToRow(RescueAction action) {
    return {
      'id': action.id,
      'item_id': action.itemId,
      'item_name': action.itemName,
      'item_category': action.itemCategory,
      'unit': action.unit,
      'suggested_path': action.suggestedPath.name,
      'final_path': action.finalPath.name,
      'suggested_entity_category': action.suggestedEntityCategory.name,
      'final_entity_category': action.finalEntityCategory.name,
      'backend_surplus_id': action.backendSurplusId,
      'was_overridden': action.wasOverridden ? 1 : 0,
      'note': action.note,
      'handover_details': action.handoverDetails,
      'pledged_at': action.pledgedAt.toIso8601String(),
      'completed_at': action.completedAt?.toIso8601String(),
      'quantity': action.quantity,
      'estimated_value': action.estimatedValue,
      'co2_factor_per_unit': action.co2FactorPerUnit,
      'is_completed': action.isCompleted ? 1 : 0,
      'is_deferred': action.isDeferred ? 1 : 0,
    };
  }

  RescueAction _actionFromRow(Map<String, Object?> row) {
    return RescueAction(
      id: (row['id'] ?? '').toString(),
      itemId: (row['item_id'] ?? '').toString(),
      itemName: (row['item_name'] ?? '').toString(),
      itemCategory: (row['item_category'] ?? '').toString(),
      unit: (row['unit'] ?? 'units').toString(),
      suggestedPath: RescuePath.values.firstWhere(
        (value) => value.name == (row['suggested_path'] ?? '').toString(),
        orElse: () => RescuePath.donation,
      ),
      finalPath: RescuePath.values.firstWhere(
        (value) => value.name == (row['final_path'] ?? '').toString(),
        orElse: () => RescuePath.donation,
      ),
      suggestedEntityCategory: RescueEntityCategory.values.firstWhere(
        (value) =>
            value.name == (row['suggested_entity_category'] ?? '').toString(),
        orElse: () => RescueEntityCategory.foodKitchen,
      ),
      finalEntityCategory: RescueEntityCategory.values.firstWhere(
        (value) =>
            value.name == (row['final_entity_category'] ?? '').toString(),
        orElse: () => RescueEntityCategory.foodKitchen,
      ),
      backendSurplusId: row['backend_surplus_id']?.toString(),
      wasOverridden: (row['was_overridden'] as int? ?? 0) == 1,
      note: row['note']?.toString(),
      handoverDetails: row['handover_details']?.toString(),
      pledgedAt:
          DateTime.tryParse((row['pledged_at'] ?? '').toString()) ??
          DateTime.now(),
      completedAt: DateTime.tryParse((row['completed_at'] ?? '').toString()),
      quantity: (row['quantity'] as num?)?.toDouble() ?? 0,
      estimatedValue: (row['estimated_value'] as num?)?.toDouble() ?? 0,
      co2FactorPerUnit: (row['co2_factor_per_unit'] as num?)?.toDouble() ?? 0,
      isCompleted: (row['is_completed'] as int? ?? 0) == 1,
      isDeferred: (row['is_deferred'] as int? ?? 0) == 1,
    );
  }
}
