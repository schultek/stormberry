import 'package:analyzer/dart/element/element.dart';

import '../../schema.dart';
import '../join_table_element.dart';
import '../table_element.dart';
import 'column_element.dart';

class JoinColumnElement extends ColumnElement with RelationalColumnElement, LinkedColumnElement {
  @override
  final FieldElement parameter;
  @override
  final TableElement linkedTable;
  final JoinTableElement joinTable;

  late JoinColumnElement referencedColumn;

  JoinColumnElement(this.parameter, this.linkedTable, this.joinTable, TableElement parentBuilder,
      BuilderState state)
      : super(parentBuilder, state) {
    if (converter != null) {
      print('Relational field was annotated with @UseConverter(...), which is not supported.\n'
          '  - ${parameter.getDisplayString(withNullability: true)}');
    }
  }

  String get columnName =>
      parentTable.getForeignKeyName()! + (referencedColumn.parentTable == parentTable ? '_a' : '');

  @override
  bool get isList => true;

  @override
  String toString() {
    return 'JoinColumnBuilder{${parameter.name}';
  }
}
