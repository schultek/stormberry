import 'dart:convert';

import 'package:collection/collection.dart';

import '../core/annotations.dart';
import '../core/database.dart';
import '../core/query_params.dart';
import 'model_registry.dart';

typedef Runnable = Future<void> Function();

abstract class ModelRepository {
  Future<T> query<T, U>(Query<T, U> query, U params);
  Future<void> run<T>(Action<T> action, T request);
}

abstract class ModelRepositoryInsert<InsertRequest> {
  Future<void> insertOne(InsertRequest request);
  Future<void> insertMany(List<InsertRequest> requests);
}

abstract class ModelRepositoryUpdate<UpdateRequest> {
  Future<void> updateOne(UpdateRequest request);
  Future<void> updateMany(List<UpdateRequest> requests);
}

abstract class ModelRepositoryDelete<DeleteRequest> {
  Future<void> deleteOne(DeleteRequest id);
  Future<void> deleteMany(List<DeleteRequest> ids);
}

mixin RepositoryDeleteMixin<DeleteRequest> on BaseRepository implements ModelRepositoryDelete<DeleteRequest> {
  Future<void> delete(Database db, List<DeleteRequest> keys);

  @override
  Future<void> deleteOne(DeleteRequest key) => transaction(() => delete(_db, [key]));
  @override
  Future<void> deleteMany(List<DeleteRequest> keys) => transaction(() => delete(_db, keys));
}

mixin RepositoryUpdateMixin<UpdateRequest> on BaseRepository implements ModelRepositoryUpdate<UpdateRequest> {
  Future<void> update(Database db, List<UpdateRequest> requests);

  @override
  Future<void> updateOne(UpdateRequest request) => transaction(() => update(_db, [request]));
  @override
  Future<void> updateMany(List<UpdateRequest> requests) => transaction(() => update(_db, requests));
}

mixin RepositoryInsertMixin<InsertRequest> on BaseRepository implements ModelRepositoryInsert<InsertRequest> {
  Future<void> insert(Database db, List<InsertRequest> requests);

  @override
  Future<void> insertOne(InsertRequest request) => transaction(() => insert(_db, [request]));
  @override
  Future<void> insertMany(List<InsertRequest> requests) => transaction(() => insert(_db, requests));
}

abstract class BaseRepository implements ModelRepository {
  final Database _db;

  BaseRepository({required Database db}) : _db = db;

  Future<T?> queryOne<T, K>(K key, KeyedViewQueryable<T, K> q) async {
    var params = QueryParams(where: '"${q.tableAlias}"."${q.keyName}" = ${q.encodeKey(key)}', limit: 1);
    return (await query(ViewQuery<T>(q), params)).firstOrNull;
  }

  Future<List<T>> queryMany<T>(ViewQueryable<T> q, [QueryParams? params]) {
    return query(ViewQuery<T>(q), params ?? const QueryParams());
  }

  @override
  Future<T> query<T, U>(Query<T, U> query, U params) {
    return query.apply(_db, params);
  }

  Future<void> transaction<T>(Runnable runnable) {
    return _db.runTransaction(runnable);
  }

  @override
  Future<void> run<T>(Action<T> action, T request) {
    return transaction(() => action.apply(_db, request));
  }
}

abstract class ViewQueryable<T> {
  String get tableName;
  String get tableAlias;

  T decode(TypedMap map);

  T Function(dynamic v) get decoder {
    return (v) {
      if (v is T) return v;
      if (v is Map) return decode(TypedMap(v.cast<String, dynamic>()));
      if (v is String) {
        try {
          decoder(jsonDecode(v));
        } catch (_) {}
      }
      throw 'Cannot decode value of type ${v.runtimeType} to $T';
    };
  }
}

abstract class KeyedViewQueryable<T, K> extends ViewQueryable<T> {
  String get keyName;

  String encodeKey(K key);
}

class ViewQuery<Result> implements Query<List<Result>, QueryParams> {
  ViewQuery(this.queryable);

  final ViewQueryable<Result> queryable;

  @override
  Future<List<Result>> apply(Database db, QueryParams params) async {
    var time = DateTime.now();
    var res = await db.query("""
      SELECT * FROM "${queryable.tableName}" "${queryable.tableAlias}"
      ${params.where != null ? "WHERE ${params.where}" : ""}
      ${params.orderBy != null ? "ORDER BY ${params.orderBy}" : ""}
      ${params.limit != null ? "LIMIT ${params.limit}" : ""}
      ${params.offset != null ? "OFFSET ${params.offset}" : ""}
    """);

    var results = res.map((row) => queryable.decode(TypedMap(row.toColumnMap()))).toList();
    print('Queried ${results.length} rows in ${DateTime.now().difference(time)}');
    return results;
  }
}
