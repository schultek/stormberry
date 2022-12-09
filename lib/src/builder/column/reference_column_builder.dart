import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';

import '../stormberry_builder.dart';
import '../table_builder.dart';
import 'column_builder.dart';
import 'foreign_column_builder.dart';

class ReferenceColumnBuilder extends ColumnBuilder with RelationalColumnBuilder, ReferencingColumnBuilder {
  @override
  FieldElement? parameter;
  @override
  TableBuilder linkBuilder;

  @override
  covariant late ForeignColumnBuilder referencedColumn;

  ReferenceColumnBuilder(this.parameter, this.linkBuilder, TableBuilder parentBuilder, BuilderState state)
      : super(parentBuilder, state);

  @override
  String get paramName => parameter?.name ?? '';

  bool get isNullable {
    if (parameter != null) {
      return parameter!.type.nullabilitySuffix != NullabilitySuffix.none;
    } else if (parentBuilder.primaryKeyColumn == null) {
      return parentBuilder.columns.whereType<ReferenceColumnBuilder>().length > 1;
    } else {
      return true;
    }
  }

  @override
  bool get isList => parameter?.type.isDartCoreList ?? true;

  @override
  Map<String, dynamic> toMap() {
    if (!isList) {
      return {
        'type': 'reference_column',
        'param_name': parameter!.name,
        'ref_column_name': referencedColumn.columnName,
      };
    } else {
      return {
        'type': 'multi_reference_column',
        'param_name': parameter!.name,
        'ref_column_name': referencedColumn.columnName,
        'link_table_name': linkBuilder.tableName,
      };
    }
  }

  @override
  String toString() {
    return 'ReferenceColumnBuilder{$paramName}';
  }
}
