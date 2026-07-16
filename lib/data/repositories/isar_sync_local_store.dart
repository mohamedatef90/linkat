import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/link.dart';
import '../../domain/entities/sync_types.dart';
import '../models/custom_category_model.dart';
import '../models/link_model.dart';
import '../services/sync_service.dart';

/// SyncLocalStore backed by the app's Isar database, with lastSyncAt kept in
/// SharedPreferences.
class IsarSyncLocalStore implements SyncLocalStore {
  static const _lastSyncKey = 'sync_last_sync_at';

  late final Future<Isar> db;

  IsarSyncLocalStore() {
    db = _initDb();
  }

  Future<Isar> _initDb() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return Isar.open(
        [LinkModelSchema, CustomCategoryModelSchema],
        directory: dir.path,
      );
    }
    return Future.value(Isar.getInstance());
  }

  @override
  Future<Link?> getByRemoteId(String remoteId) async {
    final isar = await db;
    final model =
        await isar.linkModels.filter().remoteIdEqualTo(remoteId).findFirst();
    return model?.toEntity();
  }

  @override
  Future<List<Link>> getAllSynced() async {
    final isar = await db;
    final models =
        await isar.linkModels.filter().remoteIdIsNotNull().findAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Link>> getLocalOnly() async {
    final isar = await db;
    final models = await isar.linkModels
        .filter()
        .remoteIdIsNull()
        .pendingOpEqualTo(PendingOp.none)
        .findAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Link>> getPendingOps() async {
    final isar = await db;
    final models = await isar.linkModels
        .filter()
        .not()
        .pendingOpEqualTo(PendingOp.none)
        .findAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Link> put(Link link) async {
    final isar = await db;
    final model = LinkModel.fromEntity(link);
    late int id;
    await isar.writeTxn(() async {
      id = await isar.linkModels.put(model);
    });
    return link.copyWith(id: id);
  }

  @override
  Future<void> deleteLocal(int id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.linkModels.delete(id);
    });
  }

  @override
  Future<DateTime?> getLastSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_lastSyncKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  @override
  Future<void> setLastSyncAt(DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, value.toUtc().toIso8601String());
  }
}
