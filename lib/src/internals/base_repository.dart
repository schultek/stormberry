import 'dart:async';

import 'package:collection/collection.dart';

import '../core/annotations.dart';
import '../core/database.dart';
import '../core/query_params.dart';
import 'view_query.dart';

typedef Runnable<T> = FutureOr<T> Function();

abstract class ModelRepository {
  Future<T> query<T, U>(Query<T, U> query, U params);
  Future<void> run<T>(Action<T> action, T request);
}

abstract class BaseRepository implements ModelRepository {
  final Database db;

  final String tableName;
  final String? keyName;

  BaseRepository(this.db, {required this.tableName, this.keyName});

  Future<T?> queryOne<T, K>(K key, KeyedViewQueryable<T, K> q) async {
    var params =
        QueryParams(where: '"${q.tableAlias}"."${q.keyName}" = ${q.encodeKey(key)}', limit: 1);
    return (await queryMany(q, params)).firstOrNull;
  }

  Future<List<T>> queryMany<T>(ViewQueryable<T> q, [QueryParams? params]) {
    return query(ViewQuery<T>(q), params ?? const QueryParams());
  }

  @override
  Future<T> query<T, U>(Query<T, U> query, U params) {
    return query.apply(db, params);
  }

  Future<T> transaction<T>(Runnable<T> runnable) {
    return db.runTransaction(runnable);
  }

  @override
  Future<void> run<T>(Action<T> action, T request) {
    return transaction(() => action.apply(db, request));
  }
}
