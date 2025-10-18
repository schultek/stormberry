import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'utils.dart';

final modelSchemaId = AssetId.parse('model|model.schema.dart');

void main() {
  group('schema builder', () {
    group('generates modified schema', () {
      late TestBuilderResult result;

      setUpAll(() async {
        result = await generateSchema('''
          import 'package:stormberry/stormberry.dart';
  
          @Model()
          abstract class A {
            @PrimaryKey()
            String get id;
          
            @HiddenIn(Model.defaultView)
            String get secretId;
          }
        ''');
      });

      test('view classes', () async {
        checkSchema(
          result,
          contains(
            'class AView {\n'
            '  AView({required this.id});\n\n'
            '  final String id;\n'
            '}',
          ),
        );
      });

      test('insert requests', () {
        checkSchema(
          result,
          contains(
            'class AInsertRequest {\n'
            '  AInsertRequest({required this.id, required this.secretId});\n\n'
            '  final String id;\n'
            '  final String secretId;\n'
            '}',
          ),
        );
      });

      test('update requests', () {
        checkSchema(
          result,
          contains(
            'class AUpdateRequest {\n'
            '  AUpdateRequest({required this.id, this.secretId});\n\n'
            '  final String id;\n'
            '  final String? secretId;\n'
            '}',
          ),
        );
      });
    });
  });
}
