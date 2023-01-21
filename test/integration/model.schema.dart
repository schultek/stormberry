part of 'model.dart';

extension ModelRepositories on Database {
  AuthorRepository get authors => AuthorRepository._(this);
  BookRepository get books => BookRepository._(this);
}

abstract class AuthorRepository
    implements
        ModelRepository,
        ModelRepositoryInsert<AuthorInsertRequest>,
        ModelRepositoryUpdate<AuthorUpdateRequest>,
        ModelRepositoryDelete<String> {
  factory AuthorRepository._(Database db) = _AuthorRepository;

  Future<Author?> queryAuthor(String id);
  Future<List<Author>> queryAuthors([QueryParams? params]);
}

class _AuthorRepository extends BaseRepository
    with
        RepositoryInsertMixin<AuthorInsertRequest>,
        RepositoryUpdateMixin<AuthorUpdateRequest>,
        RepositoryDeleteMixin<String>
    implements AuthorRepository {
  _AuthorRepository(super.db) : super(tableName: 'authors', keyName: 'id');

  @override
  Future<Author?> queryAuthor(String id) {
    return queryOne(id, AuthorQueryable());
  }

  @override
  Future<List<Author>> queryAuthors([QueryParams? params]) {
    return queryMany(AuthorQueryable(), params);
  }

  @override
  Future<void> insert(List<AuthorInsertRequest> requests) async {
    if (requests.isEmpty) return;

    var values = QueryValues();
    await db.query(
      'INSERT INTO "authors" ( "id", "name" )\n'
      'VALUES ${requests.map((r) => '( ${values.add(r.id)}, ${values.add(r.name)} )').join(', ')}\n',
      values.values,
    );
  }

  @override
  Future<void> update(List<AuthorUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    var values = QueryValues();
    await db.query(
      'UPDATE "authors"\n'
      'SET "name" = COALESCE(UPDATED."name"::text, "authors"."name")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${values.add(r.id)}, ${values.add(r.name)} )').join(', ')} )\n'
      'AS UPDATED("id", "name")\n'
      'WHERE "authors"."id" = UPDATED."id"',
      values.values,
    );
  }
}

abstract class BookRepository
    implements
        ModelRepository,
        ModelRepositoryInsert<BookInsertRequest>,
        ModelRepositoryUpdate<BookUpdateRequest>,
        ModelRepositoryDelete<String> {
  factory BookRepository._(Database db) = _BookRepository;

  Future<Book?> queryBook(String id);
  Future<List<Book>> queryBooks([QueryParams? params]);
}

class _BookRepository extends BaseRepository
    with
        RepositoryInsertMixin<BookInsertRequest>,
        RepositoryUpdateMixin<BookUpdateRequest>,
        RepositoryDeleteMixin<String>
    implements BookRepository {
  _BookRepository(super.db) : super(tableName: 'books', keyName: 'id');

  @override
  Future<Book?> queryBook(String id) {
    return queryOne(id, BookQueryable());
  }

  @override
  Future<List<Book>> queryBooks([QueryParams? params]) {
    return queryMany(BookQueryable(), params);
  }

  @override
  Future<void> insert(List<BookInsertRequest> requests) async {
    if (requests.isEmpty) return;

    var values = QueryValues();
    await db.query(
      'INSERT INTO "books" ( "id", "title", "author_id" )\n'
      'VALUES ${requests.map((r) => '( ${values.add(r.id)}, ${values.add(r.title)}, ${values.add(r.authorId)} )').join(', ')}\n',
      values.values,
    );
  }

  @override
  Future<void> update(List<BookUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    var values = QueryValues();
    await db.query(
      'UPDATE "books"\n'
      'SET "title" = COALESCE(UPDATED."title"::text, "books"."title"), "author_id" = COALESCE(UPDATED."author_id"::text, "books"."author_id")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${values.add(r.id)}, ${values.add(r.title)}, ${values.add(r.authorId)} )').join(', ')} )\n'
      'AS UPDATED("id", "title", "author_id")\n'
      'WHERE "books"."id" = UPDATED."id"',
      values.values,
    );
  }
}

class AuthorInsertRequest {
  AuthorInsertRequest({
    required this.id,
    required this.name,
  });

  String id;
  String name;
}

class BookInsertRequest {
  BookInsertRequest({
    required this.id,
    required this.title,
    required this.authorId,
  });

  String id;
  String title;
  String authorId;
}

class AuthorUpdateRequest {
  AuthorUpdateRequest({
    required this.id,
    this.name,
  });

  String id;
  String? name;
}

class BookUpdateRequest {
  BookUpdateRequest({
    required this.id,
    this.title,
    this.authorId,
  });

  String id;
  String? title;
  String? authorId;
}

class AuthorQueryable extends KeyedViewQueryable<Author, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => TextEncoder.i.encode(key);

  @override
  String get query => 'SELECT "authors".*'
      'FROM "authors"';

  @override
  String get tableAlias => 'authors';

  @override
  Author decode(TypedMap map) => AuthorView(id: map.get('id'), name: map.get('name'));
}

class AuthorView with Author {
  AuthorView({
    required this.id,
    required this.name,
  });

  @override
  final String id;
  @override
  final String name;
}

class BookQueryable extends KeyedViewQueryable<Book, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => TextEncoder.i.encode(key);

  @override
  String get query => 'SELECT "books".*, row_to_json("author".*) as "author"'
      'FROM "books"'
      'LEFT JOIN (${AuthorQueryable().query}) "author"'
      'ON "books"."author_id" = "author"."id"';

  @override
  String get tableAlias => 'books';

  @override
  Book decode(TypedMap map) => BookView(
      id: map.get('id'),
      title: map.get('title'),
      author: map.get('author', AuthorQueryable().decoder));
}

class BookView with Book {
  BookView({
    required this.id,
    required this.title,
    required this.author,
  });

  @override
  final String id;
  @override
  final String title;
  @override
  final Author author;
}
