import 'package:test/test.dart';

import '../../utils.dart';

void main() {
  group('analyzing builder', () {
    test('analyzes two-sided double-keyed many-to-many relation', () async {
      var schema = await analyzeSchema('''
        import 'package:stormberry/stormberry.dart';

        @Model()
        abstract class A {
          @PrimaryKey()
          String get id;
        
          List<B> get b;
        }
        
        @Model()
        abstract class B {
          @PrimaryKey()
          String get id;
          
          List<A> get a;
        }
      ''');

      // TODO: generate relation ids for inserting / updating

      expect(schema.tables, hasLength(2));
      expect(schema.joinTables, hasLength(1));

      var tableA = schema.tables.values.first;
      var tableB = schema.tables.values.toList()[1];

      var join = schema.joinTables.values.first;

      expect(tableA.tableName, equals('as'));
      expect(tableB.tableName, equals('bs'));

      testIdColumn(tableA.columns[0]);

      testColumn(
        tableA.columns[1],
        isList: true,
        linkedTo: tableB,
        references: tableB.columns[0],
        joinedTo: join,
      );

      testColumn(
        tableB.columns[0],
        isList: true,
        linkedTo: tableA,
        references: tableA.columns[1],
        joinedTo: join,
      );

      testIdColumn(tableB.columns[1]);
    });
  });
}
