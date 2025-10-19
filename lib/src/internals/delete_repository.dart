import 'package:postgres/postgres.dart';

import '../core/query_params.dart';
import 'base_repository.dart';

abstract class ModelRepositoryDelete<DeleteRequest> {
  /// Deletes a single row by its key.
  Future<void> deleteOne(DeleteRequest id);

  /// Deletes multiple rows by their keys.
  Future<void> deleteMany(List<DeleteRequest> ids);
}

mixin RepositoryDeleteMixin<DeleteRequest> on BaseRepository
    implements ModelRepositoryDelete<DeleteRequest> {
  Future<void> delete(List<DeleteRequest> keys) async {
    if (keys.isEmpty) return;
    var values = QueryValues();
    await db.execute(
      Sql.named('''
      DELETE FROM "$tableName"
      WHERE "$tableName"."$keyName" IN ( ${keys.map((k) => values.add(k)).join(', ')} )
    '''),
      parameters: values.values,
    );
  }

  @override
  Future<void> deleteOne(DeleteRequest key) => delete([key]);

  @override
  Future<void> deleteMany(List<DeleteRequest> keys) => delete(keys);
}
