import 'package:test/test.dart';

import '../../utils.dart';

void main() {
  group('analyzing builder', () {
    test('analyzes one-sided double-keyed one-to-many relation', () async {
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

      testIdColumn(tableA.columns[0]);

      testColumn(
        tableA.columns[1],
        {
          'type': 'foreign_column',
          'param_name': 'b',
          'column_name': 'b_id',
          'link_primary_key_name': 'id',
        },
        columnName: 'b_id',
        sqlType: 'text',
        paramName: 'bId',
        isList: false,
        isNullable: false,
        linkedTo: tableB,
        references: tableB.columns[1],
      );

      testIdColumn(tableB.columns[0]);

      testColumn(
        tableB.columns[1],
        null,
        paramName: '',
        isList: true,
        linkedTo: tableA,
        references: tableA.columns[1],
      );
    });

    test('analyzes two-sided double-keyed one-to-many relation', () async {
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
          
          List<A> get a;
        }
      ''');

      expect(schema.tables, hasLength(2));
      expect(schema.joinTables, isEmpty);

      var tableA = schema.tables.values.first;
      var tableB = schema.tables.values.toList()[1];

      expect(tableA.tableName, equals('as'));
      expect(tableB.tableName, equals('bs'));

      testIdColumn(tableA.columns[0]);

      testColumn(
        tableA.columns[1],
        {
          'type': 'foreign_column',
          'param_name': 'b',
          'column_name': 'b_id',
          'link_primary_key_name': 'id',
        },
        columnName: 'b_id',
        sqlType: 'text',
        paramName: 'bId',
        isList: false,
        isNullable: false,
        linkedTo: tableB,
        references: tableB.columns[1],
      );

      testIdColumn(tableB.columns[0]);

      testColumn(
        tableB.columns[1],
        {
          'type': 'multi_reference_column',
          'param_name': 'a',
          'ref_column_name': 'b_id',
          'link_table_name': 'as',
        },
        paramName: 'a',
        isList: true,
        linkedTo: tableA,
        references: tableA.columns[1],
      );
    });
  });
}
