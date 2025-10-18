import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:stormberry/src/builder/builders/schema_builder.dart';
import 'package:test/test.dart';

import '../analyze/utils.dart';

final modelSchemaId = AssetId.parse('model|model.schema.dart');

Future<TestBuilderResult> generateSchema(String source) async {
  var schema = await analyzeSchema(source);
  var inputs = {'model|model.dart': source};

  final result = await testBuilder(SchemaBuilder(BuilderOptions({}), schema), {...inputs});

  expect(result.buildResult.outputs.single, equals(modelSchemaId));
  return result;
}

void checkSchema(TestBuilderResult result, Object matcher) {
  checkOutputs(
    {'model|model.schema.dart': decodedMatches(matcher)},
    result.buildResult.outputs,
    result.readerWriter,
  );
}
