import 'package:test/test.dart';

import '../utils.dart';

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
          double get randomFloat;
          bool get isEnabled;
          DateTime get howLate;
          PgPoint get whereTo;
        }
      ''');

      expect(schema.tables, hasLength(1));

      var table = schema.tables.values.first;

      expect(table.columns, hasLength(6));

      testColumn(
        table.columns[0],
        columnName: 'my_string',
        sqlType: 'text',
        dartType: 'String',
        paramName: 'myString',
        isList: false,
      );
      testColumn(
        table.columns[1],
        columnName: 'some_numbers',
        sqlType: '_int8',
        dartType: 'int',
        paramName: 'someNumbers',
        isList: true,
      );
      testColumn(
        table.columns[2],
        columnName: 'random_float',
        sqlType: 'float8',
        dartType: 'double',
        paramName: 'randomFloat',
        isList: false,
      );
      testColumn(
        table.columns[3],
        columnName: 'is_enabled',
        sqlType: 'bool',
        dartType: 'bool',
        paramName: 'isEnabled',
        isList: false,
      );
      testColumn(
        table.columns[4],
        columnName: 'how_late',
        sqlType: 'timestamp',
        dartType: 'DateTime',
        paramName: 'howLate',
        isList: false,
      );
      testColumn(
        table.columns[5],
        columnName: 'where_to',
        sqlType: 'point',
        dartType: 'PgPoint',
        paramName: 'whereTo',
        isList: false,
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
      expect(view.className,  equals('MyModelView'));
      expect(view.entityName,  equals('MyModel'));
      expect(view.viewName,  equals('MyModel'));
      expect(view.viewTableName, equals('my_models_view'));
    });
  });
}
