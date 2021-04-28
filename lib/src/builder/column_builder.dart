import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

import 'case_style.dart';
import 'database_builder.dart';
import 'join_table_builder.dart';
import 'table_builder.dart';

class ColumnBuilder {
  BuilderState state;
  ParameterElement? parameter;
  TableBuilder? linkBuilder;
  JoinTableBuilder? joinBuilder;
  ColumnBuilder? referencedColumn;
  TableBuilder parentBuilder;

  ColumnBuilder(this.parameter, this.parentBuilder, this.state,
      {TableBuilder? link, JoinTableBuilder? join})
      : linkBuilder = link,
        joinBuilder = join;

  bool get isFieldColumn => linkBuilder == null;
  bool get isJoinColumn => joinBuilder != null;
  bool get isReferenceColumn =>
      joinBuilder == null &&
      linkBuilder != null &&
      (linkBuilder!.primaryKeyParameter == null || isList);
  bool get isForeignColumn =>
      joinBuilder == null &&
      linkBuilder != null &&
      linkBuilder!.primaryKeyParameter != null &&
      !isList;

  bool get isList => parameter?.type.isDartCoreList ?? false;

  DartType get dataType {
    if (linkBuilder != null) {
      return linkBuilder!.element.thisType;
    } else if (isList) {
      return (parameter!.type as InterfaceType).typeArguments[0];
    } else {
      return parameter!.type;
    }
  }

  String get dartType => dataType.getDisplayString(withNullability: false);

  String get sqlType {
    var type = isList ? '_' : '';
    var convertedType = state.typeConverters[dataType.element?.name]?.value;
    if (convertedType != null) {
      type += convertedType;
    } else if (isFieldColumn) {
      type += getSqlType(dataType);
    } else if (isForeignColumn) {
      type += getSqlType(linkBuilder!.primaryKeyParameter!.type);
    }
    return type;
  }

  String? get paramName {
    if (isForeignColumn) {
      return toCaseStyle(
          columnName!, CaseStyle.fromString(CaseStyle.camelCase));
    } else {
      return parameter?.name;
    }
  }

  String? get columnName {
    if (isFieldColumn) {
      return toCaseStyle(parameter!.name, state.options.columnCaseStyle);
    } else if (isForeignColumn) {
      return linkBuilder!
          .getForeignKeyName(base: parameter?.name, plural: isList);
    } else {
      return null;
    }
  }

  bool get isNullable {
    if (parameter != null) {
      return parameter!.type.nullabilitySuffix != NullabilitySuffix.none;
    } else if (parentBuilder.primaryKeyColumn == null) {
      return parentBuilder.columns.where((c) => c.parameter == null).length > 1;
    } else {
      return true;
    }
  }

  bool get isUnique => !(referencedColumn?.isList ?? true);

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
      // TODO support LatLng
      return 'point';
    } else {
      return 'jsonb';
    }
  }
}
