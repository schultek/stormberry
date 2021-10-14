import '../../helpers/utils.dart';
import '../column/column_builder.dart';
import '../column/field_column_builder.dart';
import '../column/foreign_column_builder.dart';
import '../column/reference_column_builder.dart';
import '../table_builder.dart';
import 'action_builder.dart';

class SingleInsertActionBuilder extends InsertActionBuilder {
  SingleInsertActionBuilder(TableBuilder table) : super(table);

  @override
  String generateActionMethod() {
    return 'Future<void> insertOne(${table.element.name}InsertRequest request) {\n'
        '  return run(${table.element.name}InsertAction(), [request]);\n'
        '}';
  }
}

class MultiInsertActionBuilder extends InsertActionBuilder {
  MultiInsertActionBuilder(TableBuilder table) : super(table);

  @override
  String generateActionMethod() {
    return 'Future<void> insertMany(List<${table.element.name}InsertRequest> requests) {\n'
        '  return run(${table.element.name}InsertAction(), requests);\n'
        '}';
  }
}

abstract class InsertActionBuilder extends ActionBuilder {
  InsertActionBuilder(TableBuilder table) : super(table);

  @override
  String? generateActionClass() {
    return _generateInsertAction();
  }

  bool _didGenerateInsertAction = false;
  String? _generateInsertAction() {
    if (_didGenerateInsertAction) {
      return null;
    }
    _didGenerateInsertAction = true;

    var requestClassName = '${table.element.name}InsertRequest';
    var requestClass = _generateInsertRequest();

    var actionClassName = '${table.element.name}InsertAction';

    var deepInserts = <String>[];
    var additionalClasses = <String>[];

    for (var column
        in table.columns.whereType<ReferenceColumnBuilder>().where((c) => c.linkBuilder.primaryKeyColumn == null)) {
      if (column.linkBuilder.columns
          .where((c) => c is ForeignColumnBuilder && c.linkBuilder != table && !c.isNullable)
          .isNotEmpty) {
        continue;
      }

      var isNullable = column.isNullable;
      if (!column.isList) {
        var requestParams = column.linkBuilder.columns.whereType<ParameterColumnBuilder>().map((c) {
          if (c is ForeignColumnBuilder) {
            if (c.linkBuilder == table) {
              return '${c.paramName}: r.${table.primaryKeyColumn!.paramName}';
            } else {
              return '${c.paramName}: null';
            }
          } else {
            return '${c.paramName}: r.${column.paramName}${isNullable ? '!' : ''}.${c.paramName}';
          }
        });

        var deepInsert =
            'await ${column.linkBuilder.element.name}InsertAction().apply(db, requests${isNullable ? '.where((r) => r.${column.paramName} != null)' : ''}.map((r) {\n'
            '  return ${column.linkBuilder.element.name}InsertRequest(${requestParams.join(', ')});\n'
            '}).toList());';

        deepInserts.add(deepInsert);
      } else {
        var requestParams = column.linkBuilder.columns.whereType<ParameterColumnBuilder>().map((c) {
          if (c is ForeignColumnBuilder) {
            if (c.linkBuilder == table) {
              return '${c.paramName}: r.${table.primaryKeyColumn!.paramName}';
            } else {
              return '${c.paramName}: null';
            }
          } else {
            return '${c.paramName}: rr.${c.paramName}';
          }
        });

        var deepInsert =
            'await ${column.linkBuilder.element.name}InsertAction().apply(db, requests${isNullable ? '.where((r) => r.${column.paramName} != null)' : ''}.expand((r) {\n'
            '  return r.${column.paramName}${isNullable ? '!' : ''}.map((rr) => ${column.linkBuilder.element.name}InsertRequest(${requestParams.join(', ')}));\n'
            '}).toList());';

        deepInserts.add(deepInsert);
      }

      if (!column.linkBuilder.hasDefaultInsertAction) {
        var deepActionBuilder = SingleInsertActionBuilder(column.linkBuilder);
        column.linkBuilder.actions.add(deepActionBuilder);
        additionalClasses.add(deepActionBuilder._generateInsertAction()!);
      }
    }

    String? onConflictClause;
    String? extensionClass;
    if (table.primaryKeyColumn != null) {
      onConflictClause =
          'ON CONFLICT ( "${table.primaryKeyColumn!.columnName}" ) DO UPDATE SET ${table.columns.whereType<NamedColumnBuilder>().where((c) => c != table.primaryKeyColumn).map((c) => '"${c.columnName}" = EXCLUDED."${c.columnName}"').join(', ')}';
    } else if (table.columns.where((c) => c is ForeignColumnBuilder && c.isUnique).length == 1) {
      var foreignColumn = table.columns.firstWhere((c) => c is ForeignColumnBuilder) as ForeignColumnBuilder;
      onConflictClause =
          'ON CONFLICT ( "${foreignColumn.columnName}" ) DO UPDATE SET ${table.columns.whereType<FieldColumnBuilder>().map((c) => '"${c.columnName}" = EXCLUDED."${c.columnName}"').join(', ')}';
    } else if (table.columns.where((c) => c is ForeignColumnBuilder && c.isUnique).length > 1) {
      onConflictClause =
          '\${requests.conflictKey != null ? \'ON CONFLICT ( "\${requests.conflictKey}" ) DO UPDATE SET ${table.columns.whereType<FieldColumnBuilder>().map((c) => '"${c.columnName}" = EXCLUDED."${c.columnName}"').join(', ')}\' : \'\'}';
      extensionClass = 'extension on List<$requestClassName> {\n'
          '  String? get conflictKey {\n'
          '    if (isEmpty) return null;\n'
          '${table.columns.whereType<ForeignColumnBuilder>().map((c) => '    if (first.${c.paramName} != null) return ${c.isUnique ? '\'${c.columnName}\'' : 'null'};').join('\n')}\n'
          '  }\n'
          '}';
    }

    var actionClass = 'class $actionClassName implements Action<List<$requestClassName>> {\n'
        '  @override\n'
        '  Future<void> apply(Database db, List<$requestClassName> requests) async {\n'
        '    if (requests.isEmpty) return;\n'
        '    await db.query("""\n'
        '      INSERT INTO "${table.tableName}" ( ${table.columns.whereType<NamedColumnBuilder>().map((c) => '"${c.columnName}"').join(', ')} )\n'
        '      VALUES \${requests.map((r) => \'( ${table.columns.whereType<NamedColumnBuilder>().map((c) => '\${_encode(r.${c.paramName})}').join(', ')} )\').join(\', \')}\n'
        '${onConflictClause != null ? '      $onConflictClause\n' : ''}'
        '    """);\n'
        '${deepInserts.isNotEmpty ? '\n${deepInserts.join('\n\n').indent('    ')}\n' : ''}'
        '  }\n'
        '}';

    var output = StringBuffer();

    output.write('$requestClass\n\n');

    if (extensionClass != null) {
      output.write('$extensionClass\n\n');
    }

    output.write(actionClass);
    output.writeAll(additionalClasses.map((c) => '\n\n$c'));

    return output.toString();
  }

  String _generateInsertRequest() {
    var requestClassName = '${table.element.name}InsertRequest';

    var requestFields = <MapEntry<String, String>>[];

    for (var column in table.columns) {
      if (column is FieldColumnBuilder) {
        requestFields.add(MapEntry(
          column.parameter.type.getDisplayString(withNullability: true),
          column.paramName,
        ));
      } else if (column is ReferenceColumnBuilder && column.linkBuilder.primaryKeyColumn == null) {
        if (column.linkBuilder.columns
            .where((c) => c is ForeignColumnBuilder && c.linkBuilder != table && !c.isNullable)
            .isNotEmpty) {
          continue;
        }
        requestFields.add(MapEntry(
          column.parameter!.type.getDisplayString(withNullability: true),
          column.paramName,
        ));
      } else if (column is ForeignColumnBuilder) {
        var fieldNullSuffix = column.isNullable ? '?' : '';
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
          '$fieldType$fieldNullSuffix',
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
