import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:stormberry/src/builder/builders/analyzing_builder.dart';
import 'package:stormberry/src/builder/elements/column/column_element.dart';
import 'package:stormberry/src/builder/elements/column/field_column_element.dart';
import 'package:stormberry/src/builder/elements/column/foreign_column_element.dart';
import 'package:stormberry/src/builder/elements/column/join_column_element.dart';
import 'package:stormberry/src/builder/elements/column/reference_column_element.dart';
import 'package:stormberry/src/builder/elements/column/view_column_element.dart';
import 'package:stormberry/src/builder/elements/join_table_element.dart';
import 'package:stormberry/src/builder/elements/table_element.dart';
import 'package:stormberry/src/builder/schema.dart';
import 'package:test/test.dart';

Future<SchemaState> analyzeSchema(String source) async {
  final builder = AnalyzingBuilder(BuilderOptions({}));
  final assetId = AssetId.parse('model|model.dart');

  final schema = await resolveSources({'model|model.dart': source}, (resolver) async {
    final schema = SchemaState();
    await builder.analyze(schema, await resolver.libraryFor(assetId), assetId);
    schema.finalize();
    return schema;
  }, readAllSourcesFromFilesystem: true);

  return schema;
}

Matcher isIdColumn({String name = 'id'}) {
  return isFieldColumn(
    columnName: name,
    sqlType: 'text',
    isNullable: false,
    dartType: 'String',
    paramName: name,
    isList: false,
  );
}

Matcher isFieldColumn({
  required String dartType,
  required String columnName,
  required String sqlType,
  required bool isNullable,
  required String paramName,
  required bool isList,
  String? defaultValue,
}) {
  return allOf(
    isA<FieldColumnElement>(),
    _has<FieldColumnElement>('dartType', (c) => c.dartType, dartType),
    _isNamedColumn(
      columnName: columnName,
      sqlType: sqlType,
      isNullable: isNullable,
      paramName: paramName,
      defaultValue: defaultValue,
    ),
    _isListColumn(isList: isList),
  );
}

Matcher isReferenceColumn({
  required ColumnElement references,
  required TableElement linkedTo,
  required String paramName,
  required bool isList,
}) {
  return allOf(
    isA<ReferenceColumnElement>(),
    _isReferencingColumn(references: references, linkedTo: linkedTo, paramName: paramName),
    _isListColumn(isList: isList),
  );
}

Matcher isForeignColumn({
  required String columnName,
  required String sqlType,
  required bool isNullable,
  required String paramName,
  required ColumnElement references,
  required TableElement linkedTo,
  required bool isList,
}) {
  return allOf(
    isA<ForeignColumnElement>(),
    _isNamedColumn(
      columnName: columnName,
      sqlType: sqlType,
      isNullable: isNullable,
      paramName: paramName,
    ),
    _isReferencingColumn(references: references, linkedTo: linkedTo, paramName: paramName),
    _isListColumn(isList: isList),
  );
}

Matcher isJoinColumn({
  required JoinTableElement joinedTo,
  required TableElement linkedTo,
  required ColumnElement references,
}) {
  return allOf(
    isA<JoinColumnElement>(),
    _has<JoinColumnElement>('joinedTo', (c) => c.joinTable, joinedTo),
    _has<JoinColumnElement>('references', (c) => c.referencedColumn, references),
    _isLinkedColumn(linkedTo: linkedTo),
    _isListColumn(isList: true),
  );
}

Matcher _isListColumn({required bool isList}) {
  return _has<ColumnElement>('isList', (c) => c.isList, isList);
}

Matcher _isNamedColumn({
  required String columnName,
  required String sqlType,
  required bool isNullable,
  required String paramName,
  String? defaultValue,
}) {
  return allOf(
    isA<NamedColumnElement>(),
    _has<NamedColumnElement>('columnName', (c) => c.columnName, columnName),
    _has<NamedColumnElement>('sqlType', (c) => c.sqlType, sqlType),
    _has<NamedColumnElement>('isNullable', (c) => c.isNullable, isNullable),
    defaultValue != null
        ? _has<NamedColumnElement>('defaultValue', (c) => c.defaultValue, defaultValue)
        : null,
    _isParameterColumn(paramName: paramName),
  );
}

Matcher _isParameterColumn({required String paramName}) {
  return allOf(
    isA<ParameterColumnElement>(),
    _has<ParameterColumnElement>('paramName', (c) => c.paramName, paramName),
  );
}

Matcher _isLinkedColumn({required TableElement linkedTo}) {
  return allOf(
    isA<LinkedColumnElement>(),
    _has<LinkedColumnElement>('linkedTo', (c) => c.linkedTable, linkedTo),
  );
}

Matcher _has<T>(String name, dynamic Function(T e) getter, dynamic value) {
  return HasProp(name, getter, equals(value));
}

class HasProp<T> extends CustomMatcher {
  HasProp(String name, this.getter, matcher) : super('Column with $name that is', name, matcher);
  final dynamic Function(T e) getter;

  @override
  dynamic featureValueOf(actual) {
    return getter(actual as T);
  }
}

Matcher _isReferencingColumn({
  required ColumnElement references,
  required TableElement linkedTo,
  required String paramName,
}) {
  return allOf(
    isA<ReferencingColumnElement>(),
    _has<ReferencingColumnElement>('references', (c) => c.referencedColumn, references),
    _isLinkedColumn(linkedTo: linkedTo),
    _isParameterColumn(paramName: paramName),
  );
}

Matcher isViewColumn({
  required String? viewAs,
  required String? transformer,
  required String paramName,
  required String dartType,
  required bool isNullable,
}) {
  return allOf(
    isA<ViewColumnElement>(),
    _has<ViewColumnElement>('viewAs', (c) => c.viewAs, viewAs),
    _has<ViewColumnElement>('transformer', (c) => c.transformer, transformer),
    _has<ViewColumnElement>('paramName', (c) => c.paramName, paramName),
    _has<ViewColumnElement>('dartType', (c) => c.dartType, dartType),
    _has<ViewColumnElement>('isNullable', (c) => c.isNullable, isNullable),
  );
}
