import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('multi-schema', () {
    test('generates schemas', () async {
      var proc = await Process.start(
        'dart',
        'run build_runner build --delete-conflicting-outputs'.split(' '),
        workingDirectory: 'test/packages/multi_schema',
      );

      proc.stdout.listen((e) => stdout.add(e));

      expect(await proc.exitCode, equals(0));

      var schemaA = File('test/packages/multi_schema/lib/modelsA.schema.g.dart');
      var schemaB = File('test/packages/multi_schema/lib/modelsB.schema.g.dart');

      expect(schemaA.existsSync(), equals(true));
      expect(schemaB.existsSync(), equals(true));
    }, timeout: Timeout(Duration(seconds: 60)));

    test('Migrating schemas', () async {
      var proc = await Process.start(
        'dart',
        'run stormberry migrate --apply-changes'.split(' '),
        workingDirectory: 'test/packages/multi_schema',
        environment: {
          'DB_HOST': 'localhost',
          'DB_PORT': '2222',
          'DB_NAME': 'dart_test',
          'DB_USERNAME': 'postgres',
          'DB_PASSWORD': 'postgres',
          'DB_SSL': 'false',
        },
      );

      proc.stdout.listen((e) => stdout.add(e));

      expect(await proc.exitCode, equals(0));
    }, timeout: Timeout(Duration(seconds: 60)));
  });
}
