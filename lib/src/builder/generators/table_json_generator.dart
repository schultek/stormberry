import '../column/column_builder.dart';
import '../column/foreign_column_builder.dart';
import '../table_builder.dart';

class TableJsonGenerator {
  Map<String, dynamic> generateJsonSchema(TableBuilder table) {
    return {
      'columns': {
        for (var column in table.columns)
          if (column is NamedColumnBuilder)
            column.columnName: {
              'type': column.sqlType,
              if (column.isNullable) 'isNullable': true,
            },
      },
      'constraints': [
        if (table.primaryKeyColumn != null)
          {
            'type': 'primary_key',
            'column': table.primaryKeyColumn!.columnName,
          },
        for (var column in table.columns)
          if (column is ForeignColumnBuilder)
            {
              'type': 'foreign_key',
              'column': column.columnName,
              'target': '${column.linkBuilder.tableName}.${column.linkBuilder.primaryKeyColumn!.columnName}',
              'on_delete': table.primaryKeyColumn != null ? 'set_null' : 'cascade',
              'on_update': 'cascade',
            },
        for (var column in table.columns)
          if (column is ForeignColumnBuilder && column.isUnique)
            {
              'type': 'unique',
              'column': column.columnName,
            },
      ],
      'indexes': [
        for (var index in table.indexes) index.toMap(),
      ],
      'views': [
        for (var view in table.views)
          {
            'table_name': table.tableName,
            'primary_key_name': table.primaryKeyColumn?.columnName,
            'name': view.viewTableName,
            'columns': [
              for (var column in view.columns) column.toMap(),
            ],
          },
      ],
    };
  }
}
