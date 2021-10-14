import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';

import '../../core/case_style.dart';
import '../stormberry_builder.dart';
import '../table_builder.dart';
import 'column_builder.dart';

class ForeignColumnBuilder extends ColumnBuilder with ReferencingColumnBuilder, NamedColumnBuilder {
  @override
  ParameterElement? parameter;
  @override
  TableBuilder linkBuilder;

  @override
  late ReferencingColumnBuilder referencedColumn;

  ForeignColumnBuilder(this.parameter, this.linkBuilder, TableBuilder parentBuilder, BuilderState state)
      : super(parentBuilder, state);

  @override
  String get sqlType => getSqlType(linkBuilder.primaryKeyParameter!.type);

  @override
  String get paramName => CaseStyle.camelCase.transform(columnName);

  @override
  bool get isList => false;

  @override
  String get columnName => linkBuilder.getForeignKeyName(base: parameter?.name)!;

  bool get isUnique => !referencedColumn.isList;

  @override
  bool get isNullable {
    if (parameter != null) {
      return parameter!.type.nullabilitySuffix != NullabilitySuffix.none;
    } else if (parentBuilder.primaryKeyColumn == null) {
      return parentBuilder.columns.whereType<ForeignColumnBuilder>().length > 1;
    } else {
      return true;
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'foreign_column',
      'param_name': parameter!.name,
      'column_name': columnName,
      'link_primary_key_name': linkBuilder.primaryKeyColumn!.columnName,
    };
  }
}
