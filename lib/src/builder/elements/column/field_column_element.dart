import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import '../../../core/case_style.dart';
import '../../schema.dart';
import '../../utils.dart';
import '../table_element.dart';
import 'column_element.dart';

class FieldColumnElement extends ColumnElement with NamedColumnElement {
  @override
  final FieldElement parameter;

  late final bool isAutoIncrement;

  @override
  late final String? defaultValue;

  FieldColumnElement(this.parameter, TableElement parentTable, BuilderState state)
    : super(parentTable, state) {
    isAutoIncrement =
        (autoIncrementChecker.firstAnnotationOf(parameter) ??
            autoIncrementChecker.firstAnnotationOf(parameter.getter ?? parameter)) !=
        null;

    if (isAutoIncrement && !parameter.type.isDartCoreInt) {
      throw 'The following field is annotated with @AutoIncrement() but has an unallowed type:\n'
          '  - "${parameter.displayString()}" in class "${parentTable.element.displayString()}"\n'
          'A field annotated with @AutoIncrement() must be of type int.';
    }

    final Element? getter = parameter.getter;
    if (bindToChecker.hasAnnotationOf(getter ?? parameter)) {
      var r = ConstantReader(bindToChecker.annotationsOf(parameter.getter ?? parameter).first);
      throw 'Column field was annotated with "${r.toSource()}", which is not supported.\n'
          '  - ${parameter.displayString()}';
    }

    final defaultAnnotation =
        defaultChecker.firstAnnotationOf(parameter) ??
        defaultChecker.firstAnnotationOf(getter ?? parameter);
    if (defaultAnnotation != null) {
      var r = ConstantReader(defaultAnnotation);
      defaultValue = r.read('value').stringValue;
    } else {
      defaultValue = null;
    }
  }

  @override
  void checkConverter() {
    if (converter != null) {
      var type = converter!.type as InterfaceType;
      var converterType = type.superclass!.typeArguments[0];

      if (dataType.element != converterType.element) {
        throw 'The following field is annotated with @UseConverter(...) with a custom converter '
            'that has a different type than the field:\n'
            '  - Field "${parameter.displayString()}" in class "${parentTable.element.displayString()}"\n'
            '  - Converter "${converter!.toSource()}" with type "$converterType"';
      }
    }
  }

  @override
  void checkModifiers() {
    var viewModifiers = modifiers.where((m) => m.instanceOf(viewedInChecker));
    if (viewModifiers.isNotEmpty) {
      throw 'Column field was annotated with "${viewModifiers.first.toSource()}", which is not supported.\n'
          '  - ${parameter.displayString()}';
    }
  }

  @override
  bool get isList => parameter.type.isDartCoreList;

  DartType get dataType {
    if (isList) {
      return (parameter.type as InterfaceType).typeArguments[0];
    } else {
      return parameter.type;
    }
  }

  String get dartType => dataType.getDisplayString(withNullability: false);

  @override
  String get sqlType {
    if (isAutoIncrement) {
      return 'serial';
    }
    return rawSqlType;
  }

  @override
  String get rawSqlType {
    var type = isList ? '_' : '';

    if (converter != null) {
      type += ConstantReader(converter).read('type').stringValue;
    } else {
      var t = getSqlType(dataType);
      if (t != null) {
        type += t;
      } else {
        throw 'The following field has an unsupported type:\n'
            '  - Field "${parameter.displayString()}" in class "${parentTable.element.displayString()}"\n'
            'Either change the type to a supported column type, make the class a [Model] or use a custom [TypeConverter] with [@UseConverter].';
      }
    }
    return type;
  }

  @override
  String get paramName => parameter.name!;

  @override
  String get columnName => state.options.columnCaseStyle.transform(parameter.name!);

  @override
  bool get isNullable => parameter.type.nullabilitySuffix != NullabilitySuffix.none;
}
