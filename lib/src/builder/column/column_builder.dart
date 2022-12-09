import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

import '../stormberry_builder.dart';
import '../table_builder.dart';
import '../utils.dart';

abstract class NamedColumnBuilder implements ParameterColumnBuilder {
  String get columnName;
  bool get isNullable;
  String get sqlType;
}

abstract class RelationalColumnBuilder implements ColumnBuilder {
  @override
  void checkConverter() {
    if (converter != null) {
      throw 'Relational field was annotated with @UseConverter(...), which is not supported.\n'
          '  - ${parameter!.getDisplayString(withNullability: true)}';
    }
  }

  @override
  void checkModifiers() {
    var groupedModifiers = modifiers.groupListsBy((m) => Object.hash(m.read('name').stringValue, m.objectValue.type));
    if (groupedModifiers.values.any((l) => l.length > 1)) {
      var duplicated = groupedModifiers.values.where((l) => l.length > 1).first;
      throw 'Column field was annotated with duplicate view modifiers, which is not supported.\n'
          'On field "${parameter!.getDisplayString(withNullability: false)}":\n'
          '${duplicated.map((d) => '  - @${d.toSource()}').join('\n')}';
    }
  }
}

abstract class LinkedColumnBuilder implements ColumnBuilder {
  TableBuilder get linkBuilder;
}

abstract class ReferencingColumnBuilder implements LinkedColumnBuilder, ParameterColumnBuilder {
  ReferencingColumnBuilder get referencedColumn;
  set referencedColumn(ReferencingColumnBuilder c);
}

abstract class ParameterColumnBuilder implements ColumnBuilder {
  String get paramName;
}

abstract class ColumnBuilder {
  BuilderState state;
  TableBuilder parentBuilder;

  ColumnBuilder(this.parentBuilder, this.state) {
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

String getSqlType(DartType type) {
  if (type.isDartCoreString) {
    return 'text';
  } else if (type.isDartCoreInt) {
    return 'int8';
  } else if (type.isDartCoreNum || type.isDartCoreDouble) {
    return 'float8';
  } else if (type.isDartCoreBool) {
    return 'bool';
  } else if (type.element2?.name == 'DateTime') {
    return 'timestamp';
  } else if (type.element2?.name == 'PgPoint') {
    return 'point';
  } else {
    return 'jsonb';
  }
}
