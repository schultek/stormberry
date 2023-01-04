import '../elements/table_element.dart';

class DeleteGenerator {
  String generateDeleteMethod(TableElement table) {
    var keyType = table.primaryKeyColumn?.dartType;
    if (keyType == null) return '';

    return '''
      @override
      Future<void> delete(Database db, List<$keyType> keys) async {
        if (keys.isEmpty) return;
        await db.query(
          'DELETE FROM "${table.tableName}"\\n'
          'WHERE "${table.tableName}"."${table.primaryKeyColumn!.columnName}" IN ( \${keys.map((k) => TypeEncoder.i.encode(k)).join(',')} )',
        );
      }
    ''';
  }
}
