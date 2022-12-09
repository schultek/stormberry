import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

import '../core/annotations.dart';
import '../core/case_style.dart';
import 'column/column_builder.dart';
import 'column/field_column_builder.dart';
import 'table_builder.dart';
import 'utils.dart';

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

  ColumnBuilder column;

  ViewColumn(this.column, {this.viewAs, this.transformer});

  ViewBuilder? get view {
    var c = column;
    if (c is LinkedColumnBuilder) {
      if (viewAs != null) {
        return c.linkBuilder.views.values.firstWhere((v) => v.name.toLowerCase() == viewAs!.toLowerCase());
      } else {
        return c.linkBuilder.views.values.firstWhere((v) => v.isDefaultView);
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
    } else if (column is LinkedColumnBuilder) {
      return (column as LinkedColumnBuilder).linkBuilder.tableName;
    }
    return null;
  }

  bool get isNullable => column.parameter!.type.nullabilitySuffix == NullabilitySuffix.question;

  Map<String, dynamic> toMap() {
    return column.toMap()
      ..addAll({
        if (transformer != null) 'transformer': LiteralValue(transformer!),
        if (column is! FieldColumnBuilder) 'table_name': tableName,
      });
  }
}

class ViewBuilder {
  TableBuilder table;
  String name;

  ViewBuilder(this.table, this.name);

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

        if (viewAs == null && column is LinkedColumnBuilder) {
          if (!column.linkBuilder.views.values.any((v) => v.isDefaultView)) {
            column.linkBuilder.views[''] = ViewBuilder(column.linkBuilder, '');
          }
        }

        var transformer = modifiers.where((m) => m.instanceOf(transformedInChecker)).firstOrNull?.read('by');

        String? transformerCode;
        if (transformer != null && !transformer.isNull) {
          transformerCode = transformer.toSource();
        }

        columns.add(ViewColumn(column, viewAs: viewAs, transformer: transformerCode));
      } else {
        if (column is LinkedColumnBuilder) {
          if (!column.linkBuilder.views.values.any((v) => v.isDefaultView)) {
            column.linkBuilder.views[''] = ViewBuilder(column.linkBuilder, '');
          }
        }

        columns.add(ViewColumn(column));
      }
    }

    return columns;
  }();
}