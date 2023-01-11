part of 'model.dart';

extension ModelRepositories on Database {
  ARepository get as => ARepository._(this);
  BRepository get bs => BRepository._(this);
}

abstract class ARepository
    implements
        ModelRepository,
        ModelRepositoryInsert<AInsertRequest>,
        ModelRepositoryUpdate<AUpdateRequest>,
        ModelRepositoryDelete<String> {
  factory ARepository._(Database db) = _ARepository;

  Future<A?> queryA(String id);
  Future<List<A>> queryAs([QueryParams? params]);
}

class _ARepository extends BaseRepository
    with RepositoryInsertMixin<AInsertRequest>, RepositoryUpdateMixin<AUpdateRequest>, RepositoryDeleteMixin<String>
    implements ARepository {
  _ARepository(super.db) : super(tableName: 'as', keyName: 'id');

  @override
  Future<A?> queryA(String id) {
    return queryOne(id, AQueryable());
  }

  @override
  Future<List<A>> queryAs([QueryParams? params]) {
    return queryMany(AQueryable(), params);
  }

  @override
  Future<void> insert(List<AInsertRequest> requests) async {
    if (requests.isEmpty) return;

    var values = QueryValues();
    await db.query(
      'INSERT INTO "as" ( "id", "b_id" )\n'
      'VALUES ${requests.map((r) => '( ${values.add(r.id)}, ${values.add(r.bId)} )').join(', ')}\n',
      values.values,
    );
  }

  @override
  Future<void> update(List<AUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    var values = QueryValues();
    await db.query(
      'UPDATE "as"\n'
      'SET "b_id" = COALESCE(UPDATED."b_id"::text, "as"."b_id")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${values.add(r.id)}, ${values.add(r.bId)} )').join(', ')} )\n'
      'AS UPDATED("id", "b_id")\n'
      'WHERE "as"."id" = UPDATED."id"',
      values.values,
    );
  }
}

abstract class BRepository
    implements
        ModelRepository,
        ModelRepositoryInsert<BInsertRequest>,
        ModelRepositoryUpdate<BUpdateRequest>,
        ModelRepositoryDelete<String> {
  factory BRepository._(Database db) = _BRepository;

  Future<B?> queryB(String id);
  Future<List<B>> queryBs([QueryParams? params]);
}

class _BRepository extends BaseRepository
    with RepositoryInsertMixin<BInsertRequest>, RepositoryUpdateMixin<BUpdateRequest>, RepositoryDeleteMixin<String>
    implements BRepository {
  _BRepository(super.db) : super(tableName: 'bs', keyName: 'id');

  @override
  Future<B?> queryB(String id) {
    return queryOne(id, BQueryable());
  }

  @override
  Future<List<B>> queryBs([QueryParams? params]) {
    return queryMany(BQueryable(), params);
  }

  @override
  Future<void> insert(List<BInsertRequest> requests) async {
    if (requests.isEmpty) return;

    var values = QueryValues();
    await db.query(
      'INSERT INTO "bs" ( "a_id", "id" )\n'
      'VALUES ${requests.map((r) => '( ${values.add(r.aId)}, ${values.add(r.id)} )').join(', ')}\n',
      values.values,
    );
  }

  @override
  Future<void> update(List<BUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    var values = QueryValues();
    await db.query(
      'UPDATE "bs"\n'
      'SET "a_id" = COALESCE(UPDATED."a_id"::text, "bs"."a_id")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${values.add(r.aId)}, ${values.add(r.id)} )').join(', ')} )\n'
      'AS UPDATED("a_id", "id")\n'
      'WHERE "bs"."id" = UPDATED."id"',
      values.values,
    );
  }
}

class AInsertRequest {
  AInsertRequest({
    required this.id,
    required this.bId,
  });

  String id;
  String bId;
}

class BInsertRequest {
  BInsertRequest({
    this.aId,
    required this.id,
  });

  String? aId;
  String id;
}

class AUpdateRequest {
  AUpdateRequest({
    required this.id,
    this.bId,
  });

  String id;
  String? bId;
}

class BUpdateRequest {
  BUpdateRequest({
    this.aId,
    required this.id,
  });

  String? aId;
  String id;
}

class AQueryable extends KeyedViewQueryable<A, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => TextEncoder.i.encode(key);

  @override
  String get query => 'SELECT "as".*, row_to_json("b".*) as "b"'
      'FROM "as"'
      'LEFT JOIN (${BQueryable().query}) "b"'
      'ON "as"."b_id" = "b"."id"';

  @override
  String get tableAlias => 'as';

  @override
  A decode(TypedMap map) => AView(id: map.get('id', TextEncoder.i.decode), b: map.get('b', BQueryable().decoder));
}

class AView implements A {
  AView({
    required this.id,
    required this.b,
  });

  @override
  final String id;
  @override
  final B b;
}

class BQueryable extends KeyedViewQueryable<B, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => TextEncoder.i.encode(key);

  @override
  String get query => 'SELECT "bs".*, row_to_json("a".*) as "a"'
      'FROM "bs"'
      'LEFT JOIN (${AQueryable().query}) "a"'
      'ON "bs"."a_id" = "a"."id"';

  @override
  String get tableAlias => 'bs';

  @override
  B decode(TypedMap map) => BView(a: map.getOpt('a', AQueryable().decoder), id: map.get('id', TextEncoder.i.decode));
}

class BView implements B {
  BView({
    this.a,
    required this.id,
  });

  @override
  final A? a;
  @override
  final String id;
}
