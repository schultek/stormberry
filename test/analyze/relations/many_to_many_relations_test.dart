import 'package:test/test.dart';

import '../utils.dart';

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
          
          @HiddenIn.defaultView()
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

      expect(tableA.columns[0], isIdColumn());

      expect(
        tableA.columns[1],
        isJoinColumn(linkedTo: tableB, references: tableB.columns[1], joinedTo: join),
      );

      expect(
        tableA.columns[1],
        isJoinColumn(linkedTo: tableB, references: tableB.columns[1], joinedTo: join),
      );

      expect(tableB.columns[0], isIdColumn());

      expect(
        tableB.columns[1],
        isJoinColumn(linkedTo: tableA, references: tableA.columns[1], joinedTo: join),
      );
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
          'Either define a primary key for B or change the relation by changing field "List<A> a" to have a non-list type.',
        ),
      );
    });
  });
}
