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
        {
          'type': 'join_column',
          'param_name': 'b',
          'join_table_name': 'as_bs',
          'link_table_name': 'bs',
          'parent_foreign_key_name': 'a_id',
          'link_primary_key_name': 'id',
          'link_foreign_key_name': 'b_id',
        },
        isList: true,
        linkedTo: tableB,
        references: tableB.columns[0],
        joinedTo: join,
      );

      testColumn(
        tableB.columns[0],
        {
          'type': 'join_column',
          'param_name': 'a',
          'join_table_name': 'as_bs',
          'link_table_name': 'as',
          'parent_foreign_key_name': 'b_id',
          'link_primary_key_name': 'id',
          'link_foreign_key_name': 'a_id',
        },
        isList: true,
        linkedTo: tableA,
        references: tableA.columns[1],
        joinedTo: join,
      );

      testIdColumn(tableB.columns[1]);
    });

    test('analyzes two-sided single-keyed many-to-many relation', () async {
      caller() => analyzeSchema('''
        import 'package:stormberry/stormberry.dart';

        @Model()
        abstract class A {
          @PrimaryKey()
          String get id;
        
          List<B> get b;
        }
        
        @Model()
        abstract class B {
          String get name;
          
          List<A> get a;
        }
      ''');

      expect(
        caller,
        throwsA(
            'Model B cannot have a many-to-many relation to model A without specifying a primary key.\n'
            'Either define a primary key for B or change the relation by changing field "List<A> a" to have a non-list type.'),
      );
    });
  });
}
