import 'package:analyzer/dart/element/element.dart';

import '../join_table_builder.dart';
import '../stormberry_builder.dart';
import '../table_builder.dart';
import 'column_builder.dart';

class JoinColumnBuilder extends ColumnBuilder with LinkedColumnBuilder {
  @override
  FieldElement parameter;
  @override
  TableBuilder linkBuilder;
  JoinTableBuilder joinBuilder;

  late JoinColumnBuilder referencedColumn;

  JoinColumnBuilder(this.parameter, this.linkBuilder, this.joinBuilder, TableBuilder parentBuilder, BuilderState state)
      : super(parentBuilder, state);

  @override
  bool get isList => true;

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'join_column',
      'param_name': parameter.name,
      'join_table_name': joinBuilder.tableName,
      'link_table_name': linkBuilder.tableName,
      'parent_foreign_key_name': parentBuilder.getForeignKeyName()!,
      'link_primary_key_name': linkBuilder.primaryKeyColumn!.columnName,
      'link_foreign_key_name': linkBuilder.getForeignKeyName()!,
    };
  }

  @override
  String toString() {
    return 'JoinColumnBuilder{${parameter.name}';
  }
}
