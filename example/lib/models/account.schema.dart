part of 'account.dart';

extension Repositories on Database {
  AccountRepository get accounts => AccountRepository._(this);
}

abstract class AccountRepository
    implements
        ModelRepository,
        KeyedModelRepositoryInsert<AccountInsertRequest>,
        ModelRepositoryUpdate<AccountUpdateRequest>,
        ModelRepositoryDelete<int> {
  factory AccountRepository._(Database db) = _AccountRepository;

  Future<FullAccountView?> queryFullView(int id);
  Future<List<FullAccountView>> queryFullViews([QueryParams? params]);
  Future<UserAccountView?> queryUserView(int id);
  Future<List<UserAccountView>> queryUserViews([QueryParams? params]);
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
  Future<FullAccountView?> queryFullView(int id) {
    return queryOne(id, FullAccountViewQueryable());
  }

  @override
  Future<List<FullAccountView>> queryFullViews([QueryParams? params]) {
    return queryMany(FullAccountViewQueryable(), params);
  }

  @override
  Future<UserAccountView?> queryUserView(int id) {
    return queryOne(id, UserAccountViewQueryable());
  }

  @override
  Future<List<UserAccountView>> queryUserViews([QueryParams? params]) {
    return queryMany(UserAccountViewQueryable(), params);
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
      'VALUES ${requests.map((r) => '( ${TypeEncoder.i.encode(autoIncrements[requests.indexOf(r)]['id'])}, ${TypeEncoder.i.encode(r.firstName)}, ${TypeEncoder.i.encode(r.lastName)}, ${TypeEncoder.i.encode(r.location, LatLngConverter())}, ${TypeEncoder.i.encode(r.companyId)} )').join(', ')}\n',
    );
    await db.billingAddresses.insertMany(requests.where((r) => r.billingAddress != null).map((r) {
      return BillingAddressInsertRequest(
          accountId: TypeEncoder.i.decode(autoIncrements[requests.indexOf(r)]['id']),
          companyId: null,
          city: r.billingAddress!.city,
          postcode: r.billingAddress!.postcode,
          name: r.billingAddress!.name,
          street: r.billingAddress!.street);
    }).toList());

    return autoIncrements.map<int>((m) => TypeEncoder.i.decode(m['id'])).toList();
  }

  @override
  Future<void> update(Database db, List<AccountUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query(
      'UPDATE "accounts"\n'
      'SET "first_name" = COALESCE(UPDATED."first_name"::text, "accounts"."first_name"), "last_name" = COALESCE(UPDATED."last_name"::text, "accounts"."last_name"), "location" = COALESCE(UPDATED."location"::jsonb, "accounts"."location"), "company_id" = COALESCE(UPDATED."company_id"::text, "accounts"."company_id")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${TypeEncoder.i.encode(r.id)}, ${TypeEncoder.i.encode(r.firstName)}, ${TypeEncoder.i.encode(r.lastName)}, ${TypeEncoder.i.encode(r.location, LatLngConverter())}, ${TypeEncoder.i.encode(r.companyId)} )').join(', ')} )\n'
      'AS UPDATED("id", "first_name", "last_name", "location", "company_id")\n'
      'WHERE "accounts"."id" = UPDATED."id"',
    );
    await db.billingAddresses.updateMany(requests.where((r) => r.billingAddress != null).map((r) {
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
      'WHERE "accounts"."id" IN ( ${keys.map((k) => TypeEncoder.i.encode(k)).join(',')} )',
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

class FullAccountViewQueryable extends KeyedViewQueryable<FullAccountView, int> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(int key) => TypeEncoder.i.encode(key);

  @override
  String get tableName => 'full_accounts_view';

  @override
  String get tableAlias => 'accounts';

  @override
  FullAccountView decode(TypedMap map) => FullAccountView(
      id: map.get('id', TypeEncoder.i.decode),
      firstName: map.get('first_name', TypeEncoder.i.decode),
      lastName: map.get('last_name', TypeEncoder.i.decode),
      location: map.get('location', LatLngConverter().decode),
      billingAddress: map.getOpt('billingAddress', BillingAddressQueryable().decoder),
      invoices: map.getListOpt('invoices', OwnerInvoiceViewQueryable().decoder) ?? const [],
      company: map.getOpt('company', MemberCompanyViewQueryable().decoder),
      parties: map.getListOpt('parties', GuestPartyViewQueryable().decoder) ?? const []);
}

class FullAccountView {
  FullAccountView({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.location,
    this.billingAddress,
    required this.invoices,
    this.company,
    required this.parties,
  });

  final int id;
  final String firstName;
  final String lastName;
  final LatLng location;
  final BillingAddress? billingAddress;
  final List<OwnerInvoiceView> invoices;
  final MemberCompanyView? company;
  final List<GuestPartyView> parties;
}

class UserAccountViewQueryable extends KeyedViewQueryable<UserAccountView, int> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(int key) => TypeEncoder.i.encode(key);

  @override
  String get tableName => 'user_accounts_view';

  @override
  String get tableAlias => 'accounts';

  @override
  UserAccountView decode(TypedMap map) => UserAccountView(
      id: map.get('id', TypeEncoder.i.decode),
      firstName: map.get('first_name', TypeEncoder.i.decode),
      lastName: map.get('last_name', TypeEncoder.i.decode),
      location: map.get('location', LatLngConverter().decode),
      billingAddress: map.getOpt('billingAddress', BillingAddressQueryable().decoder),
      invoices: map.getListOpt('invoices', OwnerInvoiceViewQueryable().decoder) ?? const [],
      company: map.getOpt('company', MemberCompanyViewQueryable().decoder),
      parties: map.getListOpt('parties', GuestPartyViewQueryable().decoder) ?? const []);
}

class UserAccountView {
  UserAccountView({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.location,
    this.billingAddress,
    required this.invoices,
    this.company,
    required this.parties,
  });

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
  String encodeKey(int key) => TypeEncoder.i.encode(key);

  @override
  String get tableName => 'company_accounts_view';

  @override
  String get tableAlias => 'accounts';

  @override
  CompanyAccountView decode(TypedMap map) => CompanyAccountView(
      id: map.get('id', TypeEncoder.i.decode),
      firstName: map.get('first_name', TypeEncoder.i.decode),
      lastName: map.get('last_name', TypeEncoder.i.decode),
      location: map.get('location', LatLngConverter().decode),
      parties: map.getListOpt('parties', CompanyPartyViewQueryable().decoder) ?? const []);
}

class CompanyAccountView {
  CompanyAccountView({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.location,
    required this.parties,
  });

  final int id;
  final String firstName;
  final String lastName;
  final LatLng location;
  final List<CompanyPartyView> parties;
}
