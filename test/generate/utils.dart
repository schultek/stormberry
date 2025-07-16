import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:stormberry/src/builder/builders/analyzing_builder.dart';
import 'package:stormberry/src/builder/builders/schema_builder.dart';
import 'package:test/test.dart';

import '../polyfill.dart';

final modelSchemaId = AssetId.parse('model|model.schema.dart');

Future<String> generateSchema(String source) async {
  var manager = ResourceManager();

  var inputs = {'model|model.dart': source};

  var outputs = await testBuilder2(
    AnalyzingBuilder(BuilderOptions({})),
    inputs,
    reader: await PackageAssetReader.currentIsolate(),
    resourceManager: manager,
  );

  outputs = await testBuilder2(
    SchemaBuilder(BuilderOptions({})),
    {
      ...inputs,
      ...outputs.map((id, content) => MapEntry(id.toString(), content))
    },
    reader: await PackageAssetReader.currentIsolate(),
    resourceManager: manager,
  );

  expect(outputs.keys.single, equals(modelSchemaId));
  return utf8.decode(outputs[modelSchemaId]!);
}
