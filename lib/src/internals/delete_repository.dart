import '../core/query_params.dart';
import 'base_repository.dart';

abstract class ModelRepositoryDelete<DeleteRequest> {
  Future<void> deleteOne(DeleteRequest id);
  Future<void> deleteMany(List<DeleteRequest> ids);
}

mixin RepositoryDeleteMixin<DeleteRequest> on BaseRepository
    implements ModelRepositoryDelete<DeleteRequest> {
  Future<void> delete(List<DeleteRequest> keys) async {
    if (keys.isEmpty) return;
    var values = QueryValues();
    await db.query(
      'DELETE FROM "$tableName"\n'
      'WHERE "$tableName"."$keyName" IN ( ${keys.map((k) => values.add(k)).join(', ')} )',
      values.values,
    );
  }

  @override
  Future<void> deleteOne(DeleteRequest key) => transaction(() => delete([key]));
  @override
  Future<void> deleteMany(List<DeleteRequest> keys) => transaction(() => delete(keys));
}
