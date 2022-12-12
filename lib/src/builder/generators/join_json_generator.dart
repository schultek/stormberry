import '../elements/column/column_element.dart';
import '../elements/join_table_element.dart';

class JoinJsonGenerator {
  Map<String, dynamic> generateJsonSchema(JoinTableElement join) {
    return {
      'columns': {
        join.first.getForeignKeyName(): {
          'type': getSqlType(join.first.primaryKeyParameter!.type),
        },
        join.second.getForeignKeyName(): {
          'type': getSqlType(join.second.primaryKeyParameter!.type),
        },
      },
      'constraints': [
        {
          'type': 'primary_key',
          'column': '${join.first.getForeignKeyName()}", "${join.second.getForeignKeyName()}',
        },
        {
          'type': 'foreign_key',
          'column': join.first.getForeignKeyName(),
          'target': '${join.first.tableName}.${join.first.primaryKeyColumn!.columnName}',
          'on_delete': 'cascade',
          'on_update': 'cascade',
        },
        {
          'type': 'foreign_key',
          'column': join.second.getForeignKeyName(),
          'target': '${join.second.tableName}.${join.second.primaryKeyColumn!.columnName}',
          'on_delete': 'cascade',
          'on_update': 'cascade',
        },
      ],
    };
  }
}
