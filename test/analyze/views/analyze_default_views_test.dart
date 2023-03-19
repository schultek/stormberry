import 'package:test/test.dart';

import '../../utils.dart';

void main() {
  group('analyzing builder', () {
    test('analyzes one-sided double-keyed implicit default view', () async {
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

      expect(
        viewA.columns[0],
        isViewColumn(
          paramName: 'id',
          dartType: 'String',
          isNullable: false,
          transformer: null,
          viewAs: null,
        ),
      );

      expect(
        viewA.columns[1],
        isViewColumn(
          paramName: 'b',
          dartType: 'B',
          isNullable: false,
          transformer: null,
          viewAs: null,
        ),
      );
    });

    test('analyzes one-sided double-keyed explicit default view', () async {
      var schema = await analyzeSchema('''
        import 'package:stormberry/stormberry.dart';

        @Model(views: [Model.defaultView])
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

      expect(
        viewA.columns[0],
        isViewColumn(
          paramName: 'id',
          dartType: 'String',
          isNullable: false,
          transformer: null,
          viewAs: null,
        ),
      );

      expect(
        viewA.columns[1],
        isViewColumn(
          paramName: 'b',
          dartType: 'B',
          isNullable: false,
          transformer: null,
          viewAs: null,
        ),
      );
    });

    test('analyzes modified default view', () async {
      var schema = await analyzeSchema('''
        import 'package:stormberry/stormberry.dart';

        @Model()
        abstract class A {
          @PrimaryKey()
          String get id;
        
          @HiddenIn(Model.defaultView)
          String get securityNumber;
        }
      ''');

      expect(schema.tables, hasLength(1));
      expect(schema.joinTables, isEmpty);

      var tableA = schema.tables.values.first;

      expect(tableA.tableName, equals('as'));

      expect(tableA.views, hasLength(1));
      expect(tableA.views.keys.first, equals(''));

      var viewA = tableA.views['']!;

      expect(viewA.columns, hasLength(1));

      expect(
        viewA.columns[0],
        isViewColumn(
          paramName: 'id',
          dartType: 'String',
          isNullable: false,
          transformer: null,
          viewAs: null,
        ),
      );
    });
  });
}
