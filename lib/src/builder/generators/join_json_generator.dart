import '../join_table_builder.dart';

class JoinJsonGenerator {
  Map<String, dynamic> generateJsonSchema(JoinTableBuilder join) {
    return {
      'columns': {
        join.first.getForeignKeyName(): {
          'type': join.first.primaryKeyColumn!.sqlType,
        },
        join.second.getForeignKeyName(): {
          'type': join.second.primaryKeyColumn!.sqlType,
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
