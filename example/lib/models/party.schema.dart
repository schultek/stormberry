part of 'party.dart';

extension PartyRepositories on Database {
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
  _PartyRepository(super.db) : super(tableName: 'parties', keyName: 'id');

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
  Future<void> insert(List<PartyInsertRequest> requests) async {
    if (requests.isEmpty) return;

    var values = QueryValues();
    await db.query(
      'INSERT INTO "parties" ( "sponsor_id", "id", "name", "date" )\n'
      'VALUES ${requests.map((r) => '( ${values.add(r.sponsorId)}, ${values.add(r.id)}, ${values.add(r.name)}, ${values.add(r.date)} )').join(', ')}\n',
      values.values,
    );
  }

  @override
  Future<void> update(List<PartyUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    var values = QueryValues();
    await db.query(
      'UPDATE "parties"\n'
      'SET "sponsor_id" = COALESCE(UPDATED."sponsor_id"::text, "parties"."sponsor_id"), "name" = COALESCE(UPDATED."name"::text, "parties"."name"), "date" = COALESCE(UPDATED."date"::int8, "parties"."date")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${values.add(r.sponsorId)}, ${values.add(r.id)}, ${values.add(r.name)}, ${values.add(r.date)} )').join(', ')} )\n'
      'AS UPDATED("sponsor_id", "id", "name", "date")\n'
      'WHERE "parties"."id" = UPDATED."id"',
      values.values,
    );
  }
}

class PartyInsertRequest {
  PartyInsertRequest({
    this.sponsorId,
    required this.id,
    required this.name,
    required this.date,
  });

  String? sponsorId;
  String id;
  String name;
  int date;
}

class PartyUpdateRequest {
  PartyUpdateRequest({
    this.sponsorId,
    required this.id,
    this.name,
    this.date,
  });

  String? sponsorId;
  String id;
  String? name;
  int? date;
}

class GuestPartyViewQueryable extends KeyedViewQueryable<GuestPartyView, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => TextEncoder.i.encode(key);

  @override
  String get query => 'SELECT "parties".*, row_to_json("sponsor".*) as "sponsor"'
      'FROM "parties"'
      'LEFT JOIN (${MemberCompanyViewQueryable().query}) "sponsor"'
      'ON "parties"."sponsor_id" = "sponsor"."id"';

  @override
  String get tableAlias => 'parties';

  @override
  GuestPartyView decode(TypedMap map) => GuestPartyView(
      sponsor: map.getOpt('sponsor', MemberCompanyViewQueryable().decoder),
      id: map.get('id', TextEncoder.i.decode),
      name: map.get('name', TextEncoder.i.decode),
      date: map.get('date', TextEncoder.i.decode));
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
  String encodeKey(String key) => TextEncoder.i.encode(key);

  @override
  String get query => 'SELECT "parties".*'
      'FROM "parties"';

  @override
  String get tableAlias => 'parties';

  @override
  CompanyPartyView decode(TypedMap map) =>
      CompanyPartyView(id: map.get('id'), name: map.get('name'), date: map.get('date'));
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
