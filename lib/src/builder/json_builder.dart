import '../../stormberry.dart';
import 'column/column_builder.dart';
import 'column/foreign_column_builder.dart';
import 'table_builder.dart';

extension JsonTableBuilder on TableBuilder {
  Map<String, dynamic> generateJsonSchema() {
    return {
      'columns': {
        for (var column in columns)
          if (column is NamedColumnBuilder)
            column.columnName: {
              'type': column.sqlType,
              if (column.isNullable) 'isNullable': true,
            },
      },
      'constraints': [
        if (primaryKeyColumn != null)
          {
            'type': 'primary_key',
            'column': primaryKeyColumn!.columnName,
          },
        for (var column in columns)
          if (column is ForeignColumnBuilder)
            {
              'type': 'foreign_key',
              'column': column.columnName,
              'target': '${column.linkBuilder.tableName}.${column.linkBuilder.primaryKeyColumn!.columnName}',
              'on_delete': primaryKeyColumn != null ? 'set_null' : 'cascade',
              'on_update': 'cascade',
            },
        for (var column in columns)
          if (column is ForeignColumnBuilder && column.isUnique)
            {
              'type': 'unique',
              'column': column.columnName,
            },
      ],
      'indexes': [
        for (var o in annotation.read('indexes').listValue)
          {
            'columns': o.getField('columns')!.toListValue()!.map((o) => o.toStringValue()).toList(),
            'name': o.getField('name')!.toStringValue()!,
            'unique': o.getField('unique')!.toBoolValue()!,
            'algorithm': IndexAlgorithm.values[o.getField('algorithm')!.getField('index')!.toIntValue()!].toString(),
            'condition': o.getField('condition')?.toStringValue(),
          },
      ],
      'views': [
        for (var view in views)
          {
            'table_name': tableName,
            'primary_key_name': primaryKeyColumn?.columnName,
            'name': view.viewTableName,
            'columns': [
              for (var column in view.columns) column.toMap(),
            ],
          },
      ],
    };
  }
}
