// ignore_for_file: prefer_relative_imports
import 'package:stormberry/internals.dart';

import 'models.dart';

extension Repositories on Database {
  AccountRepository get accounts => AccountRepository._(this);
  BillingAddressRepository get billingAddresses => BillingAddressRepository._(this);
  CompanyRepository get companies => CompanyRepository._(this);
  InvoiceRepository get invoices => InvoiceRepository._(this);
  PartyRepository get parties => PartyRepository._(this);
}

final registry = ModelRegistry({
  typeOf<LatLng>(): LatLngConverter(),
});

abstract class AccountRepository
    implements
        ModelRepository,
        KeyedModelRepositoryInsert<AccountInsertRequest>,
        ModelRepositoryUpdate<AccountUpdateRequest>,
        ModelRepositoryDelete<int> {
  factory AccountRepository._(Database db) = _AccountRepository;

  Future<UserAccountView?> queryUserView(int id);
  Future<List<UserAccountView>> queryUserViews([QueryParams? params]);
  Future<AdminAccountView?> queryAdminView(int id);
  Future<List<AdminAccountView>> queryAdminViews([QueryParams? params]);
  Future<CompanyAccountView?> queryCompanyView(int id);
  Future<List<CompanyAccountView>> queryCompanyViews([QueryParams? params]);
}

class _AccountRepository extends BaseRepository
    with
        KeyedRepositoryInsertMixin<AccountInsertRequest>,
        RepositoryUpdateMixin<AccountUpdateRequest>,
        RepositoryDeleteMixin<int>
    implements AccountRepository {
  _AccountRepository(Database db) : super(db: db);

  @override
  Future<UserAccountView?> queryUserView(int id) {
    return queryOne(id, UserAccountViewQueryable());
  }

  @override
  Future<List<UserAccountView>> queryUserViews([QueryParams? params]) {
    return queryMany(UserAccountViewQueryable(), params);
  }

  @override
  Future<AdminAccountView?> queryAdminView(int id) {
    return queryOne(id, AdminAccountViewQueryable());
  }

  @override
  Future<List<AdminAccountView>> queryAdminViews([QueryParams? params]) {
    return queryMany(AdminAccountViewQueryable(), params);
  }

  @override
  Future<CompanyAccountView?> queryCompanyView(int id) {
    return queryOne(id, CompanyAccountViewQueryable());
  }

  @override
  Future<List<CompanyAccountView>> queryCompanyViews([QueryParams? params]) {
    return queryMany(CompanyAccountViewQueryable(), params);
  }

  @override
  Future<List<int>> insert(Database db, List<AccountInsertRequest> requests) async {
    if (requests.isEmpty) return [];
    var rows = await db.query(requests.map((r) => "SELECT nextval('accounts_id_seq') as \"id\"").join('\nUNION ALL\n'));
    var autoIncrements = rows.map((r) => r.toColumnMap()).toList();

    await db.query(
      'INSERT INTO "accounts" ( "id", "first_name", "last_name", "location", "company_id" )\n'
      'VALUES ${requests.map((r) => '( ${registry.encode(autoIncrements[requests.indexOf(r)]['id'])}, ${registry.encode(r.firstName)}, ${registry.encode(r.lastName)}, ${registry.encode(r.location)}, ${registry.encode(r.companyId)} )').join(', ')}\n',
    );
    await _BillingAddressRepository(db).insert(
        db,
        requests.where((r) => r.billingAddress != null).map((r) {
          return BillingAddressInsertRequest(
              accountId: registry.decode(autoIncrements[requests.indexOf(r)]['id']),
              companyId: null,
              city: r.billingAddress!.city,
              postcode: r.billingAddress!.postcode,
              name: r.billingAddress!.name,
              street: r.billingAddress!.street);
        }).toList());

    return autoIncrements.map<int>((m) => registry.decode(m['id'])).toList();
  }

  @override
  Future<void> update(Database db, List<AccountUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query(
      'UPDATE "accounts"\n'
      'SET "first_name" = COALESCE(UPDATED."first_name"::text, "accounts"."first_name"), "last_name" = COALESCE(UPDATED."last_name"::text, "accounts"."last_name"), "location" = COALESCE(UPDATED."location"::point, "accounts"."location"), "company_id" = COALESCE(UPDATED."company_id"::text, "accounts"."company_id")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${registry.encode(r.id)}, ${registry.encode(r.firstName)}, ${registry.encode(r.lastName)}, ${registry.encode(r.location)}, ${registry.encode(r.companyId)} )').join(', ')} )\n'
      'AS UPDATED("id", "first_name", "last_name", "location", "company_id")\n'
      'WHERE "accounts"."id" = UPDATED."id"',
    );
    await _BillingAddressRepository(db).update(
        db,
        requests.where((r) => r.billingAddress != null).map((r) {
          return BillingAddressUpdateRequest(
              accountId: r.id,
              city: r.billingAddress!.city,
              postcode: r.billingAddress!.postcode,
              name: r.billingAddress!.name,
              street: r.billingAddress!.street);
        }).toList());
  }

  @override
  Future<void> delete(Database db, List<int> keys) async {
    if (keys.isEmpty) return;
    await db.query(
      'DELETE FROM "accounts"\n'
      'WHERE "accounts"."id" IN ( ${keys.map((k) => registry.encode(k)).join(',')} )',
    );
  }
}

abstract class BillingAddressRepository
    implements
        ModelRepository,
        ModelRepositoryInsert<BillingAddressInsertRequest>,
        ModelRepositoryUpdate<BillingAddressUpdateRequest> {
  factory BillingAddressRepository._(Database db) = _BillingAddressRepository;

  Future<List<BillingAddress>> queryBillingAddresss([QueryParams? params]);
}

class _BillingAddressRepository extends BaseRepository
    with RepositoryInsertMixin<BillingAddressInsertRequest>, RepositoryUpdateMixin<BillingAddressUpdateRequest>
    implements BillingAddressRepository {
  _BillingAddressRepository(Database db) : super(db: db);

  @override
  Future<List<BillingAddress>> queryBillingAddresss([QueryParams? params]) {
    return queryMany(BillingAddressQueryable(), params);
  }

  @override
  Future<void> insert(Database db, List<BillingAddressInsertRequest> requests) async {
    if (requests.isEmpty) return;

    await db.query(
      'INSERT INTO "billing_addresses" ( "account_id", "company_id", "city", "postcode", "name", "street" )\n'
      'VALUES ${requests.map((r) => '( ${registry.encode(r.accountId)}, ${registry.encode(r.companyId)}, ${registry.encode(r.city)}, ${registry.encode(r.postcode)}, ${registry.encode(r.name)}, ${registry.encode(r.street)} )').join(', ')}\n'
      'ON CONFLICT ( "account_id" ) DO UPDATE SET "city" = EXCLUDED."city", "postcode" = EXCLUDED."postcode", "name" = EXCLUDED."name", "street" = EXCLUDED."street"',
    );
  }

  @override
  Future<void> update(Database db, List<BillingAddressUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query(
      'UPDATE "billing_addresses"\n'
      'SET "city" = COALESCE(UPDATED."city"::text, "billing_addresses"."city"), "postcode" = COALESCE(UPDATED."postcode"::text, "billing_addresses"."postcode"), "name" = COALESCE(UPDATED."name"::text, "billing_addresses"."name"), "street" = COALESCE(UPDATED."street"::text, "billing_addresses"."street")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${registry.encode(r.accountId)}, ${registry.encode(r.companyId)}, ${registry.encode(r.city)}, ${registry.encode(r.postcode)}, ${registry.encode(r.name)}, ${registry.encode(r.street)} )').join(', ')} )\n'
      'AS UPDATED("account_id", "company_id", "city", "postcode", "name", "street")\n'
      'WHERE "billing_addresses"."account_id" = UPDATED."account_id" AND "billing_addresses"."company_id" = UPDATED."company_id"',
    );
  }
}

abstract class CompanyRepository
    implements
        ModelRepository,
        ModelRepositoryInsert<CompanyInsertRequest>,
        ModelRepositoryUpdate<CompanyUpdateRequest>,
        ModelRepositoryDelete<String> {
  factory CompanyRepository._(Database db) = _CompanyRepository;

  Future<AdminCompanyView?> queryAdminView(String id);
  Future<List<AdminCompanyView>> queryAdminViews([QueryParams? params]);
  Future<MemberCompanyView?> queryMemberView(String id);
  Future<List<MemberCompanyView>> queryMemberViews([QueryParams? params]);
}

class _CompanyRepository extends BaseRepository
    with
        RepositoryInsertMixin<CompanyInsertRequest>,
        RepositoryUpdateMixin<CompanyUpdateRequest>,
        RepositoryDeleteMixin<String>
    implements CompanyRepository {
  _CompanyRepository(Database db) : super(db: db);

  @override
  Future<AdminCompanyView?> queryAdminView(String id) {
    return queryOne(id, AdminCompanyViewQueryable());
  }

  @override
  Future<List<AdminCompanyView>> queryAdminViews([QueryParams? params]) {
    return queryMany(AdminCompanyViewQueryable(), params);
  }

  @override
  Future<MemberCompanyView?> queryMemberView(String id) {
    return queryOne(id, MemberCompanyViewQueryable());
  }

  @override
  Future<List<MemberCompanyView>> queryMemberViews([QueryParams? params]) {
    return queryMany(MemberCompanyViewQueryable(), params);
  }

  @override
  Future<void> insert(Database db, List<CompanyInsertRequest> requests) async {
    if (requests.isEmpty) return;

    await db.query(
      'INSERT INTO "companies" ( "id", "name" )\n'
      'VALUES ${requests.map((r) => '( ${registry.encode(r.id)}, ${registry.encode(r.name)} )').join(', ')}\n'
      'ON CONFLICT ( "id" ) DO UPDATE SET "name" = EXCLUDED."name"',
    );
    await _BillingAddressRepository(db).insert(
        db,
        requests.expand((r) {
          return r.addresses.map((rr) => BillingAddressInsertRequest(
              accountId: null,
              companyId: r.id,
              city: rr.city,
              postcode: rr.postcode,
              name: rr.name,
              street: rr.street));
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
    await _BillingAddressRepository(db).update(
        db,
        requests.where((r) => r.addresses != null).expand((r) {
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

class AccountInsertRequest {
  AccountInsertRequest(
      {required this.firstName, required this.lastName, required this.location, this.billingAddress, this.companyId});
  String firstName;
  String lastName;
  LatLng location;
  BillingAddress? billingAddress;
  String? companyId;
}

class BillingAddressInsertRequest {
  BillingAddressInsertRequest(
      {this.accountId,
      this.companyId,
      required this.city,
      required this.postcode,
      required this.name,
      required this.street});
  int? accountId;
  String? companyId;
  String city;
  String postcode;
  String name;
  String street;
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

class AccountUpdateRequest {
  AccountUpdateRequest(
      {required this.id, this.firstName, this.lastName, this.location, this.billingAddress, this.companyId});
  int id;
  String? firstName;
  String? lastName;
  LatLng? location;
  BillingAddress? billingAddress;
  String? companyId;
}

class BillingAddressUpdateRequest {
  BillingAddressUpdateRequest({this.accountId, this.companyId, this.city, this.postcode, this.name, this.street});
  int? accountId;
  String? companyId;
  String? city;
  String? postcode;
  String? name;
  String? street;
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

class UserAccountViewQueryable extends KeyedViewQueryable<UserAccountView, int> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(int key) => registry.encode(key);

  @override
  String get tableName => 'user_accounts_view';

  @override
  String get tableAlias => 'accounts';

  @override
  UserAccountView decode(TypedMap map) => UserAccountView(
      id: map.get('id', registry.decode),
      firstName: map.get('first_name', registry.decode),
      lastName: map.get('last_name', registry.decode),
      location: map.get('location', registry.decode),
      billingAddress: map.getOpt('billingAddress', BillingAddressQueryable().decoder),
      invoices: map.getListOpt('invoices', OwnerInvoiceViewQueryable().decoder) ?? const [],
      company: map.getOpt('company', MemberCompanyViewQueryable().decoder),
      parties: map.getListOpt('parties', GuestPartyViewQueryable().decoder) ?? const []);
}

class UserAccountView {
  UserAccountView(
      {required this.id,
      required this.firstName,
      required this.lastName,
      required this.location,
      this.billingAddress,
      required this.invoices,
      this.company,
      required this.parties});

  final int id;
  final String firstName;
  final String lastName;
  final LatLng location;
  final BillingAddress? billingAddress;
  final List<OwnerInvoiceView> invoices;
  final MemberCompanyView? company;
  final List<GuestPartyView> parties;
}

class AdminAccountViewQueryable extends KeyedViewQueryable<AdminAccountView, int> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(int key) => registry.encode(key);

  @override
  String get tableName => 'admin_accounts_view';

  @override
  String get tableAlias => 'accounts';

  @override
  AdminAccountView decode(TypedMap map) => AdminAccountView(
      id: map.get('id', registry.decode),
      firstName: map.get('first_name', registry.decode),
      lastName: map.get('last_name', registry.decode),
      location: map.get('location', registry.decode),
      billingAddress: map.getOpt('billingAddress', BillingAddressQueryable().decoder),
      invoices: map.getListOpt('invoices', OwnerInvoiceViewQueryable().decoder) ?? const [],
      company: map.getOpt('company', MemberCompanyViewQueryable().decoder),
      parties: map.getListOpt('parties', GuestPartyViewQueryable().decoder) ?? const []);
}

class AdminAccountView {
  AdminAccountView(
      {required this.id,
      required this.firstName,
      required this.lastName,
      required this.location,
      this.billingAddress,
      required this.invoices,
      this.company,
      required this.parties});

  final int id;
  final String firstName;
  final String lastName;
  final LatLng location;
  final BillingAddress? billingAddress;
  final List<OwnerInvoiceView> invoices;
  final MemberCompanyView? company;
  final List<GuestPartyView> parties;
}

class CompanyAccountViewQueryable extends KeyedViewQueryable<CompanyAccountView, int> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(int key) => registry.encode(key);

  @override
  String get tableName => 'company_accounts_view';

  @override
  String get tableAlias => 'accounts';

  @override
  CompanyAccountView decode(TypedMap map) => CompanyAccountView(
      id: map.get('id', registry.decode),
      firstName: map.get('first_name', registry.decode),
      lastName: map.get('last_name', registry.decode),
      location: map.get('location', registry.decode),
      parties: map.getListOpt('parties', CompanyPartyViewQueryable().decoder) ?? const []);
}

class CompanyAccountView {
  CompanyAccountView(
      {required this.id,
      required this.firstName,
      required this.lastName,
      required this.location,
      required this.parties});

  final int id;
  final String firstName;
  final String lastName;
  final LatLng location;
  final List<CompanyPartyView> parties;
}

class BillingAddressQueryable extends ViewQueryable<BillingAddress> {
  @override
  String get tableName => 'billing_addresses_view';

  @override
  String get tableAlias => 'billing_addresses';

  @override
  BillingAddress decode(TypedMap map) => BillingAddressView(
      city: map.get('city', registry.decode),
      postcode: map.get('postcode', registry.decode),
      name: map.get('name', registry.decode),
      street: map.get('street', registry.decode));
}

class BillingAddressView implements BillingAddress {
  BillingAddressView({required this.city, required this.postcode, required this.name, required this.street});

  @override
  final String city;
  @override
  final String postcode;
  @override
  final String name;
  @override
  final String street;
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
  AdminCompanyView(
      {required this.members,
      required this.id,
      required this.name,
      required this.addresses,
      required this.invoices,
      required this.parties});

  final List<CompanyAccountView> members;
  final String id;
  final String name;
  final List<BillingAddress> addresses;
  final List<OwnerInvoiceView> invoices;
  final List<CompanyPartyView> parties;
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
  MemberCompanyView({required this.id, required this.name, required this.addresses});

  final String id;
  final String name;
  final List<BillingAddress> addresses;
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
  OwnerInvoiceView({required this.id, required this.title, required this.invoiceId});

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
  GuestPartyView({this.sponsor, required this.id, required this.name, required this.date});

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
  CompanyPartyView({required this.id, required this.name, required this.date});

  final String id;
  final String name;
  final int date;
}
