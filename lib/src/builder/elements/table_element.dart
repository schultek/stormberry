import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

import '../../core/case_style.dart';
import '../schema.dart';
import 'column/column_element.dart';
import 'column/field_column_element.dart';
import 'column/foreign_column_element.dart';
import 'column/join_column_element.dart';
import 'column/reference_column_element.dart';
import 'index_element.dart';
import 'join_table_element.dart';
import '../utils.dart';
import 'view_element.dart';

extension EnumType on DartType {
  bool get isEnum => TypeChecker.fromRuntime(Enum).isAssignableFromType(this);
}

class TableElement {
  final ClassElement element;
  final ConstantReader annotation;
  final BuilderState state;

  late String repoName;
  late String tableName;
  late FieldElement? primaryKeyParameter;
  late Map<String, ViewElement> views;
  late List<IndexElement> indexes;
  String? annotateWith;

  TableElement(this.element, this.annotation, this.state) {
    tableName = _getTableName();
    repoName = _getRepoName();

    primaryKeyParameter = element.fields
        .where((p) =>
            primaryKeyChecker.hasAnnotationOf(p) ||
            primaryKeyChecker.hasAnnotationOf(p.getter ?? p))
        .firstOrNull;

    views = {};

    for (var o in annotation.read('views').listValue) {
      var name = o.toSymbolValue()!;
      views[name] = ViewElement(this, name);
    }

    if (views.isEmpty) {
      views[''] = ViewElement(this, '');
    }

    indexes = annotation.read('indexes').listValue.map((o) {
      return IndexElement(this, o);
    }).toList();

    if (!annotation.read('annotateWith').isNull) {
      annotateWith = '@${annotation.read('annotateWith').toSource()}';
    }
  }

  String _getTableName({bool singular = false}) {
    if (!annotation.read('tableName').isNull) {
      return annotation.read('tableName').stringValue;
    }

    return state.options.tableCaseStyle.transform(_getRepoName(singular: singular));
  }

  String _getRepoName({bool singular = false}) {
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
    return CaseStyle.camelCase.transform(name);
  }

  List<ColumnElement> columns = [];

  FieldColumnElement? get primaryKeyColumn => primaryKeyParameter != null
      ? columns
          .whereType<FieldColumnElement>()
          .where((c) => c.parameter == primaryKeyParameter)
          .firstOrNull
      : null;

  late List<FieldElement> allFields = element.fields
      .cast<FieldElement>()
      .followedBy(element.allSupertypes.expand((t) => t.isDartCoreObject ? [] : t.element.fields))
      .toList();

  void prepareColumns() {
    for (var param in allFields) {
      if (columns.any((c) => c.parameter == param)) {
        continue;
      }

      var isList = param.type.isDartCoreList;
      var dataType = isList ? (param.type as InterfaceType).typeArguments[0] : param.type;
      if (!state.schema.tables.containsKey(dataType.element)) {
        columns.add(FieldColumnElement(param, this, state));
      } else {
        var otherBuilder = state.schema.tables[dataType.element]!;

        var selfHasKey = primaryKeyParameter != null;
        var otherHasKey = otherBuilder.primaryKeyParameter != null;

        var otherParam = otherBuilder.findMatchingParam(param);
        var selfIsList = param.type.isDartCoreList;
        var otherIsList =
            otherParam != null ? otherParam.type.isDartCoreList : otherHasKey && !selfIsList;

        if (!selfHasKey && !otherHasKey) {
          throw 'Model ${otherBuilder.element.name} cannot have a relation to model ${element.name} because neither model'
              'has a primary key. Define a primary key for at least one of the models in a relation.';
        }

        if (selfHasKey && !otherHasKey && otherIsList) {
          throw 'Model ${otherBuilder.element.name} cannot have a many-to-'
              '${selfIsList ? 'many' : 'one'} relation to model ${element.name} without specifying a primary key.\n'
              'Either define a primary key for ${otherBuilder.element.name} or change the relation by changing field '
              '"${otherParam!.getDisplayString(withNullability: true)}" to have a non-list type.';
        }

        if (selfHasKey && otherHasKey && !selfIsList && !otherIsList) {
          var eitherNullable = param.type.nullabilitySuffix != NullabilitySuffix.none ||
              otherParam!.type.nullabilitySuffix != NullabilitySuffix.none;
          if (!eitherNullable) {
            throw 'Model ${otherBuilder.element.name} cannot have a one-to-one relation to model ${element.name} with '
                'both sides being non-nullable. At least one side has to be nullable, to insert one model before the other.\n'
                'However both "${element.name}.${param.name}" and "${otherBuilder.element.name}.${otherParam.name}" '
                'are non-nullable.\n'
                'Either make at least one parameter nullable or change the relation by changing one parameter to have a list type.';
          }
        }

        if (selfHasKey && otherHasKey && selfIsList && otherIsList) {
          // Many to Many

          var joinBuilder = JoinTableElement(this, otherBuilder, state);
          if (!state.schema.joinTables.containsKey(joinBuilder.tableName)) {
            state.asset.joinTables[joinBuilder.tableName] = joinBuilder;
          }

          var selfColumn = JoinColumnElement(param, otherBuilder, joinBuilder, this, state);

          if (otherParam != null) {
            var otherColumn = JoinColumnElement(otherParam, this, joinBuilder, otherBuilder, state);

            otherColumn.referencedColumn = selfColumn;
            selfColumn.referencedColumn = otherColumn;

            otherBuilder.columns.add(otherColumn);
          }

          columns.add(selfColumn);
        } else {
          ReferencingColumnElement selfColumn;

          if (otherHasKey && !selfIsList) {
            selfColumn = ForeignColumnElement(param, otherBuilder, this, state);
          } else {
            selfColumn = ReferenceColumnElement(param, otherBuilder, this, state);
          }

          columns.add(selfColumn);

          ReferencingColumnElement otherColumn;

          if (selfHasKey && !otherIsList) {
            otherColumn = ForeignColumnElement(otherParam, this, otherBuilder, state);
            otherBuilder.columns.add(otherColumn);
          } else {
            otherColumn = ReferenceColumnElement(otherParam, this, otherBuilder, state);
            otherBuilder.columns.add(otherColumn);
          }

          selfColumn.referencedColumn = otherColumn;
          otherColumn.referencedColumn = selfColumn;
        }
      }
    }

    for (var c in columns) {
      for (var m in c.modifiers) {
        var viewName = m.read('name').objectValue.toSymbolValue()!;

        if (!views.containsKey(viewName)) {
          throw 'Model ${element.name} uses a view modifier on an unknown view \'#$viewName\'.\n'
              'Make sure to add this view to @Model(views: [...]).';
        }
      }
    }
  }

  void sortColumns() {
    columns.sortBy((column) {
      var key = '';

      if (column.parameter != null) {
        // first: columns related to a model field, in declared order
        key += '0_';
        key += allFields.indexOf(column.parameter!).toString();
      } else if (column is ParameterColumnElement) {
        // then: foreign or reference columns with no field, in alphabetical order
        key += '1_';
        key += column.paramName;
      } else {
        // then: rest
        key += '2';
      }

      return key;
    });
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
