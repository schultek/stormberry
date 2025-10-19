import '../../core/case_style.dart';
import '../elements/column/column_element.dart';
import '../elements/column/field_column_element.dart';
import '../elements/column/foreign_column_element.dart';
import '../elements/column/join_column_element.dart';
import '../elements/column/reference_column_element.dart';
import '../elements/table_element.dart';
import '../utils.dart';

class InsertGenerator {
  String generateInsertMethod(TableElement table) {
    var deepInserts = <String>[];

    for (var column in table.columns) {
      if (column is ReferenceColumnElement && column.linkedTable.primaryKeyColumn == null) {
        if (column.linkedTable.columns
            .where((c) => c is ForeignColumnElement && c.linkedTable != table && !c.isNullable)
            .isNotEmpty) {
          continue;
        }

        var isNullable = column.isNullable;
        if (!column.isList) {
          var requestParams = column.linkedTable.columns.whereType<ParameterColumnElement>().map((
            c,
          ) {
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
              return '${c.paramName}: ${isNullable ? '' : 'r.'}${column.paramName}.${c.paramName}';
            }
          });

          var deepInsert = '''
            await db.${column.linkedTable.repoName}.insertMany([
              for (final r in requests)${isNullable ? ' if(r.${column.paramName} case final ${column.paramName}?)' : ''}
                ${column.linkedTable.element.name}InsertRequest(${requestParams.join(', ')}),
            ]);
          ''';

          deepInserts.add(deepInsert);
        } else {
          var requestParams = column.linkedTable.columns.whereType<ParameterColumnElement>().map((
            c,
          ) {
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
            await db.${column.linkedTable.repoName}.insertMany([
              for (final r in requests)${isNullable ? ' if (r.${column.paramName} case final ${column.paramName}?)' : ''}
                for (final rr in ${isNullable ? '' : 'r.'}${column.paramName})
                  ${column.linkedTable.element.name}InsertRequest(${requestParams.join(', ')}),
            ]);
          ''';

          deepInserts.add(deepInsert);
        }
      }

      if (column is JoinColumnElement) {
        deepInserts.add('''
          await _update${CaseStyle.pascalCase.transform(column.parameter.name ?? '')}([
            for (final r in requests) 
              if (r.${column.paramName} case final ${column.paramName}?) 
                (${table.primaryKeyColumn!.isAutoIncrement ? 'result[requests.indexOf(r)]' : 'r.${table.primaryKeyColumn!.paramName}'}, UpdateValues.set(${column.paramName})),
            ],
          );
        ''');
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

    var insertColumns = table.columns.whereType<NamedColumnElement>().where(
      (c) => c is! FieldColumnElement || !c.isAutoIncrement,
    );

    String toInsertValue(NamedColumnElement e) {
      final converter = e.converter;
      final value =
          converter != null
              ? '\${values.add(${converter.toSource()}.tryEncode(r.${e.paramName}))}:${e.rawSqlType}'
              : '\${values.add(r.${e.paramName})}:${e.rawSqlType}';
      if (e.defaultValue != null) {
        return '\${r.${e.paramName} != null ? \'$value\' : \'DEFAULT\'}';
      } else {
        return value;
      }
    }

    return '''
      @override
      Future<${keyReturnStatement != null ? 'List<int>' : 'void'}> insert(List<${table.element.name}InsertRequest> requests) async {
        if (requests.isEmpty) return${keyReturnStatement != null ? ' []' : ''};
        var values = QueryValues();
        ${autoIncrementStatement != null ? 'var rows = ' : ''}await db.execute(
          Sql.named('INSERT INTO "${table.tableName}" ( ${insertColumns.map((c) => '"${c.columnName}"').join(', ')} )\\n'
          'VALUES \${requests.map((r) => '( ${insertColumns.map(toInsertValue).join(', ')} )').join(', ')}\\n'
          ${autoIncrementStatement != null ? "'RETURNING \"${table.primaryKeyColumn!.columnName}\"'" : ''}),
          parameters: values.values,
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
          // Regular field column.
          requestFields.add(
            MapEntry(
              column.parameter.type.getDisplayString(withNullability: false) +
                  (column.isNullable || column.defaultValue != null ? '?' : ''),
              column.paramName,
            ),
          );
        }
      } else if (column is ReferenceColumnElement) {
        // Virtual one-to-one or one-to-many relation column.
        if (column.linkedTable.primaryKeyColumn == null) {
          // Skip if there is a non-nullable foreign key to some other table.
          if (column.linkedTable.columns.any(
            (c) => c is ForeignColumnElement && c.linkedTable != table && !c.isNullable,
          )) {
            continue;
          }
          requestFields.add(
            MapEntry(
              column.parameter!.type.getDisplayString(withNullability: true),
              column.paramName,
            ),
          );
        } else {
          // TODO: Handle insert requests for reference columns pointing to tables with primary keys.
        }
      } else if (column is ForeignColumnElement) {
        // Foreign key column.
        var fieldNullSuffix = column.isNullable ? '?' : '';
        String fieldType;
        if (column.linkedTable.primaryKeyColumn == null) {
          fieldType = column.linkedTable.element.name!;
          if (column.isList) {
            fieldType = 'List<$fieldType>';
          }
        } else {
          fieldType = column.linkedTable.primaryKeyColumn!.dartType;
        }
        requestFields.add(MapEntry('$fieldType$fieldNullSuffix', column.paramName));
      } else if (column is JoinColumnElement) {
        // Virtual many-to-many relation column.
        final fieldType = column.linkedTable.primaryKeyColumn!.dartType;
        final fieldName = column.paramName;
        requestFields.add(MapEntry('List<$fieldType>?', fieldName));
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

  String generateJoinMethods(TableElement table) {
    var methods = <String>[];

    for (var column in table.columns.whereType<JoinColumnElement>()) {
      final methodName = '_update${CaseStyle.pascalCase.transform(column.parameter.name ?? '')}';
      final keyType = table.primaryKeyColumn!.dartType;
      final valueType = column.linkedTable.primaryKeyColumn!.dartType;

      final joinTable = column.joinTable.tableName;
      final joinColumn = column.columnName;
      final referencedColumn = column.referencedColumn.columnName;

      methods.add('''
        Future<void> $methodName(List<($keyType, UpdateValues<$valueType>)> updates) async {
          if (updates.isEmpty) return;

          final removeAllValues = [
            for (final u in updates) if (u.\$2.mode == ValueMode.set)
              u.\$1,
          ];
          final removeValues = [
            for (final u in updates) if (u.\$2.mode == ValueMode.remove)
              for (final v in u.\$2.values) (u.\$1, v),
          ];
          final addValues = [
            for (final u in updates) 
              if (u.\$2.mode == ValueMode.add || u.\$2.mode == ValueMode.set)
                for (final v in u.\$2.values) (u.\$1, v),
          ];

          if (removeAllValues.isNotEmpty) {
            final queryValues = QueryValues();
            await db.execute(
              Sql.named(
                'DELETE FROM "$joinTable" WHERE "$joinColumn" IN ( \${removeAllValues.map((v) => queryValues.add(v)).join(', ')} )',
              ),
              parameters: queryValues.values,
            );
          }

          if (removeValues.isNotEmpty) {
            final queryValues = QueryValues();
            await db.execute(
              Sql.named(
                'DELETE FROM "$joinTable" WHERE ( "$joinColumn", "$referencedColumn" ) IN ( \${removeValues.map((v) => '( \${queryValues.add(v.\$1)}, \${queryValues.add(v.\$2)} )').join(', ')} )',
              ),
              parameters: queryValues.values,
            );
          }

          if (addValues.isNotEmpty) {
            final queryValues = QueryValues();
            await db.execute(
              Sql.named(
                'INSERT INTO "$joinTable" ( "$joinColumn", "$referencedColumn" ) VALUES \${addValues.map((v) => '( \${queryValues.add(v.\$1)}, \${queryValues.add(v.\$2)} )').join(', ')}',
              ),
              parameters: queryValues.values,
            );
          }
        }
      ''');
    }

    return methods.join('\n\n');
  }
}
