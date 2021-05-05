import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';

import '../utils.dart';
import 'table_builder.dart';

class ActionBuilder {
  TableBuilder table;
  DartObject? annotation;

  ActionBuilder(this.table, this.annotation, [this.fakeClassName]);

  String? fakeClassName;
  String? get className => annotation?.type!.element!.name! ?? fakeClassName;

  String buildActionMethod() {
    if (annotation == null) {
      return '';
    } else if (className == 'SingleInsertAction') {
      return ''
          'Future<void> insertOne(${table.element.name}InsertRequest request) {\n'
          '  return _db.runTransaction(() => ${table.element.name}InsertAction().apply(_db, [request]));\n'
          '}';
    } else if (className == 'MultiInsertAction') {
      return ''
          'Future<void> insertMany(List<${table.element.name}InsertRequest> requests) {\n'
          '  return _db.runTransaction(() => ${table.element.name}InsertAction().apply(_db, requests));\n'
          '}';
    } else if (className == 'SingleUpdateAction') {
      return ''
          'Future<void> updateOne(${table.element.name}UpdateRequest request) {\n'
          '  return _db.runTransaction(() => ${table.element.name}UpdateAction().apply(_db, [request]));\n'
          '}';
    } else if (className == 'MultiUpdateAction') {
      return ''
          'Future<void> updateMany(List<${table.element.name}UpdateRequest> requests) {\n'
          '  return _db.runTransaction(() => ${table.element.name}UpdateAction().apply(_db, requests));\n'
          '}';
    } else {
      var requestClassName = (annotation!.type!.element! as ClassElement)
          .supertype!
          .typeArguments[0]
          .getDisplayString(withNullability: true);
      return ''
          'Future<void> execute$className($requestClassName request) {\n'
          '  return _db.runTransaction(() => $className().apply(_db, request));\n'
          '}';
    }
  }

  String? generateClasses() {
    if (annotation == null) {
      return null;
    } else if (className == 'SingleInsertAction' ||
        className == 'MultiInsertAction') {
      return _generateInsertAction();
    } else if (className == 'SingleUpdateAction' ||
        className == 'MultiUpdateAction') {
      return _generateUpdateAction();
    }
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

    for (var column in table.columns.where((c) =>
        c.isReferenceColumn && c.linkBuilder!.primaryKeyColumn == null)) {
      if (column.linkBuilder!.columns
          .where((c) =>
              c.isForeignColumn && c.linkBuilder != table && !c.isNullable)
          .isNotEmpty) {
        continue;
      }

      var isNullable = column.isNullable;
      if (!column.isList) {
        var requestParams = column.linkBuilder!.columns
            .where((c) => !column.isJoinColumn)
            .map((c) {
          if (c.isForeignColumn) {
            if (c.linkBuilder == table) {
              return 'r.${table.primaryKeyColumn!.paramName}';
            } else {
              return 'null';
            }
          } else {
            return 'r.${column.paramName}${isNullable ? '!' : ''}.${c.paramName}';
          }
        });

        var deepInsert = ''
            'await ${column.linkBuilder!.element.name}InsertAction().apply(db, requests${isNullable ? '.where((r) => r.${column.paramName} != null)' : ''}.map((r) {\n'
            '  return ${column.linkBuilder!.element.name}InsertRequest(${requestParams.join(', ')});\n'
            '}).toList());';

        deepInserts.add(deepInsert);
      } else {
        var requestParams = column.linkBuilder!.columns
            .where((c) => !column.isJoinColumn)
            .map((c) {
          if (c.isForeignColumn) {
            if (c.linkBuilder == table) {
              return 'r.${table.primaryKeyColumn!.paramName}';
            } else {
              return 'null';
            }
          } else {
            return 'rr.${c.paramName}';
          }
        });

        var deepInsert = ''
            'await ${column.linkBuilder!.element.name}InsertAction().apply(db, requests${isNullable ? '.where((r) => r.${column.paramName} != null)' : ''}.expand((r) {\n'
            '  return r.${column.paramName}${isNullable ? '!' : ''}.map((rr) => ${column.linkBuilder!.element.name}InsertRequest(${requestParams.join(', ')}));\n'
            '}).toList());';

        deepInserts.add(deepInsert);
      }

      if (!column.linkBuilder!.hasDefaultInsertAction) {
        var deepActionBuilder =
            ActionBuilder(column.linkBuilder!, null, 'SingleInsertAction');
        column.linkBuilder!.actions.add(deepActionBuilder);
        additionalClasses.add(deepActionBuilder._generateInsertAction()!);
      }
    }

    String? onConflictClause;
    String? extensionClass;
    if (table.primaryKeyColumn != null) {
      onConflictClause =
          'ON CONFLICT ( "${table.primaryKeyColumn!.columnName}" ) DO UPDATE SET ${table.columns.where((c) => c != table.primaryKeyColumn && (c.isFieldColumn || c.isForeignColumn)).map((c) => '"${c.columnName}" = EXCLUDED."${c.columnName}"').join(', ')}';
    } else if (table.columns
            .where((c) => c.isForeignColumn && c.isUnique)
            .length ==
        1) {
      var foreignColumn = table.columns.firstWhere((c) => c.isForeignColumn);
      onConflictClause =
          'ON CONFLICT ( "${foreignColumn.columnName}" ) DO UPDATE SET ${table.columns.where((c) => c != foreignColumn && c.isFieldColumn).map((c) => '"${c.columnName}" = EXCLUDED."${c.columnName}"').join(', ')}';
    } else if (table.columns
            .where((c) => c.isForeignColumn && c.isUnique)
            .length >
        1) {
      onConflictClause =
          '\${requests.conflictKey != null ? \'ON CONFLICT ( "\${requests.conflictKey}" ) DO UPDATE SET ${table.columns.where((c) => c.isFieldColumn).map((c) => '"${c.columnName}" = EXCLUDED."${c.columnName}"').join(', ')}\' : \'\'}';
      extensionClass = ''
          'extension on List<$requestClassName> {\n'
          '  String? get conflictKey {\n'
          '    if (isEmpty) return null;\n'
          '${table.columns.where((c) => c.isForeignColumn).map((c) => '    if (first.${c.paramName} != null) return ${c.isUnique ? '\'${c.columnName}\'' : 'null'};').join('\n')}\n'
          '  }\n'
          '}';
    }

    var actionClass = ''
        'class $actionClassName implements Action<List<$requestClassName>> {\n'
        '  @override\n'
        '  Future<void> apply(Database db, List<$requestClassName> requests) async {\n'
        '    if (requests.isEmpty) return;\n'
        '    await db.query("""\n'
        '      INSERT INTO "${table.tableName}" ( ${table.columns.where((c) => c.isFieldColumn || c.isForeignColumn).map((c) => '"${c.columnName}"').join(', ')} )\n'
        '      VALUES \${requests.map((r) => \'( ${table.columns.where((c) => c.isFieldColumn || c.isForeignColumn).map((c) => '\${_encode(r.${c.paramName})}').join(', ')} )\').join(\', \')}\n'
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
      if (column.isFieldColumn ||
          (column.isReferenceColumn &&
              column.linkBuilder!.primaryKeyColumn == null)) {
        if (column.linkBuilder != null &&
            column.linkBuilder!.columns
                .where((c) =>
                    c.isForeignColumn &&
                    c.linkBuilder != table &&
                    !c.isNullable)
                .isNotEmpty) {
          continue;
        }
        requestFields.add(MapEntry(
          column.parameter!.type.getDisplayString(withNullability: true),
          column.paramName!,
        ));
      } else if (column.isForeignColumn) {
        var fieldNullSuffix = column.isNullable ? '?' : '';
        String fieldType;
        if (column.linkBuilder!.primaryKeyColumn == null) {
          fieldType = column.linkBuilder!.element.name;
        } else {
          fieldType = column.linkBuilder!.primaryKeyColumn!.dartType;
        }
        if (column.isList) {
          fieldType = 'List<$fieldType>';
        }
        requestFields.add(MapEntry(
          '$fieldType$fieldNullSuffix',
          column.paramName!,
        ));
      }
    }

    return ''
        'class $requestClassName {\n'
        '  ${requestFields.map((f) => '${f.key} ${f.value};').join('\n  ')}\n'
        '  \n'
        '  $requestClassName(${requestFields.map((f) => 'this.${f.value}').join(', ')});\n'
        '}';
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

    for (var column in table.columns.where((c) =>
        c.isReferenceColumn && c.linkBuilder!.primaryKeyColumn == null)) {
      if (!column.isList) {
        var requestParams = <String>[];
        for (var c
            in column.linkBuilder!.columns.where((c) => !column.isJoinColumn)) {
          if (c.isForeignColumn) {
            if (c.linkBuilder == table) {
              requestParams.add(
                  '${c.paramName}: r.${table.primaryKeyColumn!.paramName}');
            }
          } else {
            requestParams
                .add('${c.paramName}: r.${column.paramName}!.${c.paramName}');
          }
        }

        var deepInsert = ''
            'await ${column.linkBuilder!.element.name}UpdateAction().apply(db, requests.where((r) => r.${column.paramName} != null).map((r) {\n'
            '  return ${column.linkBuilder!.element.name}UpdateRequest(${requestParams.join(', ')});\n'
            '}).toList());';

        deepUpdates.add(deepInsert);
      } else {
        var requestParams = <String>[];
        for (var c
            in column.linkBuilder!.columns.where((c) => !column.isJoinColumn)) {
          if (c.isForeignColumn) {
            if (c.linkBuilder == table) {
              requestParams.add(
                  '${c.paramName}: r.${table.primaryKeyColumn!.paramName}');
            }
          } else {
            requestParams.add('${c.paramName}: rr.${c.paramName}');
          }
        }

        var deepInsert = ''
            'await ${column.linkBuilder!.element.name}UpdateAction().apply(db, requests.where((r) => r.${column.paramName} != null).expand((r) {\n'
            '  return r.${column.paramName}!.map((rr) => ${column.linkBuilder!.element.name}UpdateRequest(${requestParams.join(', ')}));\n'
            '}).toList());';

        deepUpdates.add(deepInsert);
      }

      if (!column.linkBuilder!.hasDefaultUpdateAction) {
        var deepActionBuilder =
            ActionBuilder(column.linkBuilder!, null, 'SingleUpdateAction');
        column.linkBuilder!.actions.add(deepActionBuilder);
        additionalClasses.add(deepActionBuilder._generateUpdateAction()!);
      }
    }

    var actionClass = ''
        'class $actionClassName implements Action<List<$requestClassName>> {\n'
        '  @override\n'
        '  Future<void> apply(Database db, List<$requestClassName> requests) async {\n'
        '    if (requests.isEmpty) return;\n'
        '    await db.query("""\n'
        '      UPDATE "${table.tableName}"\n'
        '      SET ${table.columns.where((c) => hasPrimaryKey ? c != table.primaryKeyColumn && (c.isFieldColumn || c.isForeignColumn) : c.isFieldColumn).map((c) => '"${c.columnName}" = COALESCE(UPDATED."${c.columnName}", "${table.tableName}"."${c.columnName}")').join(',\n          ')}\n'
        '      FROM ( VALUES \${requests.map((r) => \'( ${table.columns.where((c) => c.isFieldColumn || c.isForeignColumn).map((c) => '\${_encode(r.${c.paramName})}').join(', ')} )\').join(\', \')} )\n'
        '      AS UPDATED(${table.columns.where((c) => c.isFieldColumn || c.isForeignColumn).map((c) => '"${c.columnName}"').join(', ')})\n'
        '      WHERE ${hasPrimaryKey ? '"${table.tableName}"."${table.primaryKeyColumn!.columnName}" = UPDATED."${table.primaryKeyColumn!.columnName}"' : table.columns.where((c) => c.isForeignColumn).map((c) => '"${table.tableName}"."${c.columnName}" = UPDATED."${c.columnName}"').join(' AND ')}\n'
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
      if (column.isFieldColumn ||
          (column.isReferenceColumn &&
              column.linkBuilder!.primaryKeyColumn == null)) {
        requestFields.add(MapEntry(
          column.parameter!.type.getDisplayString(withNullability: false) +
              (column == table.primaryKeyColumn ? '' : '?'),
          column.paramName!,
        ));
      } else if (column.isForeignColumn) {
        String fieldType;
        if (column.linkBuilder!.primaryKeyColumn == null) {
          fieldType = column.linkBuilder!.element.name;
        } else {
          fieldType = column.linkBuilder!.primaryKeyColumn!.dartType;
        }
        if (column.isList) {
          fieldType = 'List<$fieldType>';
        }
        requestFields.add(MapEntry(
          '$fieldType?',
          column.paramName!,
        ));
      }
    }

    return ''
        'class $requestClassName {\n'
        '  ${requestFields.map((f) => '${f.key} ${f.value};').join('\n  ')}\n'
        '  \n'
        '  $requestClassName({${requestFields.map((f) => '${f.key.endsWith('?') ? '' : 'required '}this.${f.value}').join(', ')}});\n'
        '}';
  }
}
