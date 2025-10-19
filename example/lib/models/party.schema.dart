// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint
// ignore_for_file: annotate_overrides
// dart format off

part of 'party.dart';

extension PartyRepositories on Session {
  PartyRepository get parties => PartyRepository._(this);
}

abstract class PartyRepository
    implements
        ModelRepository,
        ModelRepositoryInsert<PartyInsertRequest>,
        ModelRepositoryUpdate<PartyUpdateRequest>,
        ModelRepositoryDelete<String> {
  factory PartyRepository._(Session db) = _PartyRepository;

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
    await db.execute(
      Sql.named(
        'INSERT INTO "parties" ( "id", "name", "sponsor_id", "date" )\n'
        'VALUES ${requests.map((r) => '( ${values.add(r.id)}:text, ${values.add(r.name)}:text, ${values.add(r.sponsorId)}:text, ${values.add(r.date)}:int8 )').join(', ')}\n',
      ),
      parameters: values.values,
    );

    await _updateGuests([
      for (final r in requests)
        if (r.guestsIds case final guestsIds?)
          (r.id, UpdateValues.set(guestsIds)),
    ]);
  }

  @override
  Future<void> update(List<PartyUpdateRequest> requests) async {
    if (requests.isEmpty) return;

    final updateRequests = [
      for (final r in requests)
        if (r.name != null || r.sponsorId != null || r.date != null) r,
    ];

    if (updateRequests.isNotEmpty) {
      var values = QueryValues();
      await db.execute(
        Sql.named(
          'UPDATE "parties"\n'
          'SET "name" = COALESCE(UPDATED."name", "parties"."name"), "sponsor_id" = COALESCE(UPDATED."sponsor_id", "parties"."sponsor_id"), "date" = COALESCE(UPDATED."date", "parties"."date")\n'
          'FROM ( VALUES ${updateRequests.map((r) => '( ${values.add(r.id)}:text::text, ${values.add(r.name)}:text::text, ${values.add(r.sponsorId)}:text::text, ${values.add(r.date)}:int8::int8 )').join(', ')} )\n'
          'AS UPDATED("id", "name", "sponsor_id", "date")\n'
          'WHERE "parties"."id" = UPDATED."id"',
        ),
        parameters: values.values,
      );
    }
    await _updateGuests([
      for (final r in requests)
        if (r.guests case final guests?) (r.id, guests),
    ]);
  }

  Future<void> _updateGuests(List<(String, UpdateValues<int>)> updates) async {
    if (updates.isEmpty) return;

    final removeAllValues = [
      for (final u in updates)
        if (u.$2.mode == ValueMode.set) u.$1,
    ];
    final removeValues = [
      for (final u in updates)
        if (u.$2.mode == ValueMode.remove)
          for (final v in u.$2.values) (u.$1, v),
    ];
    final addValues = [
      for (final u in updates)
        if (u.$2.mode == ValueMode.add || u.$2.mode == ValueMode.set)
          for (final v in u.$2.values) (u.$1, v),
    ];

    if (removeAllValues.isNotEmpty) {
      final queryValues = QueryValues();
      await db.execute(
        Sql.named(
          'DELETE FROM "accounts_parties" WHERE "party_id" IN ( ${removeAllValues.map((v) => queryValues.add(v)).join(', ')} )',
        ),
        parameters: queryValues.values,
      );
    }

    if (removeValues.isNotEmpty) {
      final queryValues = QueryValues();
      await db.execute(
        Sql.named(
          'DELETE FROM "accounts_parties" WHERE ( "party_id", "account_id" ) IN ( ${removeValues.map((v) => '( ${queryValues.add(v.$1)}, ${queryValues.add(v.$2)} )').join(', ')} )',
        ),
        parameters: queryValues.values,
      );
    }

    if (addValues.isNotEmpty) {
      final queryValues = QueryValues();
      await db.execute(
        Sql.named(
          'INSERT INTO "accounts_parties" ( "party_id", "account_id" ) VALUES ${addValues.map((v) => '( ${queryValues.add(v.$1)}, ${queryValues.add(v.$2)} )').join(', ')}',
        ),
        parameters: queryValues.values,
      );
    }
  }
}

class PartyInsertRequest {
  PartyInsertRequest({
    required this.id,
    required this.name,
    this.guestsIds,
    this.sponsorId,
    required this.date,
  });

  final String id;
  final String name;
  final List<int>? guestsIds;
  final String? sponsorId;
  final int date;
}

class PartyUpdateRequest {
  PartyUpdateRequest({
    required this.id,
    this.name,
    this.guests,
    this.sponsorId,
    this.date,
  });

  final String id;
  final String? name;
  final UpdateValues<int>? guests;
  final String? sponsorId;
  final int? date;
}

class GuestPartyViewQueryable
    extends KeyedViewQueryable<GuestPartyView, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => TextEncoder.i.encode(key);

  @override
  String get query =>
      'SELECT "parties".*, row_to_json("sponsor".*) as "sponsor"'
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
    date: map.get('date'),
  );
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

class CompanyPartyViewQueryable
    extends KeyedViewQueryable<CompanyPartyView, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => TextEncoder.i.encode(key);

  @override
  String get query =>
      'SELECT "parties".*'
      'FROM "parties"';

  @override
  String get tableAlias => 'parties';

  @override
  CompanyPartyView decode(TypedMap map) => CompanyPartyView(
    id: map.get('id'),
    name: map.get('name'),
    date: map.get('date'),
  );
}

class CompanyPartyView {
  CompanyPartyView({required this.id, required this.name, required this.date});

  final String id;
  final String name;
  final int date;
}
