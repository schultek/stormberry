import '../elements/column/column_element.dart';
import '../elements/column/foreign_column_element.dart';
import '../elements/table_element.dart';

class TableJsonGenerator {
  Map<String, dynamic> generateJsonSchema(TableElement table) {
    return {
      'columns': {
        for (var column in table.columns)
          if (column is NamedColumnElement)
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
          if (column is ForeignColumnElement)
            {
              'type': 'foreign_key',
              'column': column.columnName,
              'target':
                  '${column.linkedTable.tableName}.${column.linkedTable.primaryKeyColumn!.columnName}',
              'on_delete': table.primaryKeyColumn != null ? 'set_null' : 'cascade',
              'on_update': 'cascade',
            },
        for (var column in table.columns)
          if (column is ForeignColumnElement && column.isUnique)
            {
              'type': 'unique',
              'column': column.columnName,
            },
      ],
      'indexes': [
        for (var index in table.indexes) index.toMap(),
      ],
    };
  }
}
