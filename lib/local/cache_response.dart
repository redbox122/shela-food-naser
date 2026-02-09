import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
part 'cache_response.g.dart';

class CacheResponse extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get endPoint => text().unique()();
  TextColumn get header => text()();
  TextColumn get response => text()();
}

@DriftDatabase(tables: [CacheResponse])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'cache_response_new_db');
  }

  Future<int> insertCacheResponse(CacheResponseCompanion entry) async {
    return await into(cacheResponse).insert(entry);
  }

  /// Upsert by unique endpoint in a single write operation.
  /// This avoids read-then-write races under concurrent cache saves.
  Future<int> upsertCacheResponse(CacheResponseCompanion entry) async {
    return transaction<int>(() async {
      return into(cacheResponse).insertOnConflictUpdate(entry);
    });
  }

  Future<List<CacheResponseData>> getAllCacheResponses() async {
    return await select(cacheResponse).get();
  }

  Future<CacheResponseData?> getCacheResponseById(String endPoint) async {
    return await (select(cacheResponse)
          ..where((tbl) => tbl.endPoint.equals(endPoint)))
        .getSingleOrNull();
  }

  Future<int> updateCacheResponse(
      String endPoint, CacheResponseCompanion entry) async {
    return await (update(cacheResponse)
          ..where((tbl) => tbl.endPoint.equals(endPoint)))
        .write(entry);
  }

  Future<int> deleteCacheResponse(int id) async {
    return await (delete(cacheResponse)..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  Future<int> clearCacheResponses() async {
    return await delete(cacheResponse).go();
  }

  /// ⚡ Delete all cache entries matching a prefix pattern
  /// Used to clear stale pagination cache when loading fresh data
  Future<int> deleteCacheByPrefix(String prefix) async {
    return await (delete(cacheResponse)
          ..where((tbl) => tbl.endPoint.like('$prefix%')))
        .go();
  }
}
