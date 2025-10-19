import 'dart:async';

import 'package:collection/collection.dart';
import 'package:postgres/postgres.dart';

import '../core/annotations.dart';
import '../core/query_params.dart';
import 'view_query.dart';

typedef Runnable<T> = FutureOr<T> Function();

abstract class ModelRepository {
  Future<T> query<T, U>(Query<T, U> query, U params);
  Future<void> run<T>(Action<T> action, T request);
}

abstract class BaseRepository implements ModelRepository {
  final Session db;

  final String tableName;
  final String? keyName;

  BaseRepository(this.db, {required this.tableName, this.keyName});

  /// Queries a single row by its key.
  Future<T?> queryOne<T, K>(K key, KeyedViewQueryable<T, K> q) async {
    var params = QueryParams(
      where: '"${q.tableAlias}"."${q.keyName}" = ${q.encodeKey(key)}',
      limit: 1,
    );
    return (await queryMany(q, params)).firstOrNull;
  }

  /// Queries multiple rows.
  ///
  /// The [params] can be used to filter, order, limit and offset the results.
  Future<List<T>> queryMany<T>(ViewQueryable<T> q, [QueryParams? params]) {
    return query(ViewQuery<T>(q), params ?? const QueryParams());
  }

  /// Runs a query on the database.
  @override
  Future<T> query<T, U>(Query<T, U> query, U params) {
    return query.apply(db, params);
  }

  /// Runs an action on the database.
  @override
  Future<void> run<T>(Action<T> action, T request) {
    return action.apply(db, request);
  }
}
