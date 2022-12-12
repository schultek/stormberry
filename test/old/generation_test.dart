import 'dart:io';

import 'package:stormberry/stormberry.dart';
import 'package:test/test.dart';
import 'generation_test.schema.g.dart';

enum EnumValue { one, two, three }

enum CustomEnumValue { one, two, three }

@TypeConverter('int8')
class CustomEnumConverter extends TypeConverter<CustomEnumValue> {
  @override
  dynamic encode(CustomEnumValue value) {
    return value.index;
  }

  @override
  CustomEnumValue decode(dynamic value) {
    return CustomEnumValue.values[value as int];
  }
}

@Model()
abstract class User {
  @PrimaryKey()
  String get id;

  String get name;
  Account get account;
  EnumValue get enumValue;
  CustomEnumValue get customEnumValue;
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

    test('Test Default Enum Value Serialized Correctly', () async {
      expect(registry.convert(EnumValue.one), equals('one'));
      expect(registry.decode<EnumValue>('one'), equals(EnumValue.one));
    });

    test('Test Custom Enum Value Serialized Correctly', () async {
      expect(registry.convert(CustomEnumValue.one), equals(0));
      expect(registry.decode<CustomEnumValue>(0), equals(CustomEnumValue.one));
    });
  });
}
