import 'dart:convert';

import '../core/annotations.dart';
import '../core/database.dart';
import '../core/query_params.dart';
import 'text_encoder.dart';

abstract class ViewQueryable<T> {
  String get tableAlias;
  String get query;

  T decode(TypedMap map);

  T decoder(dynamic v) {
    if (v is T) return v;
    if (v is Map) return decode(TypedMap(v.cast<String, dynamic>()));
    if (v is String) {
      try {
        decoder(jsonDecode(v));
      } catch (_) {}
    }
    throw 'Cannot decode value of type ${v.runtimeType} to $T';
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
      SELECT * FROM (${queryable.query}) "${queryable.tableAlias}"
      ${params.where != null ? "WHERE ${params.where}" : ""}
      ${params.orderBy != null ? "ORDER BY ${params.orderBy}" : ""}
      ${params.limit != null ? "LIMIT ${params.limit}" : ""}
      ${params.offset != null ? "OFFSET ${params.offset}" : ""}
    """, params.values);

    var results = res.map((row) => queryable.decode(TypedMap(row.toColumnMap()))).toList();
    print('Queried ${results.length} rows in ${DateTime.now().difference(time)}');
    return results;
  }
}
