part of 'party.dart';

extension Repositories on Database {
  PartyRepository get parties => PartyRepository._(this);
}

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
      'INSERT INTO "parties" ( "sponsor_id", "id", "name", "date" )\n'
      'VALUES ${requests.map((r) => '( ${TypeEncoder.i.encode(r.sponsorId)}, ${TypeEncoder.i.encode(r.id)}, ${TypeEncoder.i.encode(r.name)}, ${TypeEncoder.i.encode(r.date)} )').join(', ')}\n'
      'ON CONFLICT ( "id" ) DO UPDATE SET "sponsor_id" = EXCLUDED."sponsor_id", "name" = EXCLUDED."name", "date" = EXCLUDED."date"',
    );
  }

  @override
  Future<void> update(Database db, List<PartyUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query(
      'UPDATE "parties"\n'
      'SET "sponsor_id" = COALESCE(UPDATED."sponsor_id"::text, "parties"."sponsor_id"), "name" = COALESCE(UPDATED."name"::text, "parties"."name"), "date" = COALESCE(UPDATED."date"::int8, "parties"."date")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${TypeEncoder.i.encode(r.sponsorId)}, ${TypeEncoder.i.encode(r.id)}, ${TypeEncoder.i.encode(r.name)}, ${TypeEncoder.i.encode(r.date)} )').join(', ')} )\n'
      'AS UPDATED("sponsor_id", "id", "name", "date")\n'
      'WHERE "parties"."id" = UPDATED."id"',
    );
  }

  @override
  Future<void> delete(Database db, List<String> keys) async {
    if (keys.isEmpty) return;
    await db.query(
      'DELETE FROM "parties"\n'
      'WHERE "parties"."id" IN ( ${keys.map((k) => TypeEncoder.i.encode(k)).join(',')} )',
    );
  }
}

class PartyInsertRequest {
  PartyInsertRequest({this.sponsorId, required this.id, required this.name, required this.date});
  String? sponsorId;
  String id;
  String name;
  int date;
}

class PartyUpdateRequest {
  PartyUpdateRequest({this.sponsorId, required this.id, this.name, this.date});
  String? sponsorId;
  String id;
  String? name;
  int? date;
}

class GuestPartyViewQueryable extends KeyedViewQueryable<GuestPartyView, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => TypeEncoder.i.encode(key);

  @override
  String get tableName => 'guest_parties_view';

  @override
  String get tableAlias => 'parties';

  @override
  GuestPartyView decode(TypedMap map) => GuestPartyView(
      sponsor: map.getOpt('sponsor', MemberCompanyViewQueryable().decoder),
      id: map.get('id', TypeEncoder.i.decode),
      name: map.get('name', TypeEncoder.i.decode),
      date: map.get('date', TypeEncoder.i.decode));
}

class GuestPartyView {
  GuestPartyView({
    this.sponsor,
    required this.id,
    required this.name,
    required this.date,
  });

  final MemberCompanyView? sponsor;
  final String id;
  final String name;
  final int date;
}

class CompanyPartyViewQueryable extends KeyedViewQueryable<CompanyPartyView, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => TypeEncoder.i.encode(key);

  @override
  String get tableName => 'company_parties_view';

  @override
  String get tableAlias => 'parties';

  @override
  CompanyPartyView decode(TypedMap map) => CompanyPartyView(
      id: map.get('id', TypeEncoder.i.decode),
      name: map.get('name', TypeEncoder.i.decode),
      date: map.get('date', TypeEncoder.i.decode));
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
