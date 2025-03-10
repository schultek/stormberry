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
  
          @Model(views: [Model.defaultView, #Test], meta: ModelMeta(
            insert: ClassMeta(extend: 'InsertBase'),
            update: ClassMeta(extend: 'UpdateBase'),
            view: ClassMeta(mixin: 'MyMixin', implement: '{name}Interface'),
            views: {#Test: ClassMeta(mixin: 'TestMixin')},
          ))
          abstract class A {
            @PrimaryKey()
            String get id;
          }

          mixin MyMixin {
          }

          mixin TestMixin {
          }

          abstract class AViewInterface {
          }

          class InsertBase {
          }

          class UpdateBase {
          }
        ''');
      });

      test('view classes', () async {
        expect(
          source,
          contains(
            'class AView with MyMixin implements AViewInterface {\n'
            '  AView({\n'
            '    required this.id,\n'
            '  });\n\n'
            '  final String id;\n'
            '}',
          ),
        );

        expect(
          source,
          contains(
            'class TestAView with TestMixin {\n'
            '  TestAView({\n'
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
            'class AInsertRequest extends InsertBase {\n'
            '  AInsertRequest({\n'
            '    required this.id,\n'
            '  });\n\n'
            '  final String id;\n'
            '}',
          ),
        );
      });

      test('update requests', () {
        expect(
          source,
          contains(
            'class AUpdateRequest extends UpdateBase {\n'
            '  AUpdateRequest({\n'
            '    required this.id,\n'
            '  });\n\n'
            '  final String id;\n'
            '}',
          ),
        );
      });
    });
  });
}
