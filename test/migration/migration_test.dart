import 'package:test/test.dart';

import '../config/docker.dart';
import '../config/tester.dart';

void main() {
  usePostgresDocker();
  testMigrations();
}

void testMigrations() {
  group('migration', () {
    var tester = useTester(cleanup: true);

    test('added column', () async {
      var diff1 = await tester.db.migrateTo('migration/schemas/schema_1');

      expect(diff1.existingSchema.tables, isEmpty);
      expect(diff1.newSchema.tables, hasLength(2));

      var diff2 = await tester.db.migrateTo('migration/schemas/schema_2');

      expect(diff2.tables.added, isEmpty);
      expect(diff2.tables.removed, isEmpty);
      expect(diff2.tables.modified, hasLength(1));
      expect(diff2.tables.modified.first.name, equals('books'));

      var diff2Cols = diff2.tables.modified.first.columns;

      expect(diff2Cols.removed, isEmpty);
      expect(diff2Cols.modified, isEmpty);
      expect(diff2Cols.added, hasLength(1));
      expect(diff2Cols.added.first.name, equals('rating'));

      var diff2Idx = diff2.tables.modified.first.indexes;

      expect(diff2Idx.removed, isEmpty);
      expect(diff2Idx.modified, isEmpty);
      expect(diff2Idx.added, hasLength(1));
      expect(diff2Idx.added.first.name, equals('rating_index'));
    });
  });
}
