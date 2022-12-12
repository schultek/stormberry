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
        columnName: 'b_id',
        sqlType: 'text',
        paramName: 'bId',
        isList: false,
        linkedTo: tableB,
        references: tableB.columns[0],
      );

      testColumn(
        tableB.columns[0],
        paramName: '',
        isList: true,
        linkedTo: tableA,
        references: tableA.columns[1],
      );

      testIdColumn(tableB.columns[1]);
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
        columnName: 'b_id',
        sqlType: 'text',
        paramName: 'bId',
        isList: false,
        linkedTo: tableB,
        references: tableB.columns[0],
      );

      testColumn(
        tableB.columns[0],
        paramName: 'a',
        isList: true,
        linkedTo: tableA,
        references: tableA.columns[1],
      );

      testIdColumn(tableB.columns[1]);
    });
  });
}
