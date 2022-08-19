import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:source_gen/source_gen.dart';

import '../../internals.dart';
import '../core/case_style.dart';
import 'column/column_builder.dart';
import 'column/field_column_builder.dart';
import 'table_builder.dart';
import 'utils.dart';

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
        return c.linkBuilder.views.firstWhere((v) => v.name == viewAs!.toLowerCase());
      } else {
        return c.linkBuilder.views.firstWhere((v) => v.name.isEmpty);
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
  DartObject? annotation;

  ViewBuilder(this.table, this.annotation);

  String get name => annotation?.getField('name')!.toStringValue()!.toLowerCase() ?? '';
  String get className => CaseStyle.pascalCase
      .transform(name.isNotEmpty ? '${name}_${table.element.name}_view' : '${table.element.name}_view');

  String get entityName => name.isEmpty ? table.element.name : className;

  String get viewName => CaseStyle.pascalCase.transform(name.isNotEmpty ? '${name}_view' : 'view');

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
        String? transformerCode;
        if (!transformer.isNull) {
          var node = table.element.getNode();
          if (node is ClassDeclaration) {
            var tnode = node.metadata.firstWhere((a) => a.name.name == (Model).toString());
            var vnode =
                tnode.arguments!.arguments.whereType<NamedExpression>().firstWhere((p) => p.name.label.name == 'views');
            if (vnode.expression is ListLiteral) {
              var list = vnode.expression as ListLiteral;
              var fields = list.elements
                  .whereType<MethodInvocation>()
                  .firstWhere((node) =>
                      node.methodName.name == 'View' &&
                      (node.argumentList.arguments.first as StringLiteral).stringValue?.toLowerCase() == name)
                  .argumentList
                  .arguments[1];
              if (fields is ListLiteral) {
                var field = fields.elements
                    .whereType<MethodInvocation>()
                    .firstWhere((e) => (e.argumentList.arguments.first as StringLiteral).stringValue == fieldName);
                Expression? exp;
                if (field.methodName.name == 'transform') {
                  exp = field.argumentList.arguments[1];
                } else if (field.methodName.name == 'Field') {
                  exp = field.argumentList.arguments
                      .whereType<NamedExpression>()
                      .firstWhere((a) => a.name.label.name == 'transformer')
                      .expression;
                }
                transformerCode = exp?.toSource();
              }
            }
          }
        }

        columns.add(ViewColumn(column, viewAs: viewAs, transformer: transformerCode));
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

  String? get targetAnnotation {
    if (annotation != null && !annotation!.getField('annotation')!.isNull) {
      return '@' + annotation!.getField('annotation')!.toSource();
    }
    return null;
  }
}

extension ObjectSource on DartObject {
  String toSource() {
    var reader = ConstantReader(this);

    if (reader.isLiteral) {
      if (reader.isString) {
        return "'${reader.literalValue}'";
      }
      return reader.literalValue!.toString();
    }

    var rev = reader.revive();

    var str = '';
    if (rev.source.fragment.isNotEmpty) {
      str = rev.source.fragment;

      if (rev.accessor.isNotEmpty) {
        str += '.${rev.accessor}';
      }
      str += '(';
      var isFirst = true;

      for (var p in rev.positionalArguments) {
        if (!isFirst) {
          str += ', ';
        }
        isFirst = false;
        str += p.toSource();
      }

      for (var p in rev.namedArguments.entries) {
        if (!isFirst) {
          str += ', ';
        }
        isFirst = false;
        str += '${p.key}: ${p.value.toSource()}';
      }

      str += ')';
    } else {
      str = rev.accessor;
    }
    return str;
  }
}
