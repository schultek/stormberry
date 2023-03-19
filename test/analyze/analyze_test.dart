import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('analyzing builder', () {
    test('analyzes simple model', () async {
      var schema = await analyzeSchema('''
        import 'package:stormberry/stormberry.dart';

        @Model()
        abstract class MyModel {
          @PrimaryKey()
          String get id;
        
          String get data;
          int get number;
        }
      ''');

      expect(schema.tables, hasLength(1));

      var table = schema.tables.values.first;

      expect(table.tableName, equals('my_models'));
      expect(table.repoName, equals('myModels'));

      expect(table.primaryKeyColumn, isNotNull);
      expect(table.primaryKeyColumn!.columnName, equals('id'));

      expect(table.columns, hasLength(3));
      expect(table.views, hasLength(1));
    });

    test('analyzes field columns', () async {
      var schema = await analyzeSchema('''
        import 'package:stormberry/stormberry.dart';

        @Model()
        abstract class MyModel {
          String get myString;
          List<int> get someNumbers;
          double? get randomFloat;
          bool get isEnabled;
          DateTime get howLate;
          PgPoint get whereTo;
        }
      ''');

      expect(schema.tables, hasLength(1));

      var table = schema.tables.values.first;

      expect(table.columns, hasLength(6));

      expect(
        table.columns[0],
        isFieldColumn(
          columnName: 'my_string',
          sqlType: 'text',
          dartType: 'String',
          paramName: 'myString',
          isList: false,
          isNullable: false,
        ),
      );

      expect(
        table.columns[1],
        isFieldColumn(
          columnName: 'some_numbers',
          sqlType: '_int8',
          dartType: 'int',
          paramName: 'someNumbers',
          isList: true,
          isNullable: false,
        ),
      );

      expect(
        table.columns[2],
        isFieldColumn(
          columnName: 'random_float',
          sqlType: 'float8',
          dartType: 'double',
          paramName: 'randomFloat',
          isList: false,
          isNullable: true,
        ),
      );

      expect(
        table.columns[3],
        isFieldColumn(
          columnName: 'is_enabled',
          sqlType: 'boolean',
          dartType: 'bool',
          paramName: 'isEnabled',
          isList: false,
          isNullable: false,
        ),
      );

      expect(
        table.columns[4],
        isFieldColumn(
          columnName: 'how_late',
          sqlType: 'timestamp',
          dartType: 'DateTime',
          paramName: 'howLate',
          isList: false,
          isNullable: false,
        ),
      );

      expect(
        table.columns[5],
        isFieldColumn(
          columnName: 'where_to',
          sqlType: 'point',
          dartType: 'PgPoint',
          paramName: 'whereTo',
          isList: false,
          isNullable: false,
        ),
      );
    });

    test('analyzes default view', () async {
      var schema = await analyzeSchema('''
        import 'package:stormberry/stormberry.dart';

        @Model()
        abstract class MyModel {
          @PrimaryKey()
          String get id;
        }
      ''');

      expect(schema.tables, hasLength(1));

      var table = schema.tables.values.first;

      expect(table.views, hasLength(1));
      expect(table.views.keys.first, equals(''));

      var view = table.views['']!;

      expect(view.isDefaultView, isTrue);
      expect(view.className, equals('MyModelView'));
      expect(view.viewTableName, equals('my_models_view'));
    });
  });
}
