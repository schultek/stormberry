import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

import '../core/case_style.dart';
import 'column/column_builder.dart';
import 'column/field_column_builder.dart';
import 'column/foreign_column_builder.dart';
import 'column/join_column_builder.dart';
import 'column/reference_column_builder.dart';
import 'index_builder.dart';
import 'join_table_builder.dart';
import 'stormberry_builder.dart';
import 'utils.dart';
import 'view_builder.dart';

extension EnumType on DartType {
  bool get isEnum => TypeChecker.fromRuntime(Enum).isAssignableFromType(this);
}

class TableBuilder {
  ClassElement element;
  ConstantReader annotation;
  BuilderState state;

  late String className;
  late String tableName;
  late FieldElement? primaryKeyParameter;
  late Map<String, ViewBuilder> views;
  late List<IndexBuilder> indexes;
  String? annotateWith;

  TableBuilder(this.element, this.annotation, this.state) {
    tableName = _getTableName();
    className = _getClassName();

    primaryKeyParameter = element.fields
        .where((p) => primaryKeyChecker.hasAnnotationOf(p) || primaryKeyChecker.hasAnnotationOf(p.getter ?? p))
        .firstOrNull;

    views = {};

    indexes = annotation.read('indexes').listValue.map((o) {
      return IndexBuilder(this, o);
    }).toList();

    if (!annotation.read('annotateWith').isNull) {
      annotateWith = '@${annotation.read('annotateWith').toSource()}';
    }
  }

  String _getTableName({bool singular = false}) {
    if (!annotation.read('tableName').isNull) {
      return annotation.read('tableName').stringValue;
    }

    return _getClassName(singular: singular);
  }

  String _getClassName({bool singular = false}) {
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
    return state.schema.options.tableCaseStyle.transform(name);
  }

  List<ColumnBuilder> columns = [];

  FieldColumnBuilder? get primaryKeyColumn => primaryKeyParameter != null
      ? columns.whereType<FieldColumnBuilder>().where((c) => c.parameter == primaryKeyParameter).firstOrNull
      : null;

  void prepareColumns() {
    final allFields =
        element.fields.followedBy(element.allSupertypes.expand((t) => t.isDartCoreObject ? [] : t.element.fields));

    for (var param in allFields) {
      if (columns.any((c) => c.parameter == param)) {
        continue;
      }

      var isList = param.type.isDartCoreList;
      var dataType = isList ? (param.type as InterfaceType).typeArguments[0] : param.type;
      if (!state.schema.builders.containsKey(dataType.element)) {
        columns.add(FieldColumnBuilder(param, this, state));
      } else {
        var otherBuilder = state.schema.builders[dataType.element]!;

        var selfHasKey = primaryKeyParameter != null;
        var otherHasKey = otherBuilder.primaryKeyParameter != null;

        var otherParam = otherBuilder.findMatchingParam(param);
        var selfIsList = param.type.isDartCoreList;
        var otherIsList = otherParam != null ? otherParam.type.isDartCoreList : otherHasKey && !selfIsList;

        if (selfHasKey && !otherHasKey && otherIsList) {
          throw UnsupportedError('Model ${otherBuilder.element.name} cannot have a many to '
              '${selfIsList ? 'many' : 'one'} relation to model ${element.name} without specifying a primary key.\n'
              'Either define a primary key for ${otherBuilder.element.name} or change the relation by changing field '
              '"${otherParam!.getDisplayString(withNullability: true)}" to have a non-list type.');
        }

        if (!selfHasKey && !otherHasKey) {
          // Json column
          columns.add(FieldColumnBuilder(param, this, state));
        } else {
          if (selfHasKey && otherHasKey && selfIsList && otherIsList) {
            // Many to Many

            var joinBuilder = JoinTableBuilder(this, otherBuilder, state);
            if (!state.schema.joinBuilders.containsKey(joinBuilder.tableName)) {
              state.asset.joinBuilders[joinBuilder.tableName] = joinBuilder;
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

            if (otherHasKey && !selfIsList) {
              selfColumn = ForeignColumnBuilder(param, otherBuilder, this, state);
            } else {
              selfColumn = ReferenceColumnBuilder(param, otherBuilder, this, state);
            }

            columns.add(selfColumn);

            ReferencingColumnBuilder otherColumn;

            if (selfHasKey && !otherIsList) {
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

    for (var c in columns) {
      for (var m in c.modifiers) {
        var viewName = CaseStyle.camelCase.transform(m.read('name').stringValue);

        if (!views.containsKey(viewName)) {
          views[viewName] = ViewBuilder(this, viewName);
        }
      }
    }

    if (views.isEmpty) {
      views[''] = ViewBuilder(this, '');
    }
  }

  FieldElement? findMatchingParam(FieldElement param) {
    // TODO add binding
    return element.fields.where((p) {
      var pType = p.type.isDartCoreList ? (p.type as InterfaceType).typeArguments[0] : p.type;
      return pType.element == param.enclosingElement;
    }).firstOrNull;
  }

  String? getForeignKeyName({bool plural = false, String? base}) {
    if (primaryKeyColumn == null) return null;
    var name = base ?? _getTableName(singular: true);
    if (base != null && plural && name.endsWith('s')) {
      name = name.substring(0, base.length - (base.endsWith('es') ? 2 : 1));
    }
    name = state.schema.options.columnCaseStyle.transform('$name-${primaryKeyColumn!.columnName}');
    if (plural) {
      name += name.endsWith('s') ? 'es' : 's';
    }
    return name;
  }
}
