import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('schema builder', () {
    group('generates basic schema', () {
      late String source;

      setUpAll(() async {
        source = await generateSchema('''
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
        expect(
          source,
          contains(
            'class AView {\n'
            '  AView({required this.id, required this.b});\n\n'
            '  final String id;\n'
            '  final BView b;\n'
            '}',
          ),
        );

        expect(
          source,
          contains(
            'class BView {\n'
            '  BView({required this.id});\n\n'
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
            '  AInsertRequest({required this.id, required this.bId});\n\n'
            '  final String id;\n'
            '  final String bId;\n'
            '}',
          ),
        );

        expect(
          source,
          contains(
            'class BInsertRequest {\n'
            '  BInsertRequest({required this.id});\n\n'
            '  final String id;\n'
            '}',
          ),
        );
      });

      test('update requests', () {
        expect(
          source,
          contains(
            'class AUpdateRequest {\n'
            '  AUpdateRequest({required this.id, this.bId});\n\n'
            '  final String id;\n'
            '  final String? bId;\n'
            '}',
          ),
        );

        expect(
          source,
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
