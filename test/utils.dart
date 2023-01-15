import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:stormberry/src/builder/builders/analyzing_builder.dart';
import 'package:stormberry/src/builder/elements/column/column_element.dart';
import 'package:stormberry/src/builder/elements/column/field_column_element.dart';
import 'package:stormberry/src/builder/elements/column/join_column_element.dart';
import 'package:stormberry/src/builder/elements/join_table_element.dart';
import 'package:stormberry/src/builder/elements/table_element.dart';
import 'package:stormberry/src/builder/elements/view_element.dart';
import 'package:stormberry/src/builder/schema.dart';
import 'package:test/test.dart';

import 'polyfill.dart';

Future<SchemaState> analyzeSchema(String source) async {
  var manager = ResourceManager();

  await testBuilder2(
    AnalyzingBuilder(BuilderOptions({})),
    {'model|model.dart': source},
    reader: await PackageAssetReader.currentIsolate(),
    resourceManager: manager,
  );

  var schema = await manager.fetch(schemaResource);
  schema.finalize();

  return schema;
}

void testIdColumn(ColumnElement column, {String? name = 'id'}) {
  testColumn(
    column,
    {'type': 'field_column', 'column_name': name},
    columnName: name,
    sqlType: 'text',
    dartType: 'String',
    paramName: name,
    isList: false,
    isNullable: false,
  );
}

void testColumn(
  ColumnElement column,
  Map<String, dynamic>? raw, {
  String? columnName,
  String? sqlType,
  String? dartType,
  String? paramName,
  required bool isList,
  bool? isNullable,
  TableElement? linkedTo,
  ColumnElement? references,
  JoinTableElement? joinedTo,
}) {
  if (columnName != null || sqlType != null || isNullable != null) {
    expect(column, isA<NamedColumnElement>());
    (column as NamedColumnElement);
    expect(column.columnName, equals(columnName));
    expect(column.sqlType, equals(sqlType));
    expect(column.isNullable, equals(isNullable));
  } else {
    expect(column, isNot(isA<NamedColumnElement>()),
        reason: 'Missing [columnName] or [sqlType] param for named column.');
  }

  if (dartType != null) {
    expect(column, isA<FieldColumnElement>());
    (column as FieldColumnElement);
    expect(column.dartType, equals(dartType));
  } else {
    expect(column, isNot(isA<FieldColumnElement>()),
        reason: 'Missing [dartType] param for field column.');
  }

  if (paramName != null) {
    expect(column, isA<ParameterColumnElement>());
    (column as ParameterColumnElement);
    expect(column.paramName, equals(paramName));
  } else {
    expect(column, isNot(isA<ParameterColumnElement>()),
        reason: 'Missing [paramName] param for parameter column.');
  }

  expect(column.isList, equals(isList));

  if (linkedTo != null) {
    expect(column, isA<LinkedColumnElement>());
    (column as LinkedColumnElement);
    expect(column.linkedTable, equals(linkedTo));
  } else {
    expect(column, isNot(isA<LinkedColumnElement>()),
        reason: 'Missing [linkedTo] param for linked column.');
  }

  if (references != null && joinedTo == null) {
    expect(column, isA<ReferencingColumnElement>());
    (column as ReferencingColumnElement);
    expect(column.referencedColumn, equals(references));
  } else {
    expect(column, isNot(isA<ReferencingColumnElement>()),
        reason: 'Missing [references] param for referencing column.');
  }

  if (joinedTo != null) {
    expect(column, isA<JoinColumnElement>());
    (column as JoinColumnElement);

    expect(column.joinTable, equals(joinedTo));
    expect(column.linkedTable, equals(linkedTo));
    expect(references, isA<JoinColumnElement>());
    expect(column.referencedColumn, equals(references));
  } else {
    expect(column, isNot(isA<JoinColumnElement>()),
        reason: 'Missing [joinedTo] param for join column.');
  }

  if (column.parameter != null) {
    expect(column.toMap(), equals(raw));
  } else {
    expect(raw, isNull, reason: 'Raw provided for a column without a parameter.');
  }
}

void testViewColumn(
  ViewColumn column,
  Map<String, dynamic>? raw, {
  String? viewAs,
  String? transformer,
  String? paramName,
  String? dartType,
  bool? isNullable,
}) {
  expect(column.column.toMap(), equals(raw));

  expect(column.viewAs, equals(viewAs));
  expect(column.transformer, equals(viewAs));
  expect(column.paramName, equals(paramName));
  expect(column.dartType, equals(dartType));
  expect(column.isNullable, equals(isNullable));
}
