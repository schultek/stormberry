import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('analyzing builder', () {
    test('analyzes non-modified circular views', () async {
      analyze() => analyzeSchema('''
        import 'package:stormberry/stormberry.dart';

        @Model()
        abstract class A {
          @PrimaryKey()
          String get id;
        
          B? get b;
        }
        
        @Model()
        abstract class B {
          @PrimaryKey()
          String get id;
          
          A? get a;
        }
      ''');

      expect(
        analyze,
        throwsA(
          allOf(
            startsWith('View configuration contains a circular reference'),
            contains('A -(.b)-> B -(.a)-> A'),
          ),
        ),
      );
    });
  });
}
