import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../stormberry_builder.dart';
import '../table_builder.dart';

abstract class NamedColumnBuilder implements ParameterColumnBuilder {
  String get columnName;
  bool get isNullable;
  String get sqlType;
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

  ColumnBuilder(this.parentBuilder, this.state);

  FieldElement? get parameter;

  bool get isList;

  Map<String, dynamic> toMap();

  String getSqlType(DartType type) {
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
      return 'jsonb';
    }
  }
}
