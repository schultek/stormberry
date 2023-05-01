import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

import '../../core/case_style.dart';
import '../schema.dart';
import '../utils.dart';
import 'column/column_element.dart';
import 'column/field_column_element.dart';
import 'column/foreign_column_element.dart';
import 'column/join_column_element.dart';
import 'column/reference_column_element.dart';
import 'index_element.dart';
import 'join_table_element.dart';
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
  ConstantReader? meta;

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
      var name = ViewElement.nameOf(o);
      views[name] = ViewElement(this, name);
    }

    if (views.isEmpty) {
      views[ViewElement.defaultName] = ViewElement(this);
    }

    indexes = annotation.read('indexes').listValue.map((o) {
      return IndexElement(this, o);
    }).toList();

    if (!annotation.read('meta').isNull) {
      meta = annotation.read('meta');
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

          JoinColumnElement otherColumn;
          if (param != otherParam) {
            otherColumn = JoinColumnElement(otherParam!, this, joinBuilder, otherBuilder, state);
            otherColumn.referencedColumn = selfColumn;
            otherBuilder.columns.add(otherColumn);
          } else {
            otherColumn = selfColumn;
          }

          selfColumn.referencedColumn = otherColumn;
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

          if (param == otherParam) {
            otherColumn = selfColumn;
          } else {
            if (selfHasKey &&
                !otherIsList &&
                (selfColumn is! ForeignColumnElement || this != otherBuilder)) {
              otherColumn = ForeignColumnElement(otherParam, this, otherBuilder, state);
            } else {
              otherColumn = ReferenceColumnElement(otherParam, this, otherBuilder, state);
            }
            otherBuilder.columns.add(otherColumn);
            otherColumn.referencedColumn = selfColumn;
          }

          selfColumn.referencedColumn = otherColumn;
        }
      }
    }

    for (var c in columns) {
      for (var m in c.modifiers) {
        var viewName = ViewElement.nameOf(m.read('name').objectValue);

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
    var binding = param.binding;

    if (binding != null) {
      var bindingParam = allFields.where((f) => f.name == binding).firstOrNull;

      if (bindingParam == null) {
        throw 'A @BindTo() annotation was used with an incorrect target field. The following field '
            'was annotated:\n'
            '  - "${param.getDisplayString(withNullability: true)}" in class "${param.enclosingElement.getDisplayString(withNullability: true)}"\n'
            'The binding specified a target field of:\n'
            '  - "$binding"\n'
            'which does not exist in class "${element.getDisplayString(withNullability: false)}.';
      }

      var bindingParamBinding = bindingParam.binding;

      if (bindingParamBinding == null) {
        throw 'A @BindTo() annotation was only used on one field of a relation. The following field '
            'had no binding:\n'
            '  - "${bindingParam.getDisplayString(withNullability: true)}" in class "${bindingParam.enclosingElement.getDisplayString(withNullability: true)}"\n'
            'while the following field had a binding referring to the first field:\n'
            '  - "${param.getDisplayString(withNullability: true)}" in class ${param.enclosingElement.getDisplayString(withNullability: true)}"\n\n'
            'Make sure that both parameters specify the @BindTo() annotation referring to each other, or neither.';
      } else if (bindingParamBinding != param.name) {
        throw 'A @BindTo() annotation contained an incorrect target field. The following field '
            'had a binding:\n'
            '  - "${param.getDisplayString(withNullability: true)}" in class "${param.enclosingElement.getDisplayString(withNullability: true)}"\n'
            'which referred to the second field:\n'
            '  - "${bindingParam.getDisplayString(withNullability: true)}" in class ${bindingParam.enclosingElement.getDisplayString(withNullability: true)}"\n'
            'which referred to some other field "$bindingParamBinding".\n\n'
            'Make sure that both fields specify the @BindTo() annotation referring to each other, or neither.';
      }

      var type = bindingParam.type.isDartCoreList
          ? (bindingParam.type as InterfaceType).typeArguments[0]
          : bindingParam.type;

      if (type.element != param.enclosingElement) {
        throw 'A @BindTo() annotation was used incorrectly on a type. The following field '
            'had a binding:\n'
            '  - "${param.getDisplayString(withNullability: true)}" in class "${param.enclosingElement.getDisplayString(withNullability: true)}"\n'
            'which referred to the second field:\n'
            '  - "${bindingParam.getDisplayString(withNullability: true)}" in class ${bindingParam.enclosingElement.getDisplayString(withNullability: true)}"\n'
            'which has an incorrect type "${type.element?.getDisplayString(withNullability: false)}".\n\n'
            'Make sure that the type of the second field is set to the class of the first field.';
      }

      return bindingParam;
    }

    if (allFields.contains(param)) {
      // Select no default matching param for self relations.
      return null;
    }

    return allFields.where((p) {
      var type = p.type.isDartCoreList ? (p.type as InterfaceType).typeArguments[0] : p.type;
      if (type.element != param.enclosingElement) return false;

      var binding = p.binding;
      if (binding == param.name) {
        throw 'A @BindTo() annotation was only used on one field of a relation. The following field'
            'had no binding:\n'
            '  - "${param.getDisplayString(withNullability: true)}" in class "${param.enclosingElement.getDisplayString(withNullability: true)}"\n'
            'while the following field had a binding referring to the first field:\n'
            '  - "${p.getDisplayString(withNullability: true)}" in class ${p.enclosingElement.getDisplayString(withNullability: true)}"\n\n'
            'Make sure that both fields specify the @BindTo() annotation referring to each other, or neither.';
      }
      if (binding != null) return false;
      return true;
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

  ConstantReader? metaFor(String name) {
    if (meta == null) {
      return null;
    }
    var views = meta!.read('views');
    if (!views.isNull) {
      var view =
          views.mapValue.entries.where((e) => name == e.key?.toSymbolValue()).firstOrNull?.value;
      if (view != null && !view.isNull) {
        return ConstantReader(view);
      }
    }
    return meta!.read('view');
  }

  void analyzeViews() {
    for (var view in views.values) {
      view.analyze();
    }
  }
}

extension FieldBinding on FieldElement {
  String? get binding {
    return bindToChecker.firstAnnotationOf(getter ?? this)?.getField('name')?.toSymbolValue();
  }
}
