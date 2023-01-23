import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

import '../../schema.dart';
import '../table_element.dart';
import '../../utils.dart';

abstract class NamedColumnElement implements ParameterColumnElement {
  String get columnName;
  bool get isNullable;
  String get sqlType;
}

abstract class RelationalColumnElement implements ColumnElement {
  @override
  void checkConverter() {
    if (converter != null) {
      throw 'Relational field was annotated with @UseConverter(...), which is not supported.\n'
          '  - ${parameter!.getDisplayString(withNullability: true)}';
    }
  }

  @override
  void checkModifiers() {
    var groupedModifiers = modifiers.groupListsBy(
        (m) => Object.hash(m.read('name').objectValue.toSymbolValue(), m.objectValue.type));
    if (groupedModifiers.values.any((l) => l.length > 1)) {
      var duplicated = groupedModifiers.values.where((l) => l.length > 1).first;
      throw 'Column field was annotated with duplicate view modifiers, which is not supported.\n'
          'On field "${parameter!.getDisplayString(withNullability: false)}":\n'
          '${duplicated.map((d) => '  - @${d.toSource()}').join('\n')}';
    }
  }
}

abstract class LinkedColumnElement implements ColumnElement {
  TableElement get linkedTable;
}

abstract class ReferencingColumnElement implements LinkedColumnElement, ParameterColumnElement {
  ReferencingColumnElement get referencedColumn;
  set referencedColumn(ReferencingColumnElement c);
}

abstract class ParameterColumnElement implements ColumnElement {
  String get paramName;
}

abstract class ColumnElement {
  final BuilderState state;
  final TableElement parentTable;

  ColumnElement(this.parentTable, this.state) {
    checkConverter();
  }

  FieldElement? get parameter;

  bool get isList;

  late DartObject? converter = () {
    if (parameter == null) return null;

    var converters = useConverterChecker //
        .annotationsOf(parameter!)
        .followedBy(useConverterChecker.annotationsOf(parameter!.getter!));
    if (converters.length > 1) {
      throw 'Field annotated with multiple converters. You can only use one.';
    }

    return converters.firstOrNull?.getField('converter');
  }();

  void checkConverter();

  late List<ConstantReader> modifiers = () {
    if (parameter == null || parameter!.getter == null) return <ConstantReader>[];

    return [
      ...changedInChecker.annotationsOf(parameter!),
      ...changedInChecker.annotationsOf(parameter!.getter!),
    ].map((m) => ConstantReader(m)).toList();
  }();

  void checkModifiers();

  Map<String, dynamic> toMap();
}

String? getSqlType(DartType type) {
  if (type.isDartCoreString) {
    return 'text';
  } else if (type.isDartCoreInt) {
    return 'int8';
  } else if (type.isDartCoreNum || type.isDartCoreDouble) {
    return 'float8';
  } else if (type.isDartCoreBool) {
    return 'bool';
  } else if (type.element?.name == 'DateTime') {
    return 'timestamp';
  } else if (type.element?.name == 'PgPoint') {
    return 'point';
  } else {
    return null;
  }
}
