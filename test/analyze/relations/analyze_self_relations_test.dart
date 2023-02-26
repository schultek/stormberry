import 'package:test/test.dart';

import '../../utils.dart';

void main() {
  group('analyzing builder', () {
    test('analyzes self one-to-many relation', () async {
      var schema = await analyzeSchema('''
        import 'package:stormberry/stormberry.dart';

        @Model()
        abstract class A {
          @PrimaryKey()
          String get id;
        
          A? get a;
        }
      ''');

      expect(schema.tables, hasLength(1));
      expect(schema.joinTables, isEmpty);

      var table = schema.tables.values.first;

      expect(table.tableName, equals('as'));
      expect(table.columns, hasLength(3));

      expect(table.columns[0], isIdColumn());

      expect(
        table.columns[1],
        isForeignColumn(
          columnName: 'a_id',
          sqlType: 'text',
          paramName: 'aId',
          isList: false,
          isNullable: true,
          linkedTo: table,
          references: table.columns[2],
        ),
      );

      expect(
        table.columns[2],
        isReferenceColumn(
          paramName: '',
          isList: true,
          linkedTo: table,
          references: table.columns[1],
        ),
      );
    });

    test('analyzes self many-to-one relation', () async {
      var schema = await analyzeSchema('''
        import 'package:stormberry/stormberry.dart';

        @Model()
        abstract class A {
          @PrimaryKey()
          String get id;
        
          List<A> get a;
        }
      ''');

      expect(schema.tables, hasLength(1));
      expect(schema.joinTables, isEmpty);

      var table = schema.tables.values.first;

      expect(table.tableName, equals('as'));
      expect(table.columns, hasLength(3));

      expect(table.columns[0], isIdColumn());

      expect(
        table.columns[1],
        isReferenceColumn(
          paramName: 'a',
          isList: true,
          linkedTo: table,
          references: table.columns[2],
        ),
      );

      expect(
        table.columns[2],
        isForeignColumn(
          columnName: 'a_id',
          sqlType: 'text',
          paramName: 'aId',
          isList: false,
          isNullable: true,
          linkedTo: table,
          references: table.columns[1],
        ),
      );
    });

    test('analyzes self multi many-to-one relation', () async {
      var schema = await analyzeSchema('''
        import 'package:stormberry/stormberry.dart';

        @Model()
        abstract class A {
          @PrimaryKey()
          String get id;
        
          A? get a;
          A? get b;
        }
      ''');

      expect(schema.tables, hasLength(1));
      expect(schema.joinTables, isEmpty);

      var table = schema.tables.values.first;

      expect(table.tableName, equals('as'));
      expect(table.columns, hasLength(5));

      expect(table.columns[0], isIdColumn());

      expect(
        table.columns[1],
        isForeignColumn(
          columnName: 'a_id',
          sqlType: 'text',
          isNullable: true,
          paramName: 'aId',
          isList: false,
          linkedTo: table,
          references: table.columns[3],
        ),
      );

      expect(
        table.columns[2],
        isForeignColumn(
          columnName: 'b_id',
          sqlType: 'text',
          isNullable: true,
          paramName: 'bId',
          isList: false,
          linkedTo: table,
          references: table.columns[4],
        ),
      );

      expect(
        table.columns[3],
        isReferenceColumn(
          paramName: '',
          isList: true,
          linkedTo: table,
          references: table.columns[1],
        ),
      );

      expect(
        table.columns[4],
        isReferenceColumn(
          paramName: '',
          isList: true,
          linkedTo: table,
          references: table.columns[2],
        ),
      );
    });
  });
}
