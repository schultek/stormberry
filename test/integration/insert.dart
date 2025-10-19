import 'package:stormberry/stormberry.dart';
import 'package:test/test.dart';

import '../config/tester.dart';
import 'model.dart';

void testInsert() {
  group('insert', () {
    var tester = useTester(schema: 'integration/*', cleanup: true);

    test('single object', () async {
      await tester.db.as.insertOne(
        AInsertRequest(
          id: 'abc',
          a: 'hello',
          b: 1,
          c: 0.1,
          d: true,
          e: [-2, 1234],
          f: [-0.5, 1.111, 123.45],
        ),
      );

      var as = await tester.db.as.queryAs();

      expect(as, hasLength(1));
      expect(as.first, predicate<AView>((a) => a.id == 'abc' && a.a == 'hello'));
    });

    test('multiple objects', () async {
      await tester.db.as.insertMany([
        AInsertRequest(
          id: 'abc',
          a: 'hello',
          b: 1,
          c: 0.1,
          d: true,
          e: [-2, 1234],
          f: [-0.5, 1.111, 123.45],
        ),
        AInsertRequest(
          id: 'def',
          a: 'world',
          b: 2,
          c: 0.2,
          d: false,
          e: [-3, 10000],
          f: [0.0001, 999.999],
        ),
      ]);

      var as = await tester.db.as.queryAs(QueryParams(orderBy: 'id'));

      expect(as, hasLength(2));
      expect(as.first, predicate<AView>((a) => a.id == 'abc' && a.a == 'hello'));
      expect(as.last, predicate<AView>((a) => a.id == 'def' && a.a == 'world'));
    });

    test('with many-to-many relation', () async {
      await tester.db.cs.insertOne(CInsertRequest(id: 'c1'));
      await tester.db.ds.insertOne(DInsertRequest(id: 'd1', csIds: ['c1']));
      await tester.db.ds.insertOne(DInsertRequest(id: 'd2', csIds: ['c1']));

      var cs = await tester.db.cs.queryFullViews();

      expect(cs, hasLength(1));
      expect(cs.first.ds, hasLength(2));

      var ds = await tester.db.ds.queryFullViews();

      expect(ds, hasLength(2));
      expect(ds.firstWhere((d) => d.id == 'd1').cs, hasLength(1));
      expect(ds.firstWhere((d) => d.id == 'd2').cs, hasLength(1));
    });
  });
}
