import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

import '../../core/case_style.dart';
import '../stormberry_builder.dart';
import '../table_builder.dart';
import '../utils.dart';
import 'column_builder.dart';

class FieldColumnBuilder extends ColumnBuilder with NamedColumnBuilder {
  @override
  FieldElement parameter;

  late final bool isAutoIncrement;

  FieldColumnBuilder(this.parameter, TableBuilder parentBuilder, BuilderState state) : super(parentBuilder, state) {
    isAutoIncrement = (autoIncrementChecker.firstAnnotationOf(parameter) ??
            autoIncrementChecker.firstAnnotationOf(parameter.getter ?? parameter)) !=
        null;

    if (isAutoIncrement && !parameter.type.isDartCoreInt) {
      throw 'The following field is annotated with @AutoIncrement() but has an unallowed type:\n'
          '  - "${parameter.getDisplayString(withNullability: true)}" in class "${parentBuilder.element.getDisplayString(withNullability: true)}"\n'
          'A field annotated with @AutoIncrement() must be of type int.';
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
    var type = isList ? '_' : '';
    var convertedType = state.typeConverters[dataType.element?.name]?.value;
    if (convertedType != null) {
      type += convertedType;
    } else {
      type += getSqlType(dataType);
    }
    return type;
  }

  @override
  String get paramName => parameter.name;

  @override
  String get columnName => state.options.columnCaseStyle.transform(parameter.name);

  @override
  bool get isNullable => parameter.type.nullabilitySuffix != NullabilitySuffix.none;

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'field_column',
      'column_name': columnName,
    };
  }

  @override
  String toString() {
    return 'FieldColumnBuilder{$paramName}';
  }
}
