import 'dart:io';

import 'package:stormberry/stormberry.dart';
import 'package:test/test.dart';

@Model()
abstract class User {
  @PrimaryKey()
  String get id;

  String get name;
}

@Model(views: [View('SuperSecret')])
abstract class Account {
  @PrimaryKey()
  String get id;
}

@Model(tableName: 'customTableName')
abstract class LegacyAccount {
  @PrimaryKey()
  String get id;
}

void main() {
  group('generation', () {
    test('generates schemas', () async {
      var proc = await Process.start(
        'dart',
        'run build_runner build --delete-conflicting-outputs'.split(' '),
        workingDirectory: '.',
      );

      proc.stdout.listen((e) => stdout.add(e));

      expect(await proc.exitCode, equals(0));

      var schema = File('test/generation_test.schema.g.dart');

      expect(schema.existsSync(), equals(true));
    }, timeout: Timeout(Duration(seconds: 60)));

    test('Test custom table name generated code', () async {
      final schema = File('test/generation_test.schema.g.dart');
      final content = await schema.readAsString();
      expect(content.contains('String get tableAlias => \'customTableName\';'), equals(true));
    });
  });
}
