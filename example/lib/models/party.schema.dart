// ignore_for_file: annotate_overrides

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
      'INSERT INTO "parties" ( "id", "name", "sponsor_id", "date" )\n'
      'VALUES ${requests.map((r) => '( ${values.add(r.id)}:text, ${values.add(r.name)}:text, ${values.add(r.sponsorId)}:text, ${values.add(r.date)}:int8 )').join(', ')}\n',
      values.values,
    );
  }

  @override
  Future<void> update(List<PartyUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    var values = QueryValues();
    await db.query(
      'UPDATE "parties"\n'
      'SET "name" = COALESCE(UPDATED."name", "parties"."name"), "sponsor_id" = COALESCE(UPDATED."sponsor_id", "parties"."sponsor_id"), "date" = COALESCE(UPDATED."date", "parties"."date")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${values.add(r.id)}:text, ${values.add(r.name)}:text, ${values.add(r.sponsorId)}:text, ${values.add(r.date)}:int8 )').join(', ')} )\n'
      'AS UPDATED("id", "name", "sponsor_id", "date")\n'
      'WHERE "parties"."id" = UPDATED."id"',
      values.values,
    );
  }
}

class PartyInsertRequest {
  PartyInsertRequest({
    required this.id,
    required this.name,
    this.sponsorId,
    required this.date,
  });

  final String id;
  final String name;
  final String? sponsorId;
  final int date;
}

class PartyUpdateRequest {
  PartyUpdateRequest({
    required this.id,
    this.name,
    this.sponsorId,
    this.date,
  });

  final String id;
  final String? name;
  final String? sponsorId;
  final int? date;
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
      id: map.get('id'),
      name: map.get('name'),
      sponsor: map.getOpt('sponsor', MemberCompanyViewQueryable().decoder),
      date: map.get('date'));
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
