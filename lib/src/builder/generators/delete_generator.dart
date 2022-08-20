import '../table_builder.dart';

class DeleteGenerator {
  String generateDeleteMethod(TableBuilder table) {
    var keyType = table.primaryKeyColumn?.dartType;
    if (keyType == null) return '';

    return '''
      @override
      Future<void> delete(Database db, List<$keyType> keys) async {
        if (keys.isEmpty) return;
        await db.query(
          'DELETE FROM "${table.tableName}"\\n'
          'WHERE "${table.tableName}"."${table.primaryKeyColumn!.columnName}" IN ( \${keys.map((k) => registry.encode(k)).join(',')} )',
        );
      }
    ''';
  }
}
