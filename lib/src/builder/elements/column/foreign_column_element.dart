import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';

import '../../../core/case_style.dart';
import '../../schema.dart';
import '../table_element.dart';
import 'column_element.dart';

class ForeignColumnElement extends ColumnElement
    with RelationalColumnElement, ReferencingColumnElement, NamedColumnElement {
  @override
  final FieldElement? parameter;
  @override
  final TableElement linkedTable;

  @override
  late ReferencingColumnElement referencedColumn;

  ForeignColumnElement(
      this.parameter, this.linkedTable, TableElement parentTable, BuilderState state)
      : super(parentTable, state);

  @override
  String get sqlType => getSqlType(linkedTable.primaryKeyParameter!.type)!;

  @override
  String get paramName => CaseStyle.camelCase.transform(columnName);

  @override
  bool get isList => false;

  @override
  String get columnName => linkedTable.getForeignKeyName(base: parameter?.name)!;

  bool get isUnique => !referencedColumn.isList;

  @override
  bool get isNullable {
    if (parameter != null) {
      return parameter!.type.nullabilitySuffix != NullabilitySuffix.none;
    } else if (parentTable.primaryKeyColumn == null) {
      return parentTable.columns.whereType<ForeignColumnElement>().length > 1;
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
      'link_primary_key_name': linkedTable.primaryKeyColumn!.columnName,
    };
  }
}
