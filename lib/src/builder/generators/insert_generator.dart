import '../column/column_builder.dart';
import '../column/field_column_builder.dart';
import '../column/foreign_column_builder.dart';
import '../column/reference_column_builder.dart';
import '../table_builder.dart';

class InsertGenerator {
  String generateInsertMethod(TableBuilder table) {
    var deepInserts = <String>[];

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

        var deepInsert = '''
          await _${column.linkBuilder.element.name}Repository(db).insert(db, requests${isNullable ? '.where((r) => r.${column.paramName} != null)' : ''}.map((r) {
            return ${column.linkBuilder.element.name}InsertRequest(${requestParams.join(', ')});
          }).toList());
        ''';

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

        var deepInsert = '''
          await _${column.linkBuilder.element.name}Repository(db).insert(db, requests${isNullable ? '.where((r) => r.${column.paramName} != null)' : ''}.expand((r) {
            return r.${column.paramName}${isNullable ? '!' : ''}.map((rr) => ${column.linkBuilder.element.name}InsertRequest(${requestParams.join(', ')}));
          }).toList());
        ''';

        deepInserts.add(deepInsert);
      }
    }

    String? onConflictClause;
    String? conflictKeyStatement;

    if (table.primaryKeyColumn != null) {
      onConflictClause =
          'ON CONFLICT ( "${table.primaryKeyColumn!.columnName}" ) DO UPDATE SET ${table.columns.whereType<NamedColumnBuilder>().where((c) => c != table.primaryKeyColumn).map((c) => '"${c.columnName}" = EXCLUDED."${c.columnName}"').join(', ')}';
    } else if (table.columns.where((c) => c is ForeignColumnBuilder && c.isUnique).length == 1) {
      var foreignColumn = table.columns.whereType<ForeignColumnBuilder>().first;
      onConflictClause =
          'ON CONFLICT ( "${foreignColumn.columnName}" ) DO UPDATE SET ${table.columns.whereType<FieldColumnBuilder>().map((c) => '"${c.columnName}" = EXCLUDED."${c.columnName}"').join(', ')}';
    } else if (table.columns.where((c) => c is ForeignColumnBuilder && c.isUnique).length > 1) {
      conflictKeyStatement =
          'var conflictKey = requests.isEmpty ? null : ${table.columns.whereType<ForeignColumnBuilder>().map((c) => 'requests.first.${c.paramName} != null ? ${c.isUnique ? "'${c.columnName}'" : 'mull'} : ').join()} null;';
      onConflictClause =
          "\${conflictKey != null ? 'ON CONFLICT (\"\$conflictKey\" ) DO UPDATE SET ${table.columns.whereType<FieldColumnBuilder>().map((c) => '"${c.columnName}" = EXCLUDED."${c.columnName}"').join(', ')}' : ''}";
    }

    return '''
      @override
      Future<void> insert(Database db, List<${table.element.name}InsertRequest> requests) async {
        if (requests.isEmpty) return;${conflictKeyStatement ?? ''}
        await db.query("""
          INSERT INTO "${table.tableName}" ( ${table.columns.whereType<NamedColumnBuilder>().map((c) => '"${c.columnName}"').join(', ')} )
          VALUES \${requests.map((r) => '( ${table.columns.whereType<NamedColumnBuilder>().map((c) => '\${registry.encode(r.${c.paramName})}').join(', ')} )').join(', ')}
          ${onConflictClause ?? ''}
        """);
        ${deepInserts.isNotEmpty ? deepInserts.join() : ''}
      }
    ''';
  }

  String generateInsertRequest(TableBuilder table) {
    var requestClassName = '${table.element.name}InsertRequest';
    var requestFields = <MapEntry<String, String>>[];

    for (var column in table.columns) {
      if (column is FieldColumnBuilder) {
        requestFields.add(MapEntry(column.parameter.type.getDisplayString(withNullability: true), column.paramName));
      } else if (column is ReferenceColumnBuilder && column.linkBuilder.primaryKeyColumn == null) {
        if (column.linkBuilder.columns
            .where((c) => c is ForeignColumnBuilder && c.linkBuilder != table && !c.isNullable)
            .isNotEmpty) {
          continue;
        }
        requestFields.add(MapEntry(column.parameter!.type.getDisplayString(withNullability: true), column.paramName));
      } else if (column is ForeignColumnBuilder) {
        var fieldNullSuffix = column.isNullable ? '?' : '';
        String fieldType;
        if (column.linkBuilder.primaryKeyColumn == null) {
          fieldType = column.linkBuilder.element.name;
          if (column.isList) {
            fieldType = 'List<$fieldType>';
          }
        } else {
          fieldType = column.linkBuilder.primaryKeyColumn!.dartType;
        }
        requestFields.add(MapEntry('$fieldType$fieldNullSuffix', column.paramName));
      }
    }

    return '''
      class $requestClassName {
        $requestClassName({${requestFields.map((f) => '${f.key.endsWith('?') ? '' : 'required '}this.${f.value}').join(', ')}});
        ${requestFields.map((f) => '${f.key} ${f.value};').join('\n')}
      }
    ''';
  }
}
