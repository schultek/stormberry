import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';

import '../utils.dart';
import 'case_style.dart';
import 'table_builder.dart';
import 'view_builder.dart';

class QueryBuilder {
  TableBuilder table;
  DartObject? annotation;
  ViewBuilder? fakeView;

  QueryBuilder(this.table, this.annotation, [this.fakeView]);

  String? get viewName =>
      fakeView?.name ??
      annotation?.getField('viewName')?.toStringValue()?.toLowerCase();
  ViewBuilder? get view =>
      fakeView ?? table.views.where((v) => v.name == viewName).firstOrNull;

  bool isDefaultForView(ViewBuilder? view) {
    return view == this.view &&
        (className == 'SingleQuery' || className == 'MultiQuery');
  }

  String get className =>
      annotation == null ? 'SingleQuery' : annotation!.type!.element!.name!;

  String get resultClassName {
    if (className == 'SingleQuery' || className == 'MultiQuery') {
      if (view != null) {
        return view!.className;
      } else {
        return table.element.name;
      }
    } else {
      return (annotation!.type!.element! as ClassElement)
          .supertype!
          .typeArguments[0]
          .getDisplayString(withNullability: true);
    }
  }

  String get queryClassName {
    if (className == 'SingleQuery' || className == 'MultiQuery') {
      return '${resultClassName}Query';
    } else {
      return className;
    }
  }

  String buildQueryMethod() {
    if (className == 'SingleQuery') {
      var methodName = viewName != null
          ? toCaseStyle('query_${viewName}_view',
              CaseStyle.fromString(CaseStyle.camelCase))
          : 'queryOne';
      return ''
          'Future<$resultClassName?> $methodName(${table.primaryKeyColumn!.dartType} ${table.primaryKeyColumn!.paramName}) async {\n'
          '  return (await $queryClassName().apply(_db, QueryParams(\n'
          '    where: \'"${table.tableName}"."${table.primaryKeyColumn!.paramName}" = \\\'\$${table.primaryKeyColumn!.paramName}\\\'\',\n'
          '    limit: 1,\n'
          '  ))).firstOrNull;\n'
          '}';
    } else if (className == 'MultiQuery') {
      var methodName = viewName != null
          ? toCaseStyle('query_${viewName}_views',
              CaseStyle.fromString(CaseStyle.camelCase))
          : 'queryAll';
      return ''
          'Future<List<$resultClassName>> $methodName([QueryParams? params]) {\n'
          '  return $queryClassName().apply(_db, params ?? QueryParams());\n'
          '}';
    } else {
      var requestClassName = (annotation!.type!.element! as ClassElement)
          .supertype!
          .typeArguments[1]
          .getDisplayString(withNullability: true);
      return ''
          'Future<$resultClassName> execute$className($requestClassName request) {\n'
          '  return $queryClassName().apply(_db, request);\n'
          '}';
    }
  }

  String? generateClasses() {
    if (annotation == null) {
      return null;
    } else if (className == 'SingleQuery') {
      return _generateQueryClass();
    } else if (className == 'MultiQuery' &&
        !table.queries
            .any((q) => q.className == 'SingleQuery' && q.view == view)) {
      return _generateQueryClass();
    }
  }

  bool _didGenerateQueryClass = false;
  String? _generateQueryClass() {
    if (_didGenerateQueryClass) {
      return null;
    }
    _didGenerateQueryClass = true;

    var joinColumns = view != null
        ? view!.columns
        : table.columns
            .where((c) => c.parameter != null)
            .map((c) => ViewColumn(c, null));

    var joins = <MapEntry<String, String>>[];
    var additionalClasses = <String>[];

    for (var column in joinColumns) {
      if (column.column.isForeignColumn) {
        joins.add(MapEntry(
          column.paramName,
          'LEFT JOIN ( \${${column.queryClassName}._getQueryStatement()} ) "${column.paramName}"\n'
          'ON "${table.tableName}"."${column.column.columnName}" = "${column.paramName}"."${column.column.linkBuilder!.primaryKeyColumn!.columnName}"',
        ));

        if (!column.column.linkBuilder!.hasQueryForView(column.view)) {
          var deepQueryBuilder =
              QueryBuilder(column.column.linkBuilder!, null, column.view);
          column.column.linkBuilder!.queries.add(deepQueryBuilder);
          additionalClasses.add(deepQueryBuilder._generateQueryClass()!);
        }
      } else if (column.column.isReferenceColumn) {
        var columnTable = column.column.linkBuilder!;
        if (column.column.isList) {
          joins.add(MapEntry(
            column.paramName,
            'LEFT JOIN (\n'
            '  SELECT "${columnTable.tableName}"."${column.column.referencedColumn!.columnName}",\n'
            '    array_to_json(array_agg(row_to_json("${columnTable.tableName}".*))) as data\n'
            '  FROM ( \${${column.queryClassName}._getQueryStatement()} ) "${columnTable.tableName}"\n'
            '  GROUP BY "${columnTable.tableName}"."${column.column.referencedColumn!.columnName}"\n'
            ') "${column.paramName}"\n'
            'ON "${table.tableName}"."${table.primaryKeyColumn!.columnName}" = "${column.paramName}"."${column.column.referencedColumn!.columnName}"',
          ));
        } else {
          joins.add(MapEntry(
            column.paramName,
            'LEFT JOIN ( \${${column.queryClassName}._getQueryStatement()} ) "${column.paramName}"\n'
            'ON "${table.tableName}"."${table.primaryKeyColumn!.columnName}" = "${column.paramName}"."${column.column.referencedColumn!.columnName}"',
          ));
        }

        if (!column.column.linkBuilder!.hasQueryForView(column.view)) {
          var deepQueryBuilder =
              QueryBuilder(column.column.linkBuilder!, null, column.view);
          column.column.linkBuilder!.queries.add(deepQueryBuilder);
          additionalClasses.add(deepQueryBuilder._generateQueryClass()!);
        }
      } else if (column.column.isJoinColumn) {
        var columnTable = column.column.linkBuilder!;
        var joinTable = column.column.joinBuilder!;

        joins.add(MapEntry(
          column.paramName,
          'LEFT JOIN (\n'
          '  SELECT "${joinTable.tableName}"."${column.column.parentBuilder.getForeignKeyName()}",\n'
          '    array_to_json(array_agg(row_to_json("${columnTable.tableName}".*))) as data\n'
          '  FROM "${joinTable.tableName}"\n'
          '  LEFT JOIN ( \${${column.queryClassName}._getQueryStatement()} ) "${columnTable.tableName}"\n'
          '  ON "${columnTable.tableName}"."${columnTable.primaryKeyColumn!.columnName}" = "${joinTable.tableName}"."${columnTable.getForeignKeyName()}"\n'
          '  GROUP BY "${joinTable.tableName}"."${column.column.parentBuilder.getForeignKeyName()}"\n'
          ') "${column.paramName}"\n'
          'ON "${table.tableName}"."${table.primaryKeyColumn!.columnName}" = "${column.paramName}"."${column.column.parentBuilder.getForeignKeyName()}"',
        ));

        if (!column.column.linkBuilder!.hasQueryForView(column.view)) {
          var deepQueryBuilder =
              QueryBuilder(column.column.linkBuilder!, null, column.view);
          column.column.linkBuilder!.queries.add(deepQueryBuilder);
          additionalClasses.add(deepQueryBuilder._generateQueryClass()!);
        }
      }
    }

    if (isDefaultForView(null) &&
        table.state.decoders[table.element.name] == null) {
      additionalClasses.add(_generateModelExtension());
    }

    var output = StringBuffer();

    output.write(''
        'class $queryClassName implements Query<List<$resultClassName>, QueryParams> {\n'
        '  @override\n'
        '  Future<List<$resultClassName>> apply(Database db, QueryParams params) async {\n'
        '    var time = DateTime.now();\n'
        '    var res = await db.query("""\n'
        '      \${_getQueryStatement()}\n'
        '      \${params.where != null ? "WHERE \${params.where}" : ""}\n'
        '      \${params.orderBy != null ? "ORDER BY \${params.orderBy}" : ""}\n'
        '      \${params.limit != null ? "LIMIT \${params.limit}" : ""}\n'
        '      \${params.offset != null ? "OFFSET \${params.offset}" : ""}\n'
        '    """);\n'
        '    \n'
        '    var results = res.map((row) => _decode<$resultClassName>(row.toColumnMap())).toList();\n'
        '    print(\'Queried \${results.length} rows in \${DateTime.now().difference(time)}\');\n'
        '    return results;\n'
        '  }\n'
        '  \n'
        '  static String _getQueryStatement() {\n'
        '    return """\n'
        '      SELECT "${table.tableName}".* ${joins.map((j) => ', row_to_json("${j.key}".*) as "${j.key}"').join()}\n'
        '      FROM "${table.tableName}"\n'
        '${joins.map((j) => j.value).join('\n').indent('      ')}\n'
        '    """;\n'
        '  }\n'
        '}');

    output.writeAll(additionalClasses.map((c) => '\n\n$c'));

    return output.toString();
  }

  String _generateModelExtension() {
    table.state.decoders[table.element.name] = '${table.element.name}Decoder';

    var params = <String>[];

    for (var param in table.constructor.parameters) {
      var column = table.columns.firstWhere((c) => c.parameter == param);

      var str = '';

      if (param.isNamed) {
        str = '${param.name}: ';
      }

      str += 'map.get';
      if (param.type.isDartCoreList) {
        str += 'List';
      } else if (param.type.isDartCoreMap) {
        str += 'Map';
      }
      if (param.isOptional ||
          param.type.nullabilitySuffix == NullabilitySuffix.question) {
        str += 'Opt';
      }

      var key = column.isFieldColumn ? column.columnName : param.name;
      params.add("$str('$key')");
    }

    return ''
        'extension ${table.element.name}Decoder on ${table.element.name} {\n'
        '  static ${table.element.name} fromMap(Map<String, dynamic> map) {\n'
        '    return ${table.element.name}(${params.join(', ')});\n'
        '  }\n'
        '}';
  }
}
