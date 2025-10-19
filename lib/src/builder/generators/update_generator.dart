import '../../core/case_style.dart';
import '../elements/column/column_element.dart';
import '../elements/column/field_column_element.dart';
import '../elements/column/foreign_column_element.dart';
import '../elements/column/join_column_element.dart';
import '../elements/column/reference_column_element.dart';
import '../elements/table_element.dart';
import '../utils.dart';

class UpdateGenerator {
  String generateUpdateMethod(TableElement table) {
    var deepUpdates = <String>[];

    for (var column in table.columns) {
      if (column is ReferenceColumnElement && column.linkedTable.primaryKeyColumn == null) {
        // Skip if there is a non-nullable foreign key to some other table.
        if (column.linkedTable.columns
            .where((c) => c is ForeignColumnElement && c.linkedTable != table && !c.isNullable)
            .isNotEmpty) {
          continue;
        }

        if (!column.isList) {
          var requestParams = <String>[];
          for (var c in column.linkedTable.columns.whereType<ParameterColumnElement>()) {
            if (c is ForeignColumnElement) {
              if (c.linkedTable == table) {
                requestParams.add('${c.paramName}: r.${table.primaryKeyColumn!.paramName}');
              }
            } else {
              requestParams.add('${c.paramName}: ${column.paramName}.${c.paramName}');
            }
          }

          var deepUpdate = '''
            await db.${column.linkedTable.repoName}.updateMany([
              for (final r in requests) if (r.${column.paramName} case final ${column.paramName}?)
                ${column.linkedTable.element.name}UpdateRequest(${requestParams.join(', ')}),
            ]);
          ''';

          deepUpdates.add(deepUpdate);
        } else {
          var requestParams = <String>[];
          for (var c in column.linkedTable.columns.whereType<ParameterColumnElement>()) {
            if (c is ForeignColumnElement) {
              if (c.linkedTable == table) {
                requestParams.add('${c.paramName}: r.${table.primaryKeyColumn!.paramName}');
              }
            } else {
              requestParams.add('${c.paramName}: rr.${c.paramName}');
            }
          }

          var deepUpdate = '''
            await db.${column.linkedTable.repoName}.updateMany([
              for (final r in requests) if (r.${column.paramName} case final ${column.paramName}?)
                for (final rr in ${column.paramName})
                  ${column.linkedTable.element.name}UpdateRequest(${requestParams.join(', ')}),
            ]);
          ''';

          deepUpdates.add(deepUpdate);
        }
      }
      if (column is JoinColumnElement) {
        deepUpdates.add('''
          await _update${CaseStyle.pascalCase.transform(column.parameter.name ?? '')}([
            for (final r in requests) 
              if (r.${column.parameter.name} case final ${column.parameter.name}?) 
                (r.${table.primaryKeyColumn!.paramName}, ${column.parameter.name}),
          ]);
        ''');
      }
    }

    var hasPrimaryKey = table.primaryKeyColumn != null;
    var setColumns = table.columns.whereType<NamedColumnElement>().where(
      (c) =>
          (hasPrimaryKey ? c != table.primaryKeyColumn : c is FieldColumnElement) &&
          (c is! FieldColumnElement || !c.isAutoIncrement),
    );

    var updateColumns = table.columns.whereType<NamedColumnElement>().where(
      (c) => table.primaryKeyColumn == c || c is! FieldColumnElement || !c.isAutoIncrement,
    );

    String toUpdateValue(NamedColumnElement c) {
      if (c.converter != null) {
        return '\${values.add(${c.converter!.toSource()}.tryEncode(r.${c.paramName}))}:${c.rawSqlType}::${c.rawSqlType}';
      } else {
        return '\${values.add(r.${c.paramName})}:${c.rawSqlType}::${c.rawSqlType}';
      }
    }

    String whereClause;

    if (hasPrimaryKey) {
      whereClause =
          '"${table.tableName}"."${table.primaryKeyColumn!.columnName}" = UPDATED."${table.primaryKeyColumn!.columnName}"';
    } else {
      whereClause = table.columns
          .whereType<ForeignColumnElement>()
          .map((c) => '"${table.tableName}"."${c.columnName}" = UPDATED."${c.columnName}"')
          .join(' AND ');
    }

    return '''
        @override
        Future<void> update(List<${table.element.name}UpdateRequest> requests) async {
          if (requests.isEmpty) return;

          final updateRequests = [
            for (final r in requests)
              if (${updateColumns.where((c) => c != table.primaryKeyColumn).map((c) => 'r.${c.paramName} != null').join(' || ')})
                r
          ];

          if (updateRequests.isNotEmpty) {
            var values = QueryValues();
            await db.execute(
              Sql.named('UPDATE "${table.tableName}"\\n'
              'SET ${setColumns.map((c) => '"${c.columnName}" = COALESCE(UPDATED."${c.columnName}", "${table.tableName}"."${c.columnName}")').join(', ')}\\n'
              'FROM ( VALUES \${updateRequests.map((r) => '( ${updateColumns.map(toUpdateValue).join(', ')} )').join(', ')} )\\n'
              'AS UPDATED(${updateColumns.map((c) => '"${c.columnName}"').join(', ')})\\n'
              'WHERE $whereClause'),
              parameters: values.values,
            );
          }
          ${deepUpdates.isNotEmpty ? deepUpdates.join() : ''}
        }
      ''';
  }

  String generateUpdateRequest(TableElement table) {
    var requestClassName = '${table.element.name}UpdateRequest';
    var requestFields = <MapEntry<String, String>>[];

    for (var column in table.columns) {
      if (column is FieldColumnElement) {
        if (column == table.primaryKeyColumn || !column.isAutoIncrement) {
          // Regular field column.
          requestFields.add(
            MapEntry(
              column.parameter.type.getDisplayString(withNullability: false) +
                  (column == table.primaryKeyColumn ? '' : '?'),
              column.paramName,
            ),
          );
        }
      } else if (column is ReferenceColumnElement && column.linkedTable.primaryKeyColumn == null) {
        // Skip if there is a non-nullable foreign key to some other table.
        if (column.linkedTable.columns.any(
          (c) => c is ForeignColumnElement && c.linkedTable != table && !c.isNullable,
        )) {
          continue;
        }
        // Virtual one-to-one or one-to-many relation column.
        requestFields.add(
          MapEntry(
            column.parameter!.type.getDisplayString(withNullability: false) +
                (column == table.primaryKeyColumn ? '' : '?'),
            column.paramName,
          ),
        );
      } else if (column is ForeignColumnElement) {
        // Foreign key column.
        var fieldNullSuffix = column == table.primaryKeyColumn ? '' : '?';
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
        var fieldType = 'UpdateValues<${column.linkedTable.primaryKeyColumn!.dartType}>?';
        requestFields.add(MapEntry(fieldType, column.parameter.name ?? ''));
      }
    }

    final constructorParameters = requestFields
        .map((f) => '${f.key.endsWith('?') ? '' : 'required '}this.${f.value},')
        .join(' ');

    return '''
      ${defineClassWithMeta(requestClassName, table.meta?.read('update'))}
        $requestClassName(${constructorParameters.isNotEmpty ? '{$constructorParameters}' : ''});
        
        ${requestFields.map((f) => 'final ${f.key} ${f.value};').join('\n')}
      }
    ''';
  }
}
