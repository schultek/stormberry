import 'package:stormberry/src/builder/elements/column/column_element.dart';
import 'package:test/test.dart';

import '../../utils.dart';

void main() {
  group('analyzing builder', () {
    test('analyzes used converter', () async {
      var schema = await analyzeSchema('''
        import 'package:stormberry/stormberry.dart';

        @Model()
        abstract class A {
          @PrimaryKey()
          String get id;
        
          @UseConverter(BConverter())
          B get b;
        }
        
        class B {}
        
        class BConverter extends TypeConverter<B> {
          const BConverter() : super('jsonb');
        }
      ''');

      expect(schema.tables, hasLength(1));

      var table = schema.tables.values.first;
      var column = table.columns.last;

      expect(
        column,
        isFieldColumn(
          columnName: 'b',
          sqlType: 'jsonb',
          dartType: 'B',
          paramName: 'b',
          isNullable: false,
          isList: false,
        ),
      );
    });

    test('analyzes used converter on nullable field', () async {
      var schema = await analyzeSchema('''
        import 'package:stormberry/stormberry.dart';

        @Model()
        abstract class A {
          @PrimaryKey()
          String get id;
        
          @UseConverter(BConverter())
          B? get b;
        }
        
        class B {}
        
        class BConverter extends TypeConverter<B> {
          const BConverter() : super('jsonb');
        }
      ''');

      expect(schema.tables, hasLength(1));

      var table = schema.tables.values.first;
      var column = table.columns.last;

      expect(
        column,
        isFieldColumn(
          columnName: 'b',
          sqlType: 'jsonb',
          dartType: 'B',
          paramName: 'b',
          isNullable: true,
          isList: false,
        ),
      );
    });

    test('analyzes unused converter', () async {
      var schema = await analyzeSchema('''
        import 'package:stormberry/stormberry.dart';

        @Model()
        abstract class A {
          @PrimaryKey()
          String get id;
        
          B? get b;
        }
        
        class B {}
      ''');

      expect(schema.tables, hasLength(1));

      var table = schema.tables.values.first;
      var column = table.columns.last;

      expect(
        () => (column as NamedColumnElement).sqlType,
        throwsA('The following field has an unsupported type:\n'
            '  - Field "B? b" in class "abstract class A"\n'
            'Either change the type to a supported column type, make the class a [Model] or use a custom [TypeConverter] with [@UseConverter].'),
      );
    });
  });
}
