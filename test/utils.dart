import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:stormberry/src/builder/builders/analyzing_builder.dart';
import 'package:stormberry/src/builder/elements/column/column_element.dart';
import 'package:stormberry/src/builder/elements/column/field_column_element.dart';
import 'package:stormberry/src/builder/elements/column/join_column_element.dart';
import 'package:stormberry/src/builder/elements/join_table_element.dart';
import 'package:stormberry/src/builder/elements/table_element.dart';
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
  testColumn(column, columnName: name, sqlType: 'text', dartType: 'String', paramName: name, isList: false);
}

void testColumn(
  ColumnElement column, {
  String? columnName,
  String? sqlType,
  String? dartType,
  String? paramName,
  bool? isList,
  TableElement? linkedTo,
  ColumnElement? references,
  JoinTableElement? joinedTo,
}) {
  if (columnName != null || sqlType != null) {
    expect(column, isA<NamedColumnElement>());
    (column as NamedColumnElement);
    expect(column.columnName, equals(columnName));
    expect(column.sqlType, equals(sqlType));
  } else {
    expect(column, isNot(isA<NamedColumnElement>()));
  }

  if (dartType != null) {
    expect(column, isA<FieldColumnElement>());
    (column as FieldColumnElement);
    expect(column.dartType, equals(dartType));
  } else {
    expect(column, isNot(isA<FieldColumnElement>()));
  }

  if (paramName != null) {
    expect(column, isA<ParameterColumnElement>());
    (column as ParameterColumnElement);
    expect(column.paramName, equals(paramName));
  } else {
    expect(column, isNot(isA<ParameterColumnElement>()));
  }

  expect(column.isList, equals(isList));

  if (linkedTo != null) {
    expect(column, isA<LinkedColumnElement>());
    (column as LinkedColumnElement);
    expect(column.linkedTable, equals(linkedTo));
  } else {
    expect(column, isNot(isA<LinkedColumnElement>()));
  }

  if (references != null && joinedTo == null) {
    expect(column, isA<ReferencingColumnElement>());
    (column as ReferencingColumnElement);
    expect(column.referencedColumn, equals(references));
  } else {
    expect(column, isNot(isA<ReferencingColumnElement>()));
  }

  if (joinedTo != null) {
    expect(column, isA<JoinColumnElement>());
    (column as JoinColumnElement);

    expect(column.joinTable, equals(joinedTo));
    expect(column.linkedTable, equals(linkedTo));
    expect(references, isA<JoinColumnElement>());
    expect(column.referencedColumn, equals(references));
  } else {
    expect(column, isNot(isA<JoinColumnElement>()));
  }
}
