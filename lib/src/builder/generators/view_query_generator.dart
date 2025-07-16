import '../elements/column/column_element.dart';
import '../elements/column/foreign_column_element.dart';
import '../elements/column/join_column_element.dart';
import '../elements/column/reference_column_element.dart';
import '../elements/column/view_column_element.dart';
import '../elements/view_element.dart';

String buildViewQuery(ViewElement view) {
  String tableName = view.table.tableName;
  String? primaryKeyName = view.table.primaryKeyColumn?.columnName;
  List<ViewColumnElement> columns = view.columns;

  var joins = <MapEntry<String, String>>[];

  for (var viewColumn in columns) {
    String? transform;
    if (viewColumn.transformer != null) {
      transform =
          '\${${viewColumn.transformer!}.transform(\'${viewColumn.paramName}\', \'$tableName\')}';
    }

    var column = viewColumn.column;

    String? tableReference;

    if (viewColumn.view != null) {
      tableReference = '(\${${viewColumn.view!.className}Queryable().query})';
    } else if (column is LinkedColumnElement) {
      tableReference = '"${column.linkedTable.tableName}"';
    }

    if (column is ForeignColumnElement) {
      joins.add(MapEntry(
        transform ??
            'row_to_json("${column.parameter!.name}".*) as "${column.parameter!.name}"',
        'LEFT JOIN $tableReference "${column.parameter!.name}"\n'
        'ON "$tableName"."${column.columnName}" = "${column.parameter!.name}"."${column.linkedTable.primaryKeyColumn!.columnName}"',
      ));
    } else if (column is ReferenceColumnElement) {
      if (!column.isList) {
        joins.add(MapEntry(
          transform ??
              'row_to_json("${column.parameter!.name}".*) as "${column.parameter!.name}"',
          'LEFT JOIN $tableReference "${column.parameter!.name}"\n'
          'ON "$tableName"."$primaryKeyName" = "${column.parameter!.name}"."${column.referencedColumn.columnName}"',
        ));
      } else {
        joins.add(MapEntry(
          transform ??
              '"${column.parameter!.name}"."data" as "${column.parameter!.name}"',
          'LEFT JOIN (\n'
          '  SELECT "${column.linkedTable.tableName}"."${column.referencedColumn.columnName}",\n'
          '    to_jsonb(array_agg("${column.linkedTable.tableName}".*)) as data\n'
          '  FROM $tableReference "${column.linkedTable.tableName}"\n'
          '  GROUP BY "${column.linkedTable.tableName}"."${column.referencedColumn.columnName}"\n'
          ') "${column.parameter!.name}"\n'
          'ON "$tableName"."$primaryKeyName" = "${column.parameter!.name}"."${column.referencedColumn.columnName}"',
        ));
      }
    } else if (column is JoinColumnElement) {
      joins.add(MapEntry(
        transform ??
            '"${column.parameter.name}"."data" as "${column.parameter.name}"',
        'LEFT JOIN (\n'
        '  SELECT "${column.joinTable.tableName}"."${column.columnName}",\n'
        '    to_jsonb(array_agg("${column.linkedTable.tableName}".*)) as data\n'
        '  FROM "${column.joinTable.tableName}"\n'
        '  LEFT JOIN $tableReference "${column.linkedTable.tableName}"\n'
        '  ON "${column.linkedTable.tableName}"."${column.linkedTable.primaryKeyColumn!.columnName}" = "${column.joinTable.tableName}"."${column.linkedTable.getForeignKeyName()!}"\n'
        '  GROUP BY "${column.joinTable.tableName}"."${column.columnName}"\n'
        ') "${column.parameter.name}"\n'
        'ON "$tableName"."$primaryKeyName" = "${column.parameter.name}"."${column.columnName}"',
      ));
    }
  }

  return 'SELECT "$tableName".*${joins.map((j) => ', ${j.key}').join()}\n'
      'FROM "$tableName"${joins.isNotEmpty ? '\n' : ''}'
      '${joins.map((j) => j.value).join('\n')}';
}
