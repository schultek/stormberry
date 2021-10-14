import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';

import '../core/case_style.dart';
import '../helpers/utils.dart';
import 'table_builder.dart';
import 'view_builder.dart';

class QueryBuilder {
  TableBuilder table;
  DartObject? annotation;

  QueryBuilder(this.table, this.annotation);

  String? get viewName => annotation?.getField('viewName')?.toStringValue()?.toLowerCase();
  ViewBuilder? get view => table.views.where((v) => v.name == viewName).firstOrNull;

  bool isDefaultForView(ViewBuilder? view) {
    return view == this.view && (className == 'SingleQuery' || className == 'MultiQuery');
  }

  String get className => annotation == null ? 'SingleQuery' : annotation!.type!.element!.name!;

  String get resultClassName {
    if (className == 'SingleQuery' || className == 'MultiQuery') {
      return view?.className ?? table.element.name;
    } else {
      return (annotation!.type!.element! as ClassElement)
          .supertype!
          .typeArguments[0]
          .getDisplayString(withNullability: true);
    }
  }

  String buildQueryMethod() {
    if (className == 'SingleQuery') {
      var methodName = viewName != null ? CaseStyle.camelCase.transform('query_${viewName}_view') : 'queryOne';
      var paramName = table.primaryKeyColumn!.paramName;
      return 'Future<$resultClassName?> $methodName(${table.primaryKeyColumn!.dartType} $paramName) async {\n'
          '  return queryOne($paramName, "${view!.viewTableName}", "${table.tableName}", "$paramName");\n'
          '}';
    } else if (className == 'MultiQuery') {
      var methodName = viewName != null ? CaseStyle.camelCase.transform('query_${viewName}_views') : 'queryAll';
      return 'Future<List<$resultClassName>> $methodName([QueryParams? params]) {\n'
          '  return queryMany(params ?? QueryParams(), "${view!.viewTableName}", "${table.tableName}");\n'
          '}';
    } else {
      var requestClassName = (annotation!.type!.element! as ClassElement)
          .supertype!
          .typeArguments[1]
          .getDisplayString(withNullability: true);
      return 'Future<$resultClassName> execute$className($requestClassName request) {\n'
          '  return query($className(), request);\n'
          '}';
    }
  }
}
