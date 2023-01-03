part of 'model.dart';

extension Repositories on Database {
  ARepository get as => ARepository._(this);
  BRepository get bs => BRepository._(this);
}

final registry = ModelRegistry();

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
  _ARepository(Database db) : super(db: db);

  @override
  Future<A?> queryA(String id) {
    return queryOne(id, AQueryable());
  }

  @override
  Future<List<A>> queryAs([QueryParams? params]) {
    return queryMany(AQueryable(), params);
  }

  @override
  Future<void> insert(Database db, List<AInsertRequest> requests) async {
    if (requests.isEmpty) return;

    await db.query(
      'INSERT INTO "as" ( "id", "b_id" )\n'
      'VALUES ${requests.map((r) => '( ${registry.encode(r.id)}, ${registry.encode(r.bId)} )').join(', ')}\n'
      'ON CONFLICT ( "id" ) DO UPDATE SET "b_id" = EXCLUDED."b_id"',
    );
  }

  @override
  Future<void> update(Database db, List<AUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query(
      'UPDATE "as"\n'
      'SET "b_id" = COALESCE(UPDATED."b_id"::text, "as"."b_id")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${registry.encode(r.id)}, ${registry.encode(r.bId)} )').join(', ')} )\n'
      'AS UPDATED("id", "b_id")\n'
      'WHERE "as"."id" = UPDATED."id"',
    );
  }

  @override
  Future<void> delete(Database db, List<String> keys) async {
    if (keys.isEmpty) return;
    await db.query(
      'DELETE FROM "as"\n'
      'WHERE "as"."id" IN ( ${keys.map((k) => registry.encode(k)).join(',')} )',
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
  _BRepository(Database db) : super(db: db);

  @override
  Future<B?> queryB(String id) {
    return queryOne(id, BQueryable());
  }

  @override
  Future<List<B>> queryBs([QueryParams? params]) {
    return queryMany(BQueryable(), params);
  }

  @override
  Future<void> insert(Database db, List<BInsertRequest> requests) async {
    if (requests.isEmpty) return;

    await db.query(
      'INSERT INTO "bs" ( "a_id", "id" )\n'
      'VALUES ${requests.map((r) => '( ${registry.encode(r.aId)}, ${registry.encode(r.id)} )').join(', ')}\n'
      'ON CONFLICT ( "id" ) DO UPDATE SET "a_id" = EXCLUDED."a_id"',
    );
  }

  @override
  Future<void> update(Database db, List<BUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query(
      'UPDATE "bs"\n'
      'SET "a_id" = COALESCE(UPDATED."a_id"::text, "bs"."a_id")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${registry.encode(r.aId)}, ${registry.encode(r.id)} )').join(', ')} )\n'
      'AS UPDATED("a_id", "id")\n'
      'WHERE "bs"."id" = UPDATED."id"',
    );
  }

  @override
  Future<void> delete(Database db, List<String> keys) async {
    if (keys.isEmpty) return;
    await db.query(
      'DELETE FROM "bs"\n'
      'WHERE "bs"."id" IN ( ${keys.map((k) => registry.encode(k)).join(',')} )',
    );
  }
}

class AInsertRequest {
  AInsertRequest({required this.id, required this.bId});
  String id;
  String bId;
}

class BInsertRequest {
  BInsertRequest({this.aId, required this.id});
  String? aId;
  String id;
}

class AUpdateRequest {
  AUpdateRequest({required this.id, this.bId});
  String id;
  String? bId;
}

class BUpdateRequest {
  BUpdateRequest({this.aId, required this.id});
  String? aId;
  String id;
}

class AQueryable extends KeyedViewQueryable<A, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => registry.encode(key);

  @override
  String get tableName => 'as_view';

  @override
  String get tableAlias => 'as';

  @override
  A decode(TypedMap map) => AView(id: map.get('id', registry.decode), b: map.get('b', BQueryable().decoder));
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
  String encodeKey(String key) => registry.encode(key);

  @override
  String get tableName => 'bs_view';

  @override
  String get tableAlias => 'bs';

  @override
  B decode(TypedMap map) => BView(a: map.getOpt('a', AQueryable().decoder), id: map.get('id', registry.decode));
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
