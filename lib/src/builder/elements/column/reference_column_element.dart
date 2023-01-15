import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';

import '../../schema.dart';
import '../table_element.dart';
import 'column_element.dart';
import 'foreign_column_element.dart';

class ReferenceColumnElement extends ColumnElement
    with RelationalColumnElement, ReferencingColumnElement {
  @override
  final FieldElement? parameter;
  @override
  final TableElement linkedTable;

  @override
  covariant late ForeignColumnElement referencedColumn;

  ReferenceColumnElement(
      this.parameter, this.linkedTable, TableElement parentTable, BuilderState state)
      : super(parentTable, state);

  @override
  String get paramName => parameter?.name ?? '';

  bool get isNullable {
    if (parameter != null) {
      return parameter!.type.nullabilitySuffix != NullabilitySuffix.none;
    } else if (parentTable.primaryKeyColumn == null) {
      return parentTable.columns.whereType<ReferenceColumnElement>().length > 1;
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
        'link_table_name': linkedTable.tableName,
      };
    }
  }
}
