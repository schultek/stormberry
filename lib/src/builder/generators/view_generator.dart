import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';

import '../elements/column/field_column_element.dart';
import '../elements/table_element.dart';
import '../utils.dart';
import '../elements/view_element.dart';
import 'view_query_generator.dart';

class ViewGenerator {
  String generateRepositoryMethods(TableElement table, {bool abstract = false}) {
    var str = StringBuffer();

    for (var view in table.views.values) {
      var viewName = view.viewName;

      if (table.primaryKeyColumn != null) {
        var paramType = table.primaryKeyColumn!.dartType;
        var paramName = table.primaryKeyColumn!.paramName;
        var signature = 'Future<${view.entityName}?> query$viewName($paramType $paramName)';
        if (abstract) {
          str.writeln('$signature;');
        } else {
          str.writeln(
            '@override $signature {\nreturn queryOne($paramName, ${view.entityName}Queryable());\n}',
          );
        }
      }

      var signature = 'Future<List<${view.entityName}>> query$viewName${viewName.endsWith('s') ? 'e' : ''}s([QueryParams? params])';
      if (abstract) {
        str.writeln('$signature;');
      } else {
        str.writeln('@override $signature {\nreturn queryMany(${view.entityName}Queryable(), params);\n}');
      }
    }

    return str.toString();
  }

  String generateViewClasses(TableElement table) {
    return table.views.values.map((v) => generateViewClass(v)).join('\n');
  }

  String generateViewClass(ViewElement view) {
    var hasKey = view.table.primaryKeyColumn != null;
    var keyType = hasKey ? view.table.primaryKeyColumn!.dartType : null;

    var implementsBase = view.name.isEmpty;

    return '''
      class ${view.entityName}Queryable extends ${hasKey ? 'Keyed' : ''}ViewQueryable<${view.entityName}${hasKey ? ', $keyType' : ''}> {
        ${hasKey ? '''
        @override
        String get keyName => '${view.table.primaryKeyColumn!.columnName}';
        
        @override
        String encodeKey($keyType key) => TypeEncoder.i.encode(key);
        ''' : ''}
        
        @override
        String get query => '${buildViewQuery(view).replaceAll('\n', "'\n'")}';
        
        @override
        String get tableAlias => '${view.table.tableName}';
        
        @override
        ${view.entityName} decode(TypedMap map) => ${view.className}(${view.columns.map((c) => '${c.paramName}: ${_getInitializer(c)}').join(',')});
      }
      
      ${view.table.annotateWith ?? ''}
      class ${view.className}${implementsBase ? ' implements ${view.table.element.name}' : ''} {
        ${view.className}(${view.columns.isEmpty ? '' : '{${view.columns.map((c) => '${c.isNullable ? '' : 'required '}this.${c.paramName}').join(', ')},}'});
        
        ${view.columns.map((c) => '${implementsBase ? '@override ' : ''}final ${c.dartType} ${c.paramName};').join('\n')}
      }
    ''';
  }

  String _getInitializer(ViewColumn c) {
    var column = c.column;
    var param = column.parameter!;
    var str = 'map.get';
    String? defVal;
    if (param.type.isDartCoreList) {
      str += 'List';
    } else if (param.type.isDartCoreMap) {
      str += 'Map';
    }
    if (param.type.nullabilitySuffix == NullabilitySuffix.question) {
      str += 'Opt';
    } else if (param.type.isDartCoreList) {
      str += 'Opt';
      defVal = 'const []';
    } else if (param.type.isDartCoreMap) {
      str += 'Opt';
      defVal = 'const {}';
    }

    var key = column is FieldColumnElement ? column.columnName : c.paramName;
    str += "('$key', ";

    if (c.view != null) {
      str += '${c.view!.entityName}Queryable().decoder)';
    } else if (c.column.converter != null) {
      str += '${c.column.converter!.toSource()}.decode)';
    } else if (c.column is FieldColumnElement && (c.column as FieldColumnElement).dataType.isEnum) {
      var e = (c.column as FieldColumnElement).dataType.element as EnumElement;
      str += 'EnumTypeConverter<${e.name}>(${e.name}.values).decode)';
    } else {
      str += 'TypeEncoder.i.decode)';
    }

    if (defVal != null) {
      str += ' ?? $defVal';
    }
    return str;
  }
}
