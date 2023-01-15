import 'package:test/test.dart';

import '../../utils.dart';

void main() {
  group('analyzing builder', () {
    test('analyzes one-sided double-keyed default view', () async {
      var schema = await analyzeSchema('''
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

      expect(schema.tables, hasLength(2));
      expect(schema.joinTables, isEmpty);

      var tableA = schema.tables.values.first;
      var tableB = schema.tables.values.toList()[1];

      expect(tableA.tableName, equals('as'));
      expect(tableB.tableName, equals('bs'));

      expect(tableA.views, hasLength(1));
      expect(tableA.views.keys.first, equals(''));

      var viewA = tableA.views['']!;

      expect(viewA.columns, hasLength(2));

      testViewColumn(
        viewA.columns[0],
        {
          'type': 'field_column',
          'column_name': 'id',
        },
        paramName: 'id',
        dartType: 'String',
        isNullable: false,
      );

      testViewColumn(
        viewA.columns[1],
        {
          'type': 'foreign_column',
          'param_name': 'b',
          'column_name': 'b_id',
          'link_primary_key_name': 'id',
        },
        paramName: 'b',
        dartType: 'B',
        isNullable: false,
      );
    });
  });
}
