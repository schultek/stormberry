import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';

import '../core/annotations.dart';
import '../core/case_style.dart';
import 'column_builder.dart';
import 'table_builder.dart';

class ViewColumn {
  Field? field;
  ColumnBuilder column;

  ViewColumn(this.column, this.field);

  ViewBuilder? get view {
    if (field?.viewAs != null) {
      return column.linkBuilder!.views
          .firstWhere((v) => v.name == field!.viewAs!.toLowerCase());
    }
  }

  String get paramName {
    return column.parameter!.name;
  }

  String get dartType {
    if (field?.viewAs != null) {
      var isList = column.isList;
      var nullSuffix = column.parameter!.type.nullabilitySuffix;
      var typeSuffix = nullSuffix == NullabilitySuffix.question ? '?' : '';
      return isList
          ? 'List<${view!.className}>$typeSuffix'
          : '${view!.className}$typeSuffix';
    } else {
      return column.parameter!.type.getDisplayString(withNullability: true);
    }
  }

  String get queryClassName {
    if (view != null) {
      return '${view!.className}Query';
    } else {
      return '${column.dataType.getDisplayString(withNullability: false)}Query';
    }
  }
}

class ViewBuilder {
  TableBuilder table;
  DartObject annotation;

  ViewBuilder(this.table, this.annotation);

  String get name =>
      annotation.getField('name')!.toStringValue()!.toLowerCase();
  String get className =>
      CaseStyle.pascalCase.transform('${name}_${table.element.name}_view');

  List<ViewColumn>? _columns;
  List<ViewColumn> get columns => _columns ??= _getViewColumns();
  List<ViewColumn> _getViewColumns() {
    var viewFields = Map.fromEntries(annotation
        .getField('fields')!
        .toListValue()!
        .map((f) => MapEntry(f.getField('name')!.toStringValue()!, f)));

    var columns = <ViewColumn>[];

    for (var column in table.columns) {
      if (column.parameter == null) {
        continue;
      }
      if (viewFields.containsKey(column.parameter!.name)) {
        var fieldName = column.parameter!.name;
        var viewField = viewFields[fieldName]!;
        var mode = FieldMode.values[
            viewField.getField('mode')!.getField('index')!.toIntValue()!];

        if (mode == FieldMode.hidden) {
          continue;
        } else if (mode == FieldMode.view) {
          var asView = viewField.getField('viewAs')!.toStringValue()!;
          columns.add(ViewColumn(
            column,
            Field.view(fieldName, as: asView),
          ));
        } else if (mode == FieldMode.filtered) {
          var filterBy = viewField.getField('filteredBy')!.toStringValue()!;
          columns.add(ViewColumn(
            column,
            Field.filtered(fieldName, by: filterBy),
          ));
        }
      } else {
        columns.add(ViewColumn(column, null));
      }
    }

    return columns;
  }

  String generateClass() {
    table.state.decoders[className] = className;

    return ''
        'class $className {\n'
        '  $className(${columns.map((c) => 'this.${c.paramName}').join(', ')});\n'
        '  $className.fromMap(Map<String, dynamic> map)\n'
        '    : ${columns.map((c) => '${c.paramName} = ${_getInitializer(c)}').join(',\n      ')};\n'
        '  \n'
        '  ${columns.map((c) => '${c.dartType} ${c.paramName};').join('\n  ')}\n'
        '}';
  }

  String _getInitializer(ViewColumn c) {
    var param = c.column.parameter!;
    var str = 'map.get';
    String? defVal;
    if (param.type.isDartCoreList) {
      str += 'List';
    } else if (param.type.isDartCoreMap) {
      str += 'Map';
    }
    if (param.isOptional ||
        param.type.nullabilitySuffix == NullabilitySuffix.question) {
      str += 'Opt';
    } else if (param.type.isDartCoreList) {
      str += 'Opt';
      defVal = 'const []';
    } else if (param.type.isDartCoreMap) {
      str += 'Opt';
      defVal = 'const {}';
    }

    var key = c.column.isFieldColumn ? c.column.columnName : c.paramName;
    str += "('$key')";

    if (defVal != null) {
      str += ' ?? $defVal';
    }
    return str;
  }
}
