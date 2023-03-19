import 'package:build/build.dart';
import 'package:test/test.dart';

import 'utils.dart';

final modelSchemaId = AssetId.parse('model|model.schema.dart');

void main() {
  group('schema builder', () {
    group('generates modified schema', () {
      late String source;

      setUpAll(() async {
        source = await generateSchema('''
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
        expect(
          source,
          contains(
            'class AView {\n'
            '  AView({\n'
            '    required this.id,\n'
            '  });\n\n'
            '  final String id;\n'
            '}',
          ),
        );
      });

      test('insert requests', () {
        expect(
          source,
          contains(
            'class AInsertRequest {\n'
            '  AInsertRequest({\n'
            '    required this.id,\n'
            '    required this.secretId,\n'
            '  });\n\n'
            '  final String id;\n'
            '  final String secretId;\n'
            '}',
          ),
        );
      });

      test('update requests', () {
        expect(
          source,
          contains(
            'class AUpdateRequest {\n'
            '  AUpdateRequest({\n'
            '    required this.id,\n'
            '    this.secretId,\n'
            '  });\n\n'
            '  final String id;\n'
            '  final String? secretId;\n'
            '}',
          ),
        );
      });
    });
  });
}
