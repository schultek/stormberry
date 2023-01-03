part of 'party.dart';

extension Repositories on Database {
  PartyRepository get parties => PartyRepository._(this);
}

final registry = ModelRegistry();

abstract class PartyRepository
    implements
        ModelRepository,
        ModelRepositoryInsert<PartyInsertRequest>,
        ModelRepositoryUpdate<PartyUpdateRequest>,
        ModelRepositoryDelete<String> {
  factory PartyRepository._(Database db) = _PartyRepository;

  Future<GuestPartyView?> queryGuestView(String id);
  Future<List<GuestPartyView>> queryGuestViews([QueryParams? params]);
  Future<CompanyPartyView?> queryCompanyView(String id);
  Future<List<CompanyPartyView>> queryCompanyViews([QueryParams? params]);
}

class _PartyRepository extends BaseRepository
    with
        RepositoryInsertMixin<PartyInsertRequest>,
        RepositoryUpdateMixin<PartyUpdateRequest>,
        RepositoryDeleteMixin<String>
    implements PartyRepository {
  _PartyRepository(Database db) : super(db: db);

  @override
  Future<GuestPartyView?> queryGuestView(String id) {
    return queryOne(id, GuestPartyViewQueryable());
  }

  @override
  Future<List<GuestPartyView>> queryGuestViews([QueryParams? params]) {
    return queryMany(GuestPartyViewQueryable(), params);
  }

  @override
  Future<CompanyPartyView?> queryCompanyView(String id) {
    return queryOne(id, CompanyPartyViewQueryable());
  }

  @override
  Future<List<CompanyPartyView>> queryCompanyViews([QueryParams? params]) {
    return queryMany(CompanyPartyViewQueryable(), params);
  }

  @override
  Future<void> insert(Database db, List<PartyInsertRequest> requests) async {
    if (requests.isEmpty) return;

    await db.query(
      'INSERT INTO "parties" ( "id", "name", "sponsor_id", "date" )\n'
      'VALUES ${requests.map((r) => '( ${registry.encode(r.id)}, ${registry.encode(r.name)}, ${registry.encode(r.sponsorId)}, ${registry.encode(r.date)} )').join(', ')}\n'
      'ON CONFLICT ( "id" ) DO UPDATE SET "name" = EXCLUDED."name", "sponsor_id" = EXCLUDED."sponsor_id", "date" = EXCLUDED."date"',
    );
  }

  @override
  Future<void> update(Database db, List<PartyUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query(
      'UPDATE "parties"\n'
      'SET "name" = COALESCE(UPDATED."name"::text, "parties"."name"), "sponsor_id" = COALESCE(UPDATED."sponsor_id"::text, "parties"."sponsor_id"), "date" = COALESCE(UPDATED."date"::int8, "parties"."date")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${registry.encode(r.id)}, ${registry.encode(r.name)}, ${registry.encode(r.sponsorId)}, ${registry.encode(r.date)} )').join(', ')} )\n'
      'AS UPDATED("id", "name", "sponsor_id", "date")\n'
      'WHERE "parties"."id" = UPDATED."id"',
    );
  }

  @override
  Future<void> delete(Database db, List<String> keys) async {
    if (keys.isEmpty) return;
    await db.query(
      'DELETE FROM "parties"\n'
      'WHERE "parties"."id" IN ( ${keys.map((k) => registry.encode(k)).join(',')} )',
    );
  }
}

class PartyInsertRequest {
  PartyInsertRequest({required this.id, required this.name, this.sponsorId, required this.date});
  String id;
  String name;
  String? sponsorId;
  int date;
}

class PartyUpdateRequest {
  PartyUpdateRequest({required this.id, this.name, this.sponsorId, this.date});
  String id;
  String? name;
  String? sponsorId;
  int? date;
}

class GuestPartyViewQueryable extends KeyedViewQueryable<GuestPartyView, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => registry.encode(key);

  @override
  String get tableName => 'guest_parties_view';

  @override
  String get tableAlias => 'parties';

  @override
  GuestPartyView decode(TypedMap map) => GuestPartyView(
      id: map.get('id', registry.decode),
      name: map.get('name', registry.decode),
      sponsor: map.getOpt('sponsor', MemberCompanyViewQueryable().decoder),
      date: map.get('date', registry.decode));
}

class GuestPartyView {
  GuestPartyView({
    required this.id,
    required this.name,
    this.sponsor,
    required this.date,
  });

  final String id;
  final String name;
  final MemberCompanyView? sponsor;
  final int date;
}

class CompanyPartyViewQueryable extends KeyedViewQueryable<CompanyPartyView, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => registry.encode(key);

  @override
  String get tableName => 'company_parties_view';

  @override
  String get tableAlias => 'parties';

  @override
  CompanyPartyView decode(TypedMap map) => CompanyPartyView(
      id: map.get('id', registry.decode),
      name: map.get('name', registry.decode),
      date: map.get('date', registry.decode));
}

class CompanyPartyView {
  CompanyPartyView({
    required this.id,
    required this.name,
    required this.date,
  });

  final String id;
  final String name;
  final int date;
}
