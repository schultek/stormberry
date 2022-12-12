import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

import '../../core/annotations.dart';
import '../../core/case_style.dart';
import 'column/column_element.dart';
import 'column/field_column_element.dart';
import 'table_element.dart';
import '../utils.dart';

final hiddenInChecker = TypeChecker.fromRuntime(HiddenIn);
final viewedInChecker = TypeChecker.fromRuntime(ViewedIn);
final transformedInChecker = TypeChecker.fromRuntime(TransformedIn);

class LiteralValue {
  String value;
  LiteralValue(this.value);

  dynamic toJson() {
    return '__%$value%__';
  }

  static String fix(String json) {
    return json.replaceAll('"__%', '').replaceAll('%__"', '');
  }
}

class ViewColumn {
  String? viewAs;
  String? transformer;

  ColumnElement column;

  ViewColumn(this.column, {this.viewAs, this.transformer});

  ViewElement? get view {
    var c = column;
    if (c is LinkedColumnElement) {
      if (viewAs != null) {
        return c.linkedTable.views.values.firstWhere((v) => v.name.toLowerCase() == viewAs!.toLowerCase());
      } else {
        return c.linkedTable.views.values.firstWhere((v) => v.isDefaultView);
      }
    }
    return null;
  }

  String get paramName {
    return column.parameter!.name;
  }

  String get dartType {
    if (view != null) {
      var isList = column.isList;
      var nullSuffix = column.parameter!.type.nullabilitySuffix;
      var typeSuffix = nullSuffix == NullabilitySuffix.question ? '?' : '';
      return isList ? 'List<${view!.entityName}>$typeSuffix' : '${view!.entityName}$typeSuffix';
    } else {
      return column.parameter!.type.getDisplayString(withNullability: true);
    }
  }

  String? get tableName {
    if (view != null) {
      return view!.viewTableName;
    } else if (column is LinkedColumnElement) {
      return (column as LinkedColumnElement).linkedTable.tableName;
    }
    return null;
  }

  bool get isNullable => column.parameter!.type.nullabilitySuffix == NullabilitySuffix.question;

  Map<String, dynamic> toMap() {
    return column.toMap()
      ..addAll({
        if (transformer != null) 'transformer': LiteralValue(transformer!),
        if (column is! FieldColumnElement) 'table_name': tableName,
      });
  }
}

class ViewElement {
  TableElement table;
  String name;

  ViewElement(this.table, this.name);

  bool get isDefaultView => name.isEmpty;

  String get className => CaseStyle.pascalCase
      .transform('${!isDefaultView ? '${name}_' : ''}${table.element.name}_view');

  String get entityName => isDefaultView ? table.element.name : className;

  String get viewName => CaseStyle.pascalCase.transform(isDefaultView ? entityName : '${name}_view');

  String get viewTableName => CaseStyle.snakeCase.transform('${!isDefaultView ? '${name}_' : ''}${table.tableName}_view');

  late List<ViewColumn> columns = () {
    var columns = <ViewColumn>[];

    for (var column in table.columns) {
      if (column.parameter == null) {
        continue;
      }
      var modifiers = column.modifiers.where((m) => m.read('name').stringValue.toLowerCase() == name);
      if (modifiers.isNotEmpty) {
        var isHidden = modifiers.any((m) => m.instanceOf(hiddenInChecker));
        if (isHidden) {
          continue;
        }

        var viewAs = modifiers.where((m) => m.instanceOf(viewedInChecker)).firstOrNull?.read('as').stringValue;

        if (viewAs == null && column is LinkedColumnElement) {
          if (!column.linkedTable.views.values.any((v) => v.isDefaultView)) {
            column.linkedTable.views[''] = ViewElement(column.linkedTable, '');
          }
        }

        var transformer = modifiers.where((m) => m.instanceOf(transformedInChecker)).firstOrNull?.read('by');

        String? transformerCode;
        if (transformer != null && !transformer.isNull) {
          transformerCode = transformer.toSource();
        }

        columns.add(ViewColumn(column, viewAs: viewAs, transformer: transformerCode));
      } else {
        if (column is LinkedColumnElement) {
          if (!column.linkedTable.views.values.any((v) => v.isDefaultView)) {
            column.linkedTable.views[''] = ViewElement(column.linkedTable, '');
          }
        }

        columns.add(ViewColumn(column));
      }
    }

    return columns;
  }();
}