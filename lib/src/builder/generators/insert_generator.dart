import '../elements/column/column_element.dart';
import '../elements/column/field_column_element.dart';
import '../elements/column/foreign_column_element.dart';
import '../elements/column/reference_column_element.dart';
import '../elements/table_element.dart';
import '../utils.dart';

class InsertGenerator {
  String generateInsertMethod(TableElement table) {
    var deepInserts = <String>[];

    for (var column in table.columns
        .whereType<ReferenceColumnElement>()
        .where((c) => c.linkedTable.primaryKeyColumn == null)) {
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
                return '${c.paramName}: result[requests.indexOf(r)]';
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
                return '${c.paramName}: result[requests.indexOf(r)]';
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

    String? autoIncrementStatement, keyReturnStatement;

    if (table.primaryKeyColumn?.isAutoIncrement ?? false) {
      var name = table.primaryKeyColumn!.columnName;
      autoIncrementStatement = '''
        var result = rows.map<int>((r) => TextEncoder.i.decode(r.toColumnMap()['$name'])).toList();
      ''';

      keyReturnStatement = 'return result;';
    }

    var insertColumns = table.columns
        .whereType<NamedColumnElement>()
        .where((c) => c is! FieldColumnElement || !c.isAutoIncrement);

    String toInsertValue(NamedColumnElement c) {
      if (c.converter != null) {
        return '\${values.add(${c.converter!.toSource()}.tryEncode(r.${c.paramName}))}:${c.rawSqlType}';
      } else {
        return '\${values.add(r.${c.paramName}${c.converter != null ? ', ${c.converter!.toSource()}' : ''})}:${c.rawSqlType}';
      }
    }

    return '''
      @override
      Future<${keyReturnStatement != null ? 'List<int>' : 'void'}> insert(List<${table.element.name}InsertRequest> requests) async {
        if (requests.isEmpty) return${keyReturnStatement != null ? ' []' : ''};
        var values = QueryValues();
        ${autoIncrementStatement != null ? 'var rows = ' : ''}await db.query(
          'INSERT INTO "${table.tableName}" ( ${insertColumns.map((c) => '"${c.columnName}"').join(', ')} )\\n'
          'VALUES \${requests.map((r) => '( ${insertColumns.map(toInsertValue).join(', ')} )').join(', ')}\\n'
          ${autoIncrementStatement != null ? "'RETURNING \"${table.primaryKeyColumn!.columnName}\"'" : ''},
          values.values,
        );
        ${autoIncrementStatement ?? ''}
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
          requestFields.add(MapEntry(
              column.parameter.type.getDisplayString(withNullability: true), column.paramName));
        }
      } else if (column is ReferenceColumnElement && column.linkedTable.primaryKeyColumn == null) {
        if (column.linkedTable.columns
            .where((c) => c is ForeignColumnElement && c.linkedTable != table && !c.isNullable)
            .isNotEmpty) {
          continue;
        }
        requestFields.add(MapEntry(
            column.parameter!.type.getDisplayString(withNullability: true), column.paramName));
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

    var constructorParameters = requestFields
        .map((f) => '${f.key.endsWith('?') ? '' : 'required '}this.${f.value},')
        .join(' ');

    return '''
      ${defineClassWithMeta(requestClassName, table.meta?.read('insert'))}
        $requestClassName(${constructorParameters.isNotEmpty ? '{$constructorParameters}' : ''});
        
        ${requestFields.map((f) => 'final ${f.key} ${f.value};').join('\n')}
      }
    ''';
  }
}
