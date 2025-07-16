import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:postgres/postgres.dart';
import 'package:source_gen/source_gen.dart';

import '../../schema.dart';
import '../../utils.dart';
import '../table_element.dart';

abstract mixin class NamedColumnElement implements ParameterColumnElement {
  String get columnName;
  bool get isNullable;
  String get sqlType;
  String get rawSqlType;
}

mixin RelationalColumnElement implements ColumnElement {
  @override
  void checkConverter() {
    if (converter != null) {
      throw 'Relational field was annotated with @UseConverter(...), which is not supported.\n'
          '  - ${parameter!.getDisplayString(withNullability: true)}';
    }
  }

  @override
  void checkModifiers() {
    var groupedModifiers = modifiers.groupListsBy((m) => Object.hash(
        m.read('name').objectValue.toSymbolValue(), m.objectValue.type));
    if (groupedModifiers.values.any((l) => l.length > 1)) {
      var duplicated = groupedModifiers.values.where((l) => l.length > 1).first;
      throw 'Column field was annotated with duplicate view modifiers, which is not supported.\n'
          'On field "${parameter!.getDisplayString(withNullability: false)}":\n'
          '${duplicated.map((d) => '  - @${d.toSource()}').join('\n')}';
    }
  }
}

abstract mixin class LinkedColumnElement implements ColumnElement {
  TableElement get linkedTable;
}

abstract mixin class ReferencingColumnElement
    implements LinkedColumnElement, ParameterColumnElement {
  ReferencingColumnElement get referencedColumn;
  set referencedColumn(ReferencingColumnElement c);
}

abstract mixin class ParameterColumnElement implements ColumnElement {
  String get paramName;
}

abstract class ColumnElement {
  final BuilderState state;
  final TableElement parentTable;

  ColumnElement(this.parentTable, this.state) {
    checkConverter();
    checkModifiers();
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
    final parameter = this.parameter;
    final parameterGetter = parameter?.getter;
    if (parameter == null || parameterGetter == null) return <ConstantReader>[];

    return [
      ...hiddenInChecker.annotationsOf(parameter),
      ...hiddenInChecker.annotationsOf(parameterGetter),
      ...viewedInChecker.annotationsOf(parameter),
      ...viewedInChecker.annotationsOf(parameterGetter),
      ...transformedInChecker.annotationsOf(parameter),
      ...transformedInChecker.annotationsOf(parameterGetter),
    ].map((m) => ConstantReader(m)).toList();
  }();

  void checkModifiers();
}

final _dateTimeChecker = TypeChecker.fromRuntime(DateTime);
final _pointChecker = TypeChecker.fromRuntime(Point);

String? getSqlType(DartType type) {
  if (type.isDartCoreString) {
    return 'text';
  } else if (type.isDartCoreInt) {
    return 'int8';
  } else if (type.isDartCoreNum || type.isDartCoreDouble) {
    return 'float8';
  } else if (type.isDartCoreBool) {
    return 'boolean';
  } else if (_dateTimeChecker.isExactlyType(type)) {
    return 'timestamp';
  } else if (_pointChecker.isExactlyType(type)) {
    return 'point';
  } else {
    return null;
  }
}
