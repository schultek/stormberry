import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import '../core/case_style.dart';
import '../helpers/utils.dart';
import 'action/action_builder.dart';
import 'action/insert_action_builder.dart';
import 'action/update_action_builder.dart';
import 'column/column_builder.dart';
import 'column/field_column_builder.dart';
import 'column/foreign_column_builder.dart';
import 'column/join_column_builder.dart';
import 'column/reference_column_builder.dart';
import 'join_table_builder.dart';
import 'query_builder.dart';
import 'stormberry_builder.dart';
import 'view_builder.dart';

class TableBuilder {
  ClassElement element;
  ConstantReader annotation;
  BuilderState state;

  late ConstructorElement constructor;
  late String tableName;
  late ParameterElement? primaryKeyParameter;
  late List<ViewBuilder> views;
  late List<ActionBuilder> actions;
  late List<QueryBuilder> queries;

  TableBuilder(this.element, this.annotation, this.state) {
    // TODO add constructor annotation
    constructor = element.constructors.firstWhere((c) => !c.isPrivate);

    tableName = _getTableName();

    primaryKeyParameter = constructor.parameters
        .whereType<FieldFormalParameterElement>()
        .where((p) => primaryKeyChecker.hasAnnotationOf(p.field!))
        .firstOrNull;

    views = annotation.read('views').listValue.map((o) {
      return ViewBuilder(this, o);
    }).toList();
    actions = annotation.read('actions').listValue.map((o) {
      return ActionBuilder.get(this, o);
    }).toList();
    queries = annotation.read('queries').listValue.map((o) {
      return QueryBuilder(this, o);
    }).toList();
  }

  String _getTableName({bool singular = false}) {
    var name = element.name;
    if (!singular) {
      if (element.name.endsWith('s')) {
        name += 'es';
      } else if (element.name.endsWith('y')) {
        name = '${name.substring(0, name.length - 1)}ies';
      } else {
        name += 's';
      }
    }
    return state.options.tableCaseStyle.transform(name);
  }

  List<ColumnBuilder> columns = [];

  FieldColumnBuilder? get primaryKeyColumn => primaryKeyParameter != null
      ? columns.whereType<FieldColumnBuilder>().where((c) => c.parameter == primaryKeyParameter).firstOrNull
      : null;

  bool get hasDefaultInsertAction => actions.any((a) => a is InsertActionBuilder);
  bool get hasDefaultUpdateAction => actions.any((a) => a is UpdateActionBuilder);

  bool hasQueryForView(ViewBuilder? view) {
    return queries.any((q) => q.isDefaultForView(view));
  }

  bool get hasDefaultQuery => queries.any((q) => q.className == 'SingleQuery' || q.className == 'MultiQuery');

  void prepareColumns() {
    for (var param in constructor.parameters) {
      if (columns.any((c) => c.parameter == param)) {
        continue;
      }

      var isList = param.type.isDartCoreList;
      var dataType = isList ? (param.type as InterfaceType).typeArguments[0] : param.type;

      if (!state.builders.containsKey(dataType.element)) {
        columns.add(FieldColumnBuilder(param, this, state));
      } else {
        var otherBuilder = state.builders[dataType.element]!;

        var selfHasKey = primaryKeyParameter != null;
        var otherHasKey = otherBuilder.primaryKeyParameter != null;

        var otherParam = otherBuilder.findMatchingParam(param);
        var isBothList = param.type.isDartCoreList && (otherParam?.type.isDartCoreList ?? false);

        if (!selfHasKey && !otherHasKey) {
          // Json column
          columns.add(FieldColumnBuilder(param, this, state));
        } else if (selfHasKey && otherHasKey && isBothList) {
          // Many to Many

          var joinBuilder = JoinTableBuilder(this, otherBuilder, state);
          if (!state.joinBuilders.containsKey(joinBuilder.tableName)) {
            state.joinBuilders[joinBuilder.tableName] = joinBuilder;
          }

          var selfColumn = JoinColumnBuilder(param, otherBuilder, joinBuilder, this, state);

          if (otherParam != null) {
            var otherColumn = JoinColumnBuilder(otherParam, this, joinBuilder, otherBuilder, state);

            otherColumn.referencedColumn = selfColumn;
            selfColumn.referencedColumn = otherColumn;

            otherBuilder.columns.add(otherColumn);
          }

          columns.add(selfColumn);
        } else {
          ReferencingColumnBuilder selfColumn;
          if (otherHasKey && !param.type.isDartCoreList) {
            selfColumn = ForeignColumnBuilder(param, otherBuilder, this, state);
          } else {
            selfColumn = ReferenceColumnBuilder(param, otherBuilder, this, state);
          }

          columns.add(selfColumn);

          ReferencingColumnBuilder otherColumn;

          if (selfHasKey && (otherParam == null || !otherParam.type.isDartCoreList)) {
            otherColumn = ForeignColumnBuilder(otherParam, this, otherBuilder, state);
            var insertIndex = otherBuilder.columns.lastIndexWhere((c) => c is ForeignColumnBuilder) + 1;
            otherBuilder.columns.insert(insertIndex, otherColumn);
          } else {
            otherColumn = ReferenceColumnBuilder(otherParam, this, otherBuilder, state);
            otherBuilder.columns.add(otherColumn);
          }

          selfColumn.referencedColumn = otherColumn;
          otherColumn.referencedColumn = selfColumn;
        }
      }
    }
  }

  ParameterElement? findMatchingParam(ParameterElement param) {
    // TODO add binding
    return constructor.parameters.where((p) {
      var pType = p.type.isDartCoreList ? (p.type as InterfaceType).typeArguments[0] : p.type;
      return pType.element == param.enclosingElement?.enclosingElement;
    }).firstOrNull;
  }

  String? getForeignKeyName({bool plural = false, String? base}) {
    if (primaryKeyColumn == null) return null;
    var name = base ?? _getTableName(singular: true);
    if (base != null && plural && name.endsWith('s')) {
      name = name.substring(0, base.length - (base.endsWith('es') ? 2 : 1));
    }
    name = state.options.columnCaseStyle.transform('$name-${primaryKeyColumn!.columnName}');
    if (plural) {
      name += name.endsWith('s') ? 'es' : 's';
    }
    return name;
  }

  String generateTableClass() {
    var methods = <String>[];

    for (var query in queries) {
      methods.add(query.buildQueryMethod());
    }

    for (var action in actions) {
      methods.add(action.generateActionMethod());
    }

    return 'class ${element.name}Table extends BaseTable {\n'
        '  ${element.name}Table._(Database db) : super(db);\n'
        '\n'
        '${methods.join('\n\n').indent()}\n'
        '}';
  }

  String generateViews() {
    var viewClasses = <String>[];

    for (var view in [...views]) {
      viewClasses.add(view.generateClass());
    }

    return viewClasses.join('\n\n');
  }

  String generateActions() {
    var actionClasses = <String>[];

    for (var action in [...actions]) {
      var actionCode = action.generateActionClass();
      if (actionCode != null) {
        actionClasses.add(actionCode);
      }
    }

    return actionClasses.join('\n\n');
  }
}
