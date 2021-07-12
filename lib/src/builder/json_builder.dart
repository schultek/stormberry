import '../core/schema.dart';
import '../helpers/utils.dart';
import 'table_builder.dart';

extension JsonTableBuilder on TableBuilder {
  String generateJsonSchema() {
    var args = <String>[];

    var cols = columns.where((c) => c.columnName != null).map((c) =>
        '"${c.columnName}": {"type": "${c.sqlType}"${c.isNullable ? ', "isNullable": true' : ''}}');

    args.add('"columns": {\n${cols.join(',\n').indent()}\n}');

    var cons = [];

    if (primaryKeyColumn != null) {
      cons.add(
          '{"type": "primary_key", "column": "${primaryKeyColumn!.columnName}"}');
    }

    for (var column in columns.where((c) => c.isForeignColumn)) {
      var columnName = column.columnName;
      var tableName = column.linkBuilder!.tableName;
      var keyName = column.linkBuilder!.primaryKeyColumn!.columnName;
      var action = primaryKeyColumn != null ? 'set_null' : 'cascade';
      cons.add(
          '{"type": "foreign_key", "column": "$columnName", "target": "$tableName.$keyName", "on_delete": "$action", "on_update": "cascade"}');
    }

    for (var column in columns.where((c) => c.isUnique && c.isForeignColumn)) {
      cons.add('{"type": "unique", "column": "${column.columnName}"}');
    }

    if (cons.isNotEmpty) {
      args.add('"constraints": [\n${cons.join(',\n').indent()}\n]');
    }

    // TODO remove outdated triggers

    var ind = [];

    for (var o in annotation.read('indexes').listValue) {
      var inp = [];
      var columns = o
          .getField('columns')!
          .toListValue()!
          .map((o) => '"${o.toStringValue()}"')
          .toList();
      inp.add('"columns": [${columns.join(', ')}]');
      var name = o.getField('name')!.toStringValue()!;
      inp.add('"name": "$name"');
      var unique = o.getField('unique')!.toBoolValue()!;
      if (unique) {
        inp.add('"unique": true');
      }
      var aIndex = o.getField('algorithm')!.getField('index')!.toIntValue()!;
      var algorithm = IndexAlgorithm.values[aIndex];
      if (algorithm != IndexAlgorithm.BTREE) {
        inp.add('"algorithm": "$algorithm"');
      }
      var condition = o.getField('condition')?.toStringValue();
      if (condition != null) {
        inp.add('"condition": "$condition"');
      }
      ind.add('{${inp.join(', ')}}');
    }

    if (ind.isNotEmpty) {
      args.add('"indexes": [\n${ind.join(',\n').indent()}\n]');
    }

    return '"$tableName": {\n${args.join(',\n').indent()}\n}';
  }
}
