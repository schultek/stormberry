import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('schema builder', () {
    group('generates basic schema', () {
      late TestBuilderResult result;

      setUpAll(() async {
        result = await generateSchema('''
          import 'package:stormberry/stormberry.dart';

          @Model()
          abstract class A {
            @PrimaryKey()
            String get id;
          
            B get b;
          }
          
          @Model()
          abstract class B {
            @PrimaryKey()
            String get id;
          }
        ''');
      });

      test('view classes', () async {
        checkSchema(
          result,
          contains(
            'class AView {\n'
            '  AView({required this.id, required this.b});\n\n'
            '  final String id;\n'
            '  final BView b;\n'
            '}',
          ),
        );

        checkSchema(
          result,
          contains(
            'class BView {\n'
            '  BView({required this.id});\n\n'
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
            '  AInsertRequest({required this.id, required this.bId});\n\n'
            '  final String id;\n'
            '  final String bId;\n'
            '}',
          ),
        );

        checkSchema(
          result,
          contains(
            'class BInsertRequest {\n'
            '  BInsertRequest({required this.id});\n\n'
            '  final String id;\n'
            '}',
          ),
        );
      });

      test('update requests', () {
        checkSchema(
          result,
          contains(
            'class AUpdateRequest {\n'
            '  AUpdateRequest({required this.id, this.bId});\n\n'
            '  final String id;\n'
            '  final String? bId;\n'
            '}',
          ),
        );

        checkSchema(
          result,
          contains(
            'class BUpdateRequest {\n'
            '  BUpdateRequest({required this.id});\n\n'
            '  final String id;\n'
            '}',
          ),
        );
      });
    });
  });
}
