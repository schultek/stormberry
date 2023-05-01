import 'package:analyzer/dart/constant/value.dart';
import 'package:collection/collection.dart';

import '../../core/annotations.dart';
import '../../core/case_style.dart';
import '../utils.dart';
import 'column/column_element.dart';
import 'column/view_column_element.dart';
import 'table_element.dart';

class ViewElement {
  final TableElement table;
  final String name;

  ViewElement(this.table, [this.name = defaultName]);

  static String nameOf(DartObject object) {
    var name = object.toSymbolValue()!;
    if (Symbol(name) == Model.defaultView) {
      name = defaultName;
    }
    return name;
  }

  static const String defaultName = '';

  bool get isDefaultView => name == defaultName;

  String get className => CaseStyle.pascalCase
      .transform('${!isDefaultView ? '${name}_' : ''}${table.element.name}_view');

  String get viewTableName =>
      CaseStyle.snakeCase.transform('${!isDefaultView ? '${name}_' : ''}${table.tableName}_view');

  String get queryName =>
      CaseStyle.pascalCase.transform(isDefaultView ? table.element.name : '${name}_view');

  late List<ViewColumnElement> columns = () {
    var columns = <ViewColumnElement>[];

    for (var column in table.columns) {
      if (column.parameter == null) {
        continue;
      }

      var modifiers = column.modifiers
          .where((m) => nameOf(m.read('name').objectValue).toLowerCase() == name.toLowerCase());
      if (modifiers.isNotEmpty) {
        var isHidden = modifiers.any((m) => m.instanceOf(hiddenInChecker));
        if (isHidden) {
          continue;
        }

        var viewModifier = modifiers.where((m) => m.instanceOf(viewedInChecker)).firstOrNull;
        var viewAs = viewModifier != null ? nameOf(viewModifier.read('as').objectValue) : null;

        if (viewAs == null && column is LinkedColumnElement) {
          if (!column.linkedTable.views.values.any((v) => v.isDefaultView)) {
            column.linkedTable.views[defaultName] = ViewElement(column.linkedTable);
          }
        }

        var transformer =
            modifiers.where((m) => m.instanceOf(transformedInChecker)).firstOrNull?.read('by');

        String? transformerCode;
        if (transformer != null && !transformer.isNull) {
          transformerCode = transformer.toSource();
        }

        columns.add(ViewColumnElement(column, viewAs: viewAs, transformer: transformerCode));
      } else {
        if (column is LinkedColumnElement) {
          if (!column.linkedTable.views.values.any((v) => v.isDefaultView)) {
            column.linkedTable.views[defaultName] = ViewElement(column.linkedTable);
          }
        }

        columns.add(ViewColumnElement(column));
      }
    }

    return columns;
  }();

  void analyze() {
    for (var c in columns) {
      c.analyzeCircularColumns();
    }
  }
}
