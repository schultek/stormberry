import '../elements/column/column_element.dart';
import '../elements/column/field_column_element.dart';
import '../elements/column/foreign_column_element.dart';
import '../elements/column/reference_column_element.dart';
import '../elements/table_element.dart';
import '../utils.dart';

class InsertGenerator {
  String generateInsertMethod(TableElement table) {
    var deepInserts = <String>[];

    for (var column
        in table.columns.whereType<ReferenceColumnElement>().where((c) => c.linkedTable.primaryKeyColumn == null)) {
      if (column.linkedTable.columns
          .where((c) => c is ForeignColumnElement && c.linkedTable != table && !c.isNullable)
          .isNotEmpty) {
        continue;
      }

      var isNullable = column.isNullable;
      if (!column.isList) {
        var requestParams = column.linkedTable.columns.whereType<ParameterColumnElement>().map((c) {
          if (c is ForeignColumnElement) {
            if (c.linkedTable == table) {
              if (table.primaryKeyColumn!.isAutoIncrement) {
                return '${c.paramName}: TypeEncoder.i.decode(autoIncrements[requests.indexOf(r)][\'${table.primaryKeyColumn!.columnName}\'])';
              } else {
                return '${c.paramName}: r.${table.primaryKeyColumn!.paramName}';
              }
            } else {
              return '${c.paramName}: null';
            }
          } else {
            return '${c.paramName}: r.${column.paramName}${isNullable ? '!' : ''}.${c.paramName}';
          }
        });

        var deepInsert = '''
          await db.${column.linkedTable.repoName}.insertMany(requests${isNullable ? '.where((r) => r.${column.paramName} != null)' : ''}.map((r) {
            return ${column.linkedTable.element.name}InsertRequest(${requestParams.join(', ')});
          }).toList());
        ''';

        deepInserts.add(deepInsert);
      } else {
        var requestParams = column.linkedTable.columns.whereType<ParameterColumnElement>().map((c) {
          if (c is ForeignColumnElement) {
            if (c.linkedTable == table) {
              if (table.primaryKeyColumn!.isAutoIncrement) {
                return '${c.paramName}: TypeEncoder.i.decode(autoIncrements[requests.indexOf(r)][\'${table.primaryKeyColumn!.columnName}\'])';
              } else {
                return '${c.paramName}: r.${table.primaryKeyColumn!.paramName}';
              }
            } else {
              return '${c.paramName}: null';
            }
          } else {
            return '${c.paramName}: rr.${c.paramName}';
          }
        });

        var deepInsert = '''
          await db.${column.linkedTable.repoName}.insertMany(requests${isNullable ? '.where((r) => r.${column.paramName} != null)' : ''}.expand((r) {
            return r.${column.paramName}${isNullable ? '!' : ''}.map((rr) => ${column.linkedTable.element.name}InsertRequest(${requestParams.join(', ')}));
          }).toList());
        ''';

        deepInserts.add(deepInsert);
      }
    }

    var autoIncrementCols = table.columns.whereType<FieldColumnElement>().where((c) => c.isAutoIncrement);
    String? autoIncrementStatement, keyReturnStatement;

    if (autoIncrementCols.isNotEmpty) {
      autoIncrementStatement = '''
        var rows = await db.query(requests
          .map((r) => "SELECT ${autoIncrementCols.map((c) => "nextval('${c.parentTable.tableName}_${c.columnName}_seq') as \\\"${c.columnName}\\\"").join(', ')}")
          .join('\\nUNION ALL\\n')
        );
        var autoIncrements = rows.map((r) => r.toColumnMap()).toList();
      ''';

      if (table.primaryKeyColumn?.isAutoIncrement ?? false) {
        keyReturnStatement =
            "return autoIncrements.map<int>((m) => TypeEncoder.i.decode(m['${table.primaryKeyColumn!.columnName}'])).toList();";
      }
    }

    String? onConflictClause;
    String? conflictKeyStatement;

    if (table.primaryKeyColumn != null) {
      if (!table.primaryKeyColumn!.isAutoIncrement) {
        var conflictColumns = table.columns
            .whereType<NamedColumnElement>()
            .where((c) => c != table.primaryKeyColumn && (c is! FieldColumnElement || !c.isAutoIncrement));
        onConflictClause = '\n\'ON CONFLICT ( "${table.primaryKeyColumn!.columnName}" ) DO UPDATE SET '
            '${conflictColumns.map((c) => '"${c.columnName}" = EXCLUDED."${c.columnName}"').join(', ')}\'';
      }
    } else if (table.columns.where((c) => c is ForeignColumnElement && c.isUnique).length == 1) {
      var foreignColumn = table.columns.whereType<ForeignColumnElement>().first;
      var conflictColumns = table.columns.whereType<FieldColumnElement>().where((c) => !c.isAutoIncrement);
      onConflictClause = '\n\'ON CONFLICT ( "${foreignColumn.columnName}" ) DO UPDATE SET '
          '${conflictColumns.map((c) => '"${c.columnName}" = EXCLUDED."${c.columnName}"').join(', ')}\'';
    } else if (table.columns.where((c) => c is ForeignColumnElement && c.isUnique).length > 1) {
      var conflictColumns = table.columns.whereType<FieldColumnElement>().where((c) => !c.isAutoIncrement);
      conflictKeyStatement =
          'var conflictKey = requests.isEmpty ? null : ${table.columns.whereType<ForeignColumnElement>().map((c) => 'requests.first.${c.paramName} != null ? ${c.isUnique ? "'${c.columnName}'" : 'mull'} : ').join()} null;';
      onConflictClause = "\n'\${conflictKey != null ? 'ON CONFLICT (\"\$conflictKey\" ) DO UPDATE SET "
          "${conflictColumns.map((c) => '"${c.columnName}" = EXCLUDED."${c.columnName}"').join(', ')}' : ''}'";
    }

    var insertColumns = table.columns.whereType<NamedColumnElement>();

    String toInsertValue(NamedColumnElement c) {
      if (c is FieldColumnElement && c.isAutoIncrement) {
        return '\${TypeEncoder.i.encode(autoIncrements[requests.indexOf(r)][\'${c.columnName}\'])}';
      } else {
        return '\${TypeEncoder.i.encode(r.${c.paramName}${c.converter != null ? ', ${c.converter!.toSource()}' : ''})}';
      }
    }

    return '''
      @override
      Future<${keyReturnStatement != null ? 'List<int>' : 'void'}> insert(Database db, List<${table.element.name}InsertRequest> requests) async {
        if (requests.isEmpty) return${keyReturnStatement != null ? ' []' : ''};
        ${autoIncrementStatement ?? ''}
        ${conflictKeyStatement ?? ''}
        await db.query(
          'INSERT INTO "${table.tableName}" ( ${insertColumns.map((c) => '"${c.columnName}"').join(', ')} )\\n'
          'VALUES \${requests.map((r) => '( ${insertColumns.map(toInsertValue).join(', ')} )').join(', ')}\\n'${onConflictClause ?? ''},
        );
        ${deepInserts.isNotEmpty ? deepInserts.join() : ''}
        ${keyReturnStatement ?? ''}
      }
    ''';
  }

  String generateInsertRequest(TableElement table) {
    var requestClassName = '${table.element.name}InsertRequest';
    var requestFields = <MapEntry<String, String>>[];

    for (var column in table.columns) {
      if (column is FieldColumnElement) {
        if (!column.isAutoIncrement) {
          requestFields.add(MapEntry(column.parameter.type.getDisplayString(withNullability: true), column.paramName));
        }
      } else if (column is ReferenceColumnElement && column.linkedTable.primaryKeyColumn == null) {
        if (column.linkedTable.columns
            .where((c) => c is ForeignColumnElement && c.linkedTable != table && !c.isNullable)
            .isNotEmpty) {
          continue;
        }
        requestFields.add(MapEntry(column.parameter!.type.getDisplayString(withNullability: true), column.paramName));
      } else if (column is ForeignColumnElement) {
        var fieldNullSuffix = column.isNullable ? '?' : '';
        String fieldType;
        if (column.linkedTable.primaryKeyColumn == null) {
          fieldType = column.linkedTable.element.name;
          if (column.isList) {
            fieldType = 'List<$fieldType>';
          }
        } else {
          fieldType = column.linkedTable.primaryKeyColumn!.dartType;
        }
        requestFields.add(MapEntry('$fieldType$fieldNullSuffix', column.paramName));
      }
    }

    return '''
      ${table.annotateWith ?? ''}
      class $requestClassName {
        $requestClassName({${requestFields.map((f) => '${f.key.endsWith('?') ? '' : 'required '}this.${f.value}').join(', ')},});
        
        ${requestFields.map((f) => '${f.key} ${f.value};').join('\n')}
      }
    ''';
  }
}
