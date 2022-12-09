part of 'company.dart';

extension Repositories on Database {
  CompanyRepository get companies => CompanyRepository._(this);
  InvoiceRepository get invoices => InvoiceRepository._(this);
  PartyRepository get parties => PartyRepository._(this);
}

final registry = ModelRegistry();

abstract class CompanyRepository
    implements
        ModelRepository,
        ModelRepositoryInsert<CompanyInsertRequest>,
        ModelRepositoryUpdate<CompanyUpdateRequest>,
        ModelRepositoryDelete<String> {
  factory CompanyRepository._(Database db) = _CompanyRepository;

  Future<MemberCompanyView?> queryMemberView(String id);
  Future<List<MemberCompanyView>> queryMemberViews([QueryParams? params]);
  Future<AdminCompanyView?> queryAdminView(String id);
  Future<List<AdminCompanyView>> queryAdminViews([QueryParams? params]);
}

class _CompanyRepository extends BaseRepository
    with
        RepositoryInsertMixin<CompanyInsertRequest>,
        RepositoryUpdateMixin<CompanyUpdateRequest>,
        RepositoryDeleteMixin<String>
    implements CompanyRepository {
  _CompanyRepository(Database db) : super(db: db);

  @override
  Future<MemberCompanyView?> queryMemberView(String id) {
    return queryOne(id, MemberCompanyViewQueryable());
  }

  @override
  Future<List<MemberCompanyView>> queryMemberViews([QueryParams? params]) {
    return queryMany(MemberCompanyViewQueryable(), params);
  }

  @override
  Future<AdminCompanyView?> queryAdminView(String id) {
    return queryOne(id, AdminCompanyViewQueryable());
  }

  @override
  Future<List<AdminCompanyView>> queryAdminViews([QueryParams? params]) {
    return queryMany(AdminCompanyViewQueryable(), params);
  }

  @override
  Future<void> insert(Database db, List<CompanyInsertRequest> requests) async {
    if (requests.isEmpty) return;

    await db.query(
      'INSERT INTO "companies" ( "id", "name" )\n'
      'VALUES ${requests.map((r) => '( ${registry.encode(r.id)}, ${registry.encode(r.name)} )').join(', ')}\n'
      'ON CONFLICT ( "id" ) DO UPDATE SET "name" = EXCLUDED."name"',
    );
    await db.billingAddresses.insertMany(requests.expand((r) {
      return r.addresses.map((rr) => BillingAddressInsertRequest(
          accountId: null, companyId: r.id, city: rr.city, postcode: rr.postcode, name: rr.name, street: rr.street));
    }).toList());
  }

  @override
  Future<void> update(Database db, List<CompanyUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query(
      'UPDATE "companies"\n'
      'SET "name" = COALESCE(UPDATED."name"::text, "companies"."name")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${registry.encode(r.id)}, ${registry.encode(r.name)} )').join(', ')} )\n'
      'AS UPDATED("id", "name")\n'
      'WHERE "companies"."id" = UPDATED."id"',
    );
    await db.billingAddresses.updateMany(requests.where((r) => r.addresses != null).expand((r) {
      return r.addresses!.map((rr) => BillingAddressUpdateRequest(
          companyId: r.id, city: rr.city, postcode: rr.postcode, name: rr.name, street: rr.street));
    }).toList());
  }

  @override
  Future<void> delete(Database db, List<String> keys) async {
    if (keys.isEmpty) return;
    await db.query(
      'DELETE FROM "companies"\n'
      'WHERE "companies"."id" IN ( ${keys.map((k) => registry.encode(k)).join(',')} )',
    );
  }
}

abstract class InvoiceRepository
    implements
        ModelRepository,
        ModelRepositoryInsert<InvoiceInsertRequest>,
        ModelRepositoryUpdate<InvoiceUpdateRequest>,
        ModelRepositoryDelete<String> {
  factory InvoiceRepository._(Database db) = _InvoiceRepository;

  Future<OwnerInvoiceView?> queryOwnerView(String id);
  Future<List<OwnerInvoiceView>> queryOwnerViews([QueryParams? params]);
}

class _InvoiceRepository extends BaseRepository
    with
        RepositoryInsertMixin<InvoiceInsertRequest>,
        RepositoryUpdateMixin<InvoiceUpdateRequest>,
        RepositoryDeleteMixin<String>
    implements InvoiceRepository {
  _InvoiceRepository(Database db) : super(db: db);

  @override
  Future<OwnerInvoiceView?> queryOwnerView(String id) {
    return queryOne(id, OwnerInvoiceViewQueryable());
  }

  @override
  Future<List<OwnerInvoiceView>> queryOwnerViews([QueryParams? params]) {
    return queryMany(OwnerInvoiceViewQueryable(), params);
  }

  @override
  Future<void> insert(Database db, List<InvoiceInsertRequest> requests) async {
    if (requests.isEmpty) return;

    await db.query(
      'INSERT INTO "invoices" ( "account_id", "company_id", "id", "title", "invoice_id" )\n'
      'VALUES ${requests.map((r) => '( ${registry.encode(r.accountId)}, ${registry.encode(r.companyId)}, ${registry.encode(r.id)}, ${registry.encode(r.title)}, ${registry.encode(r.invoiceId)} )').join(', ')}\n'
      'ON CONFLICT ( "id" ) DO UPDATE SET "account_id" = EXCLUDED."account_id", "company_id" = EXCLUDED."company_id", "title" = EXCLUDED."title", "invoice_id" = EXCLUDED."invoice_id"',
    );
  }

  @override
  Future<void> update(Database db, List<InvoiceUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query(
      'UPDATE "invoices"\n'
      'SET "account_id" = COALESCE(UPDATED."account_id"::int8, "invoices"."account_id"), "company_id" = COALESCE(UPDATED."company_id"::text, "invoices"."company_id"), "title" = COALESCE(UPDATED."title"::text, "invoices"."title"), "invoice_id" = COALESCE(UPDATED."invoice_id"::text, "invoices"."invoice_id")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${registry.encode(r.accountId)}, ${registry.encode(r.companyId)}, ${registry.encode(r.id)}, ${registry.encode(r.title)}, ${registry.encode(r.invoiceId)} )').join(', ')} )\n'
      'AS UPDATED("account_id", "company_id", "id", "title", "invoice_id")\n'
      'WHERE "invoices"."id" = UPDATED."id"',
    );
  }

  @override
  Future<void> delete(Database db, List<String> keys) async {
    if (keys.isEmpty) return;
    await db.query(
      'DELETE FROM "invoices"\n'
      'WHERE "invoices"."id" IN ( ${keys.map((k) => registry.encode(k)).join(',')} )',
    );
  }
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
      'VALUES ${requests.map((r) => '( ${registry.encode(r.sponsorId)}, ${registry.encode(r.id)}, ${registry.encode(r.name)}, ${registry.encode(r.date)} )').join(', ')}\n'
      'ON CONFLICT ( "id" ) DO UPDATE SET "sponsor_id" = EXCLUDED."sponsor_id", "name" = EXCLUDED."name", "date" = EXCLUDED."date"',
    );
  }

  @override
  Future<void> update(Database db, List<PartyUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query(
      'UPDATE "parties"\n'
      'SET "sponsor_id" = COALESCE(UPDATED."sponsor_id"::text, "parties"."sponsor_id"), "name" = COALESCE(UPDATED."name"::text, "parties"."name"), "date" = COALESCE(UPDATED."date"::int8, "parties"."date")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${registry.encode(r.sponsorId)}, ${registry.encode(r.id)}, ${registry.encode(r.name)}, ${registry.encode(r.date)} )').join(', ')} )\n'
      'AS UPDATED("sponsor_id", "id", "name", "date")\n'
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

class CompanyInsertRequest {
  CompanyInsertRequest({required this.id, required this.name, required this.addresses});
  String id;
  String name;
  List<BillingAddress> addresses;
}

class InvoiceInsertRequest {
  InvoiceInsertRequest(
      {this.accountId, this.companyId, required this.id, required this.title, required this.invoiceId});
  int? accountId;
  String? companyId;
  String id;
  String title;
  String invoiceId;
}

class PartyInsertRequest {
  PartyInsertRequest({this.sponsorId, required this.id, required this.name, required this.date});
  String? sponsorId;
  String id;
  String name;
  int date;
}

class CompanyUpdateRequest {
  CompanyUpdateRequest({required this.id, this.name, this.addresses});
  String id;
  String? name;
  List<BillingAddress>? addresses;
}

class InvoiceUpdateRequest {
  InvoiceUpdateRequest({this.accountId, this.companyId, required this.id, this.title, this.invoiceId});
  int? accountId;
  String? companyId;
  String id;
  String? title;
  String? invoiceId;
}

class PartyUpdateRequest {
  PartyUpdateRequest({this.sponsorId, required this.id, this.name, this.date});
  String? sponsorId;
  String id;
  String? name;
  int? date;
}

class MemberCompanyViewQueryable extends KeyedViewQueryable<MemberCompanyView, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => registry.encode(key);

  @override
  String get tableName => 'member_companies_view';

  @override
  String get tableAlias => 'companies';

  @override
  MemberCompanyView decode(TypedMap map) => MemberCompanyView(
      id: map.get('id', registry.decode),
      name: map.get('name', registry.decode),
      addresses: map.getListOpt('addresses', BillingAddressQueryable().decoder) ?? const []);
}

class MemberCompanyView {
  MemberCompanyView({
    required this.id,
    required this.name,
    required this.addresses,
  });

  final String id;
  final String name;
  final List<BillingAddress> addresses;
}

class AdminCompanyViewQueryable extends KeyedViewQueryable<AdminCompanyView, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => registry.encode(key);

  @override
  String get tableName => 'admin_companies_view';

  @override
  String get tableAlias => 'companies';

  @override
  AdminCompanyView decode(TypedMap map) => AdminCompanyView(
      members: map.getListOpt('members', CompanyAccountViewQueryable().decoder) ?? const [],
      id: map.get('id', registry.decode),
      name: map.get('name', registry.decode),
      addresses: map.getListOpt('addresses', BillingAddressQueryable().decoder) ?? const [],
      invoices: map.getListOpt('invoices', OwnerInvoiceViewQueryable().decoder) ?? const [],
      parties: map.getListOpt('parties', CompanyPartyViewQueryable().decoder) ?? const []);
}

class AdminCompanyView {
  AdminCompanyView({
    required this.members,
    required this.id,
    required this.name,
    required this.addresses,
    required this.invoices,
    required this.parties,
  });

  final List<CompanyAccountView> members;
  final String id;
  final String name;
  final List<BillingAddress> addresses;
  final List<OwnerInvoiceView> invoices;
  final List<CompanyPartyView> parties;
}

class OwnerInvoiceViewQueryable extends KeyedViewQueryable<OwnerInvoiceView, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => registry.encode(key);

  @override
  String get tableName => 'owner_invoices_view';

  @override
  String get tableAlias => 'invoices';

  @override
  OwnerInvoiceView decode(TypedMap map) => OwnerInvoiceView(
      id: map.get('id', registry.decode),
      title: map.get('title', registry.decode),
      invoiceId: map.get('invoice_id', registry.decode));
}

class OwnerInvoiceView {
  OwnerInvoiceView({
    required this.id,
    required this.title,
    required this.invoiceId,
  });

  final String id;
  final String title;
  final String invoiceId;
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
      sponsor: map.getOpt('sponsor', MemberCompanyViewQueryable().decoder),
      id: map.get('id', registry.decode),
      name: map.get('name', registry.decode),
      date: map.get('date', registry.decode));
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
