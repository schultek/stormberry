import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('analyzing builder', () {
    test('analyzes one-sided double-keyed many-to-one relation', () async {
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
          isList: true,
          linkedTo: tableB,
          references: tableB.columns[1],
        ),
      );

      expect(tableB.columns[0], isIdColumn());

      expect(
        tableB.columns[1],
        isForeignColumn(
          columnName: 'a_id',
          sqlType: 'text',
          paramName: 'aId',
          isList: false,
          isNullable: true,
          linkedTo: tableA,
          references: tableA.columns[1],
        ),
      );
    });

    test('analyzes one-sided single-keyed many-to-one relation', () async {
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
          isList: true,
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

    test('analyzes two-sided double-keyed many-to-one relation', () async {
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
          isList: true,
          linkedTo: tableB,
          references: tableB.columns[1],
        ),
      );

      expect(tableB.columns[0], isIdColumn());

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

    test('analyzes two-sided single-keyed many-to-one relation', () async {
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

      expect(tableA.columns[0], isIdColumn());

      expect(
        tableA.columns[1],
        isReferenceColumn(
          paramName: 'b',
          isList: true,
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
