import 'package:stormberry/internals.dart';
import 'package:test/test.dart';

class Data {
  String a;
  int b;

  Data(this.a, this.b);
}

class DataConverter extends TypeConverter<Data> {
  @override
  dynamic encode(Data value) {
    return {'a': value.a, 'b': value.b};
  }

  @override
  Data decode(dynamic value) {
    return Data(value['a'] as String, value['b'] as int);
  }
}

void main() {
  group('encoding', () {
    late ModelRegistry registry;

    setUpAll(() {
      registry = ModelRegistry({Data: DataConverter()});
    });

    test('properly escapes strings', () async {
      expect(registry.encode('test abc'), equals("'test abc'"));

      expect(registry.encode("te@st 'abc'"), equals("'te@@st ''abc'''"));

      expect(registry.encode(['abc', "test's"]), equals("'{\"abc\",\"test''s\"}'"));

      expect(registry.encode({'a': "test's"}), equals("'{\"a\":\"test''s\"}'"));

      expect(registry.encode(Data("tes@t's", 42)), equals("'{\"a\":\"tes@@t''s\",\"b\":42}'"));

      expect(
        registry.encode([Data("te\nst's", 42)]),
        equals(" E'{\"{\\\\\"a\\\\\":\\\\\"te\\\\\\\\nst''s\\\\\",\\\\\"b\\\\\":42}\"}'"),
      );

      expect(
        registry.encode([Data("t\nest's", 42)]),
        equals(" E'{\"{\\\\\"a\\\\\":\\\\\"t\\\\\\\\nest''s\\\\\",\\\\\"b\\\\\":42}\"}'"),
      );
    });
  });
}
