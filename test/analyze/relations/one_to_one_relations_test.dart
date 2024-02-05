import 'package:test/test.dart';

import '../utils.dart';

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

      expect(tableA.columns[0], isIdColumn());

      expect(
        tableA.columns[1],
        isReferenceColumn(
          paramName: 'b',
          isList: false,
          linkedTo: tableB,
          references: tableB.columns[1],
        ),
      );

      expect(tableB.columns[0], isIdColumn(name: 'name'));

      expect(
        tableB.columns[1],
        isForeignColumn(
          columnName: 'a_id',
          sqlType: 'text',
          paramName: 'aId',
          isList: false,
          isNullable: false,
          linkedTo: tableA,
          references: tableA.columns[1],
        ),
      );
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
        
          @HiddenIn.defaultView()
          B get b;
        }
        
        @Model()
        abstract class B {
          String get name;
          
          @HiddenIn.defaultView()
          A get a;
        }
      ''');

      expect(schema.tables, hasLength(2));
      expect(schema.joinTables, isEmpty);

      var tableA = schema.tables.values.first;
      var tableB = schema.tables.values.toList()[1];

      expect(tableA.tableName, equals('as'));
      expect(tableB.tableName, equals('bs'));

      expect(tableA.columns[0], isIdColumn());

      expect(
        tableA.columns[1],
        isReferenceColumn(
          paramName: 'b',
          isList: false,
          linkedTo: tableB,
          references: tableB.columns[1],
        ),
      );

      expect(tableB.columns[0], isIdColumn(name: 'name'));

      expect(
        tableB.columns[1],
        isForeignColumn(
          columnName: 'a_id',
          sqlType: 'text',
          paramName: 'aId',
          isList: false,
          isNullable: false,
          linkedTo: tableA,
          references: tableA.columns[1],
        ),
      );
    });
  });
}
