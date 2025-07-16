import 'package:analyzer/dart/element/nullability_suffix.dart';

import '../view_element.dart';
import 'column_element.dart';

class ViewColumnElement {
  String? viewAs;
  String? transformer;

  ColumnElement column;

  ViewColumnElement(this.column, {this.viewAs, this.transformer});

  void analyzeCircularColumns() {
    _visitLinkedView([]);
  }

  void _visitLinkedView(List<ViewColumnElement> parents) {
    if (parents.contains(this)) {
      var index = parents.indexOf(this);
      var loop = parents.sublist(index);
      throw 'View configuration contains a circular reference, causing an infinite loop when queried.\n'
          'The following circle was detected:\n\n'
          '${loop.map((c) => '${c.column.parentTable.element.name}${!c.view!.isDefaultView ? '[${c.view!.name}]' : ''} -(.${c.paramName})-> ').join()}${column.parentTable.element.name}\n\n'
          'To break this circle add a modifier annotation to one of the linking parameters, e.g.\n\n'
          'class ${column.parentTable.element.name} {\n'
          '  @HiddenIn${view!.isDefaultView ? '.defaultView()' : '(#${view!.name})'}\n'
          '  ${column.parameter?.getter?.toString() ?? column.parameter?.toString()}\n'
          '}';
    }

    if (view == null) return;
    for (var v in view!.columns) {
      v._visitLinkedView([...parents, this]);
    }
  }

  late ViewElement? view = () {
    var c = column;
    if (c is LinkedColumnElement) {
      if (viewAs != null) {
        return c.linkedTable.views.values
            .firstWhere((v) => v.name.toLowerCase() == viewAs!.toLowerCase());
      } else {
        return c.linkedTable.views.values.firstWhere((v) => v.isDefaultView);
      }
    }
    return null;
  }();

  late String paramName = column.parameter!.name;

  late String dartType = () {
    if (view != null) {
      var isList = column.isList;
      var nullSuffix = column.parameter!.type.nullabilitySuffix;
      var typeSuffix = nullSuffix == NullabilitySuffix.question ? '?' : '';
      return isList
          ? 'List<${view!.className}>$typeSuffix'
          : '${view!.className}$typeSuffix';
    } else {
      return column.parameter!.type.getDisplayString(withNullability: true);
    }
  }();

  late bool isNullable =
      column.parameter!.type.nullabilitySuffix == NullabilitySuffix.question;
}
