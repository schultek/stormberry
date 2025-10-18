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
        ''');
      });

      test('view classes', () async {
        checkSchema(
          result,
          contains(
            'class AView with MyMixin implements AViewInterface {\n'
            '  AView({required this.id});\n\n'
            '  final String id;\n'
            '}',
          ),
        );

        checkSchema(
          result,
          contains(
            'class TestAView with TestMixin {\n'
            '  TestAView({required this.id});\n\n'
            '  final String id;\n'
            '}',
          ),
        );
      });

      test('insert requests', () {
        checkSchema(
          result,
          contains(
            'class AInsertRequest extends InsertBase {\n'
            '  AInsertRequest({required this.id});\n\n'
            '  final String id;\n'
            '}',
          ),
        );
      });

      test('update requests', () {
        checkSchema(
          result,
          contains(
            'class AUpdateRequest extends UpdateBase {\n'
            '  AUpdateRequest({required this.id});\n\n'
            '  final String id;\n'
            '}',
          ),
        );
      });
    });
  });
}
