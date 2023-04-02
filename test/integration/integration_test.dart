import 'package:stormberry/stormberry.dart';
import 'package:test/test.dart';

import '../config/docker.dart';
import '../config/tester.dart';
import 'model.dart';

void main() {
  usePostgresDocker();
  testInserts();
}

void testInserts() {
  group('integration', () {
    var tester = useTester(schema: 'integration/*', cleanup: true);

    test('insert single object', () async {
      await tester.db.authors
          .insertOne(AuthorInsertRequest(id: 'abc', name: 'Alice', verified: false));

      var authors = await tester.db.authors.queryAuthors();

      expect(authors, hasLength(1));
      expect(authors.first, predicate<AuthorView>((a) => a.id == 'abc' && a.name == 'Alice'));
    });

    test('insert multiple objects', () async {
      await tester.db.authors.insertMany([
        AuthorInsertRequest(id: 'abc', name: 'Alice', verified: false),
        AuthorInsertRequest(id: 'def', name: 'Bob', verified: true)
      ]);

      var authors = await tester.db.authors.queryAuthors(QueryParams(orderBy: 'id'));

      expect(authors, hasLength(2));
      expect(authors.first, predicate<AuthorView>((a) => a.id == 'abc' && a.name == 'Alice'));
      expect(authors.last, predicate<AuthorView>((a) => a.id == 'def' && a.name == 'Bob'));
    });

    test('updates single object', () async {
      await tester.db.authors.insertMany([
        AuthorInsertRequest(id: 'abc', name: 'Alice', verified: false),
        AuthorInsertRequest(id: 'def', name: 'Bob', verified: true)
      ]);

      await tester.db.authors
          .updateOne(AuthorUpdateRequest(id: 'abc', name: 'Alex', verified: true));
      await tester.db.authors.updateMany([]);

      var authors = await tester.db.authors.queryAuthors(QueryParams(orderBy: 'id'));

      expect(authors, hasLength(2));
      expect(authors.first, predicate<AuthorView>((a) => a.id == 'abc' && a.name == 'Alex'));
      expect(authors.last, predicate<AuthorView>((a) => a.id == 'def' && a.name == 'Bob'));
    });

    test('delete single object', () async {
      await tester.db.authors.insertMany([
        AuthorInsertRequest(id: 'abc', name: 'Alice', verified: false),
        AuthorInsertRequest(id: 'def', name: 'Bob', verified: true)
      ]);

      await tester.db.authors.deleteOne('abc');
      await tester.db.authors.deleteMany([]);

      var authors = await tester.db.authors.queryAuthors();

      expect(authors, hasLength(1));
      expect(authors.last, predicate<AuthorView>((a) => a.id == 'def' && a.name == 'Bob'));
    });
  });
}
