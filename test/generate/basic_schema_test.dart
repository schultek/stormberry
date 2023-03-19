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
            '  AView({\n'
            '    required this.id,\n'
            '    required this.b,\n'
            '  });\n\n'
            '  final String id;\n'
            '  final B b;\n'
            '}',
          ),
        );

        expect(
          source,
          contains(
            'class BView {\n'
            '  BView({\n'
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
            '    required this.bId,\n'
            '  });\n\n'
            '  final String id;\n'
            '  final String bId;\n'
            '}',
          ),
        );

        expect(
          source,
          contains(
            'class BInsertRequest {\n'
            '  BInsertRequest({\n'
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
            'class AUpdateRequest {\n'
            '  AUpdateRequest({\n'
            '    required this.id,\n'
            '    this.bId,\n'
            '  });\n\n'
            '  final String id;\n'
            '  final String? bId;\n'
            '}',
          ),
        );

        expect(
          source,
          contains(
            'class BUpdateRequest {\n'
            '  BUpdateRequest({\n'
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
