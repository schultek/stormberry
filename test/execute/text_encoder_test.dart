import 'package:stormberry/stormberry.dart';
import 'package:test/test.dart';

void main() {
  group('model registry', () {
    late TextEncoder registry;

    setUpAll(() {
      registry = TextEncoder();
    });

    test('properly escapes strings', () async {
      expect(registry.encode('test abc'), equals("'test abc'"));

      expect(registry.encode("te@st 'abc'"), equals("'te@st ''abc'''"));

      expect(registry.encode(['abc', "test's"]), equals("'{\"abc\",\"test''s\"}'"));

      expect(registry.encode({'a': "test's"}), equals("'{\"a\":\"test''s\"}'"));

      expect(
        registry.encode([
          {'a': "te\nst's", 'b': 42},
        ]),
        equals(" E'{\"{\\\\\"a\\\\\":\\\\\"te\\\\\\\\nst''s\\\\\",\\\\\"b\\\\\":42}\"}'"),
      );
    });
  });
}
