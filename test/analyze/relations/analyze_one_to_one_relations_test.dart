import 'package:test/test.dart';

import '../../utils.dart';

void main() {
  group('analyzing builder', () {
    test('analyzes one-sided single-keyed one-to-one relation', () async {
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
          String get name;
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
          'type': 'reference_column',
          'param_name': 'b',
          'ref_column_name': 'a_id',
        },
        paramName: 'b',
        isList: false,
        linkedTo: tableB,
        references: tableB.columns[0],
      );

      testColumn(
        tableB.columns[0],
        null,
        columnName: 'a_id',
        sqlType: 'text',
        paramName: 'aId',
        isList: false,
        isNullable: false,
        linkedTo: tableA,
        references: tableA.columns[1],
      );

      testIdColumn(tableB.columns[1], name: 'name');
    });

    test('analyzes two-sided double-keyed one-to-one relation', () async {
      build() => analyzeSchema('''
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
          
          A get a;
        }
      ''');

      expect(
        build,
        throwsA(
          'Model B cannot have a one-to-one relation to model A with both sides being non-nullable. '
          'At least one side has to be nullable, to insert one model before the other.\n'
          'However both "A.b" and "B.a" are non-nullable.\n'
          'Either make at least one parameter nullable or change the relation by changing one parameter to have a list type.',
        ),
      );
    });

    test('analyzes two-sided single-keyed one-to-one relation', () async {
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
          String get name;
          
          A get a;
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
          'type': 'reference_column',
          'param_name': 'b',
          'ref_column_name': 'a_id',
        },
        paramName: 'b',
        isList: false,
        linkedTo: tableB,
        references: tableB.columns[0],
      );

      testColumn(
        tableB.columns[0],
        {
          'type': 'foreign_column',
          'param_name': 'a',
          'column_name': 'a_id',
          'link_primary_key_name': 'id',
        },
        columnName: 'a_id',
        sqlType: 'text',
        paramName: 'aId',
        isList: false,
        isNullable: false,
        linkedTo: tableA,
        references: tableA.columns[1],
      );

      testIdColumn(tableB.columns[1], name: 'name');
    });
  });
}
