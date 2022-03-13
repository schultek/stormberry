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
import 'view_builder.dart';

class TableBuilder {
  ClassElement element;
  ConstantReader annotation;
  BuilderState state;

  late String tableName;
  late FieldElement? primaryKeyParameter;
  late List<ViewBuilder> views;
  late List<IndexBuilder> indexes;

  TableBuilder(this.element, this.annotation, this.state) {
    tableName = _getTableName();

    primaryKeyParameter = element.fields
        .where((p) => primaryKeyChecker.hasAnnotationOf(p) || primaryKeyChecker.hasAnnotationOf(p.getter ?? p))
        .firstOrNull;

    views = annotation.read('views').listValue.map((o) {
      return ViewBuilder(this, o);
    }).toList();

    indexes = annotation.read('indexes').listValue.map((o) {
      return IndexBuilder(this, o);
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

  void prepareColumns() {
    for (var param in element.fields) {
      if (columns.any((c) => c.parameter?.id == param.id)) {
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
    name = state.options.columnCaseStyle.transform('$name-${primaryKeyColumn!.columnName}');
    if (plural) {
      name += name.endsWith('s') ? 'es' : 's';
    }
    return name;
  }
}
