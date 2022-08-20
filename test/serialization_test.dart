import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('serialization', () {
    test('generates outputs', () async {
      var proc = await Process.start(
        'dart',
        'run build_runner build --delete-conflicting-outputs'.split(' '),
        workingDirectory: 'test/packages/serialization',
      );

      expect(await proc.exitCode, equals(0));

      var schema = File('test/packages/serialization/lib/models.schema.g.dart');
      var mapper = File('test/packages/serialization/lib/models.mapper.g.dart');

      expect(schema.existsSync(), equals(true));
      expect(mapper.existsSync(), equals(true));
    }, timeout: Timeout(Duration(seconds: 60)));

    test('serialize models', () async {

      var proc = await Process.start(
        'dart',
        'run lib/main.dart'.split(' '),
        workingDirectory: 'test/packages/serialization',
      );

      var output = await proc.stdout.map((e) => utf8.decode(e)).fold<String>('', (s, e) => s + e);

      var lines = output.split('\n');

      expect(lines, hasLength(5));

      expect(lines[0], equals('{"id":"abc","name":"Tom","securityNumber":"12345"}'));
      expect(lines[1], equals('DefaultUserView(id: abc, name: Alex, securityNumber: 12345)'));
      expect(lines[2], equals('{"id":"01","member":{"id":"def","name":"Susan"}}'));
      expect(lines[3], equals('{"companyId":null,"id":"abc","name":null,"securityNumber":"007"}'));
      expect(lines[4], equals(''));

    }, timeout: Timeout(Duration(seconds: 60)));
  });
}
