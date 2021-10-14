import '../../helpers/utils.dart';
import '../column/column_builder.dart';
import '../column/field_column_builder.dart';
import '../column/foreign_column_builder.dart';
import '../column/reference_column_builder.dart';
import '../table_builder.dart';
import 'action_builder.dart';

class SingleUpdateActionBuilder extends UpdateActionBuilder {
  SingleUpdateActionBuilder(TableBuilder table) : super(table);

  @override
  String generateActionMethod() {
    return 'Future<void> updateOne(${table.element.name}UpdateRequest request) {\n'
        '  return run(${table.element.name}UpdateAction(), [request]);\n'
        '}';
  }
}

class MultiUpdateActionBuilder extends UpdateActionBuilder {
  MultiUpdateActionBuilder(TableBuilder table) : super(table);

  @override
  String generateActionMethod() {
    return 'Future<void> updateMany(List<${table.element.name}UpdateRequest> requests) {\n'
        '  return run(${table.element.name}UpdateAction(), requests);\n'
        '}';
  }
}

abstract class UpdateActionBuilder extends ActionBuilder {
  UpdateActionBuilder(TableBuilder table) : super(table);

  @override
  String? generateActionClass() {
    return _generateUpdateAction();
  }

  bool _didGenerateUpdateAction = false;
  String? _generateUpdateAction() {
    if (_didGenerateUpdateAction) {
      return null;
    }
    _didGenerateUpdateAction = true;

    var requestClassName = '${table.element.name}UpdateRequest';
    var requestClass = _generateUpdateRequest();

    var actionClassName = '${table.element.name}UpdateAction';

    var hasPrimaryKey = table.primaryKeyColumn != null;

    var deepUpdates = <String>[];
    var additionalClasses = <String>[];

    for (var column
        in table.columns.whereType<ReferenceColumnBuilder>().where((c) => c.linkBuilder.primaryKeyColumn == null)) {
      if (!column.isList) {
        var requestParams = <String>[];
        for (var c in column.linkBuilder.columns.whereType<ParameterColumnBuilder>()) {
          if (c is ForeignColumnBuilder) {
            if (c.linkBuilder == table) {
              requestParams.add('${c.paramName}: r.${table.primaryKeyColumn!.paramName}');
            }
          } else {
            requestParams.add('${c.paramName}: r.${column.paramName}!.${c.paramName}');
          }
        }

        var deepInsert =
            'await ${column.linkBuilder.element.name}UpdateAction().apply(db, requests.where((r) => r.${column.paramName} != null).map((r) {\n'
            '  return ${column.linkBuilder.element.name}UpdateRequest(${requestParams.join(', ')});\n'
            '}).toList());';

        deepUpdates.add(deepInsert);
      } else {
        var requestParams = <String>[];
        for (var c in column.linkBuilder.columns.whereType<ParameterColumnBuilder>()) {
          if (c is ForeignColumnBuilder) {
            if (c.linkBuilder == table) {
              requestParams.add('${c.paramName}: r.${table.primaryKeyColumn!.paramName}');
            }
          } else {
            requestParams.add('${c.paramName}: rr.${c.paramName}');
          }
        }

        var deepInsert =
            'await ${column.linkBuilder.element.name}UpdateAction().apply(db, requests.where((r) => r.${column.paramName} != null).expand((r) {\n'
            '  return r.${column.paramName}!.map((rr) => ${column.linkBuilder.element.name}UpdateRequest(${requestParams.join(', ')}));\n'
            '}).toList());';

        deepUpdates.add(deepInsert);
      }

      if (!column.linkBuilder.hasDefaultUpdateAction) {
        var deepActionBuilder = SingleUpdateActionBuilder(column.linkBuilder);
        column.linkBuilder.actions.add(deepActionBuilder);
        additionalClasses.add(deepActionBuilder._generateUpdateAction()!);
      }
    }

    var actionClass = 'class $actionClassName implements Action<List<$requestClassName>> {\n'
        '  @override\n'
        '  Future<void> apply(Database db, List<$requestClassName> requests) async {\n'
        '    if (requests.isEmpty) return;\n'
        '    await db.query("""\n'
        '      UPDATE "${table.tableName}"\n'
        '      SET ${(hasPrimaryKey ? table.columns.whereType<NamedColumnBuilder>().where((c) => c != table.primaryKeyColumn) : table.columns.whereType<FieldColumnBuilder>()).map((c) => '"${c.columnName}" = COALESCE(UPDATED."${c.columnName}"::${c.sqlType}, "${table.tableName}"."${c.columnName}")').join(',\n          ')}\n'
        '      FROM ( VALUES \${requests.map((r) => \'( ${table.columns.whereType<NamedColumnBuilder>().map((c) => '\${_encode(r.${c.paramName})}').join(', ')} )\').join(\', \')} )\n'
        '      AS UPDATED(${table.columns.whereType<NamedColumnBuilder>().map((c) => '"${c.columnName}"').join(', ')})\n'
        '      WHERE ${hasPrimaryKey ? '"${table.tableName}"."${table.primaryKeyColumn!.columnName}" = UPDATED."${table.primaryKeyColumn!.columnName}"' : table.columns.whereType<ForeignColumnBuilder>().map((c) => '"${table.tableName}"."${c.columnName}" = UPDATED."${c.columnName}"').join(' AND ')}\n'
        '    """);\n'
        '${deepUpdates.isNotEmpty ? '\n${deepUpdates.join('\n\n').indent('    ')}\n' : ''}'
        '  }\n'
        '}';

    var output = StringBuffer();

    output.write('$requestClass\n\n');

    output.write(actionClass);
    output.writeAll(additionalClasses.map((c) => '\n\n$c'));

    return output.toString();
  }

  String _generateUpdateRequest() {
    var requestClassName = '${table.element.name}UpdateRequest';

    var requestFields = <MapEntry<String, String>>[];

    for (var column in table.columns) {
      if (column is FieldColumnBuilder) {
        requestFields.add(MapEntry(
          column.parameter.type.getDisplayString(withNullability: false) +
              (column == table.primaryKeyColumn ? '' : '?'),
          column.paramName,
        ));
      } else if (column is ReferenceColumnBuilder && column.linkBuilder.primaryKeyColumn == null) {
        requestFields.add(MapEntry(
          column.parameter!.type.getDisplayString(withNullability: false) +
              (column == table.primaryKeyColumn ? '' : '?'),
          column.paramName,
        ));
      } else if (column is ForeignColumnBuilder) {
        String fieldType;
        if (column.linkBuilder.primaryKeyColumn == null) {
          fieldType = column.linkBuilder.element.name;
        } else {
          fieldType = column.linkBuilder.primaryKeyColumn!.dartType;
        }
        if (column.isList) {
          fieldType = 'List<$fieldType>';
        }
        requestFields.add(MapEntry(
          '$fieldType?',
          column.paramName,
        ));
      }
    }

    return 'class $requestClassName {\n'
        '  ${requestFields.map((f) => '${f.key} ${f.value};').join('\n  ')}\n'
        '  \n'
        '  $requestClassName({${requestFields.map((f) => '${f.key.endsWith('?') ? '' : 'required '}this.${f.value}').join(', ')}});\n'
        '}';
  }
}
