import 'package:analyzer/dart/element/element.dart';

import '../../schema.dart';
import '../join_table_element.dart';
import '../table_element.dart';
import 'column_element.dart';

class JoinColumnElement extends ColumnElement with RelationalColumnElement, LinkedColumnElement {
  @override
  FieldElement parameter;
  @override
  TableElement linkedTable;
  JoinTableElement joinTable;

  late JoinColumnElement referencedColumn;

  JoinColumnElement(this.parameter, this.linkedTable, this.joinTable, TableElement parentBuilder, BuilderState state)
      : super(parentBuilder, state) {
    if (converter != null) {
      print('Relational field was annotated with @UseConverter(...), which is not supported.\n'
          '  - ${parameter.getDisplayString(withNullability: true)}');
    }
  }

  @override
  bool get isList => true;

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'join_column',
      'param_name': parameter.name,
      'join_table_name': joinTable.tableName,
      'link_table_name': linkedTable.tableName,
      'parent_foreign_key_name': parentTable.getForeignKeyName()!,
      'link_primary_key_name': linkedTable.primaryKeyColumn!.columnName,
      'link_foreign_key_name': linkedTable.getForeignKeyName()!,
    };
  }

  @override
  String toString() {
    return 'JoinColumnBuilder{${parameter.name}';
  }
}
