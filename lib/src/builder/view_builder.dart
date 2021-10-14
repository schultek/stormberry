import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';

import '../core/case_style.dart';
import 'column/column_builder.dart';
import 'column/field_column_builder.dart';
import 'table_builder.dart';

class ViewColumn {
  String? viewAs;
  String? transformer;

  ColumnBuilder column;

  ViewColumn(this.column, {this.viewAs, this.transformer});

  ViewBuilder? get view {
    var c = column;
    if (c is LinkedColumnBuilder) {
      if (viewAs != null) {
        return c.linkBuilder.views.firstWhere((v) => v.name == viewAs!.toLowerCase());
      } else {
        return c.linkBuilder.views.firstWhere((v) => v.name.isEmpty);
      }
    }
  }

  String get paramName {
    return column.parameter!.name;
  }

  String get dartType {
    if (viewAs != null) {
      var isList = column.isList;
      var nullSuffix = column.parameter!.type.nullabilitySuffix;
      var typeSuffix = nullSuffix == NullabilitySuffix.question ? '?' : '';
      return isList ? 'List<${view!.className}>$typeSuffix' : '${view!.className}$typeSuffix';
    } else {
      return column.parameter!.type.getDisplayString(withNullability: true);
    }
  }

  String? get tableName {
    if (view != null) {
      return view!.viewTableName;
    } else if (column is LinkedColumnBuilder) {
      return (column as LinkedColumnBuilder).linkBuilder.tableName;
    }
  }

  Map<String, dynamic> toMap() {
    return column.toMap()
      ..addAll({
        if (transformer != null) 'transformer': transformer,
        if (column is! FieldColumnBuilder) 'table_name': tableName,
      });
  }
}

class ViewBuilder {
  TableBuilder table;
  DartObject? annotation;

  ViewBuilder(this.table, this.annotation);

  String get name => annotation?.getField('name')!.toStringValue()!.toLowerCase() ?? '';
  String get className => CaseStyle.pascalCase
      .transform(name.isNotEmpty ? '${name}_${table.element.name}_view' : '${table.element.name}_view');

  String get viewTableName => name.isNotEmpty ? '${name}_${table.tableName}_view' : '${table.tableName}_view';

  List<ViewColumn>? _columns;
  List<ViewColumn> get columns => _columns ??= _getViewColumns();
  List<ViewColumn> _getViewColumns() {
    var viewFields = annotation != null
        ? Map.fromEntries(
            annotation!
                .getField('fields')!
                .toListValue()!
                .map((f) => MapEntry(f.getField('name')!.toStringValue()!, f)),
          )
        : <String, DartObject>{};

    var columns = <ViewColumn>[];

    for (var column in table.columns) {
      if (column.parameter == null) {
        continue;
      }
      if (viewFields.containsKey(column.parameter!.name)) {
        var fieldName = column.parameter!.name;
        var viewField = viewFields[fieldName]!;

        var isHidden = viewField.getField('isHidden')!.toBoolValue()!;

        if (isHidden) {
          continue;
        }

        var viewAs = viewField.getField('viewAs')!.toStringValue();

        if (viewAs == null && column is LinkedColumnBuilder) {
          if (!column.linkBuilder.views.any((v) => v.name.isEmpty)) {
            column.linkBuilder.views.add(ViewBuilder(column.linkBuilder, null));
          }
        }

        var transformer = viewField.getField('transformer')!;
        while (transformer.getField('(super)') != null) {
          transformer = transformer.getField('(super)')!;
        }
        var statement = transformer.getField('statement')?.toStringValue()?.replaceAll(RegExp(r'\s+'), ' ').trim();

        columns.add(ViewColumn(column, viewAs: viewAs, transformer: statement));
      } else {
        if (column is LinkedColumnBuilder) {
          if (!column.linkBuilder.views.any((v) => v.name.isEmpty)) {
            column.linkBuilder.views.add(ViewBuilder(column.linkBuilder, null));
          }
        }

        columns.add(ViewColumn(column));
      }
    }

    return columns;
  }

  String generateClass() {
    if (annotation != null) {
      table.state.decoders[className] = className;
      return 'class $className {\n'
          '  $className(${columns.map((c) => 'this.${c.paramName}').join(', ')});\n'
          '  $className.fromMap(Map<String, dynamic> map)\n'
          '    : ${columns.map((c) => '${c.paramName} = ${_getInitializer(c)}').join(',\n      ')};\n'
          '  \n'
          '  ${columns.map((c) => '${c.dartType} ${c.paramName};').join('\n  ')}\n'
          '}';
    } else {
      return _generateModelExtension();
    }
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
      if (param.isOptional || param.type.nullabilitySuffix == NullabilitySuffix.question) {
        str += 'Opt';
      }

      var key = column is FieldColumnBuilder ? column.columnName : param.name;
      params.add("$str('$key')");
    }

    return 'extension ${table.element.name}Decoder on ${table.element.name} {\n'
        '  static ${table.element.name} fromMap(Map<String, dynamic> map) {\n'
        '    return ${table.element.name}(${params.join(', ')});\n'
        '  }\n'
        '}';
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
    if (param.isOptional || param.type.nullabilitySuffix == NullabilitySuffix.question) {
      str += 'Opt';
    } else if (param.type.isDartCoreList) {
      str += 'Opt';
      defVal = 'const []';
    } else if (param.type.isDartCoreMap) {
      str += 'Opt';
      defVal = 'const {}';
    }

    var key = column is FieldColumnBuilder ? column.columnName : c.paramName;
    str += "('$key')";

    if (defVal != null) {
      str += ' ?? $defVal';
    }
    return str;
  }
}
