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
  _AccountRepository(super.db) : super(tableName: 'accounts', keyName: 'id');

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
  Future<List<int>> insert(List<AccountInsertRequest> requests) async {
    if (requests.isEmpty) return [];
    var rows = await db.query(requests.map((r) => "SELECT nextval('accounts_id_seq') as \"id\"").join('\nUNION ALL\n'));
    var autoIncrements = rows.map((r) => r.toColumnMap()).toList();

    await db.query(
      'INSERT INTO "accounts" ( "company_id", "id", "first_name", "last_name", "location" )\n'
      'VALUES ${requests.map((r) => '( ${TypeEncoder.i.encode(r.companyId)}, ${TypeEncoder.i.encode(autoIncrements[requests.indexOf(r)]['id'])}, ${TypeEncoder.i.encode(r.firstName)}, ${TypeEncoder.i.encode(r.lastName)}, ${TypeEncoder.i.encode(r.location, LatLngConverter())} )').join(', ')}\n',
    );
    await db.billingAddresses.insertMany(requests.where((r) => r.billingAddress != null).map((r) {
      return BillingAddressInsertRequest(
          companyId: null,
          accountId: TypeEncoder.i.decode(autoIncrements[requests.indexOf(r)]['id']),
          city: r.billingAddress!.city,
          postcode: r.billingAddress!.postcode,
          name: r.billingAddress!.name,
          street: r.billingAddress!.street);
    }).toList());

    return autoIncrements.map<int>((m) => TypeEncoder.i.decode(m['id'])).toList();
  }

  @override
  Future<void> update(List<AccountUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query(
      'UPDATE "accounts"\n'
      'SET "company_id" = COALESCE(UPDATED."company_id"::text, "accounts"."company_id"), "first_name" = COALESCE(UPDATED."first_name"::text, "accounts"."first_name"), "last_name" = COALESCE(UPDATED."last_name"::text, "accounts"."last_name"), "location" = COALESCE(UPDATED."location"::point, "accounts"."location")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${TypeEncoder.i.encode(r.companyId)}, ${TypeEncoder.i.encode(r.id)}, ${TypeEncoder.i.encode(r.firstName)}, ${TypeEncoder.i.encode(r.lastName)}, ${TypeEncoder.i.encode(r.location, LatLngConverter())} )').join(', ')} )\n'
      'AS UPDATED("company_id", "id", "first_name", "last_name", "location")\n'
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
}

class AccountInsertRequest {
  AccountInsertRequest({
    this.companyId,
    required this.firstName,
    required this.lastName,
    required this.location,
    this.billingAddress,
  });

  String? companyId;
  String firstName;
  String lastName;
  LatLng location;
  BillingAddress? billingAddress;
}

class AccountUpdateRequest {
  AccountUpdateRequest({
    this.companyId,
    required this.id,
    this.firstName,
    this.lastName,
    this.location,
    this.billingAddress,
  });

  String? companyId;
  int id;
  String? firstName;
  String? lastName;
  LatLng? location;
  BillingAddress? billingAddress;
}

class FullAccountViewQueryable extends KeyedViewQueryable<FullAccountView, int> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(int key) => TypeEncoder.i.encode(key);

  @override
  String get query =>
      'SELECT "accounts".*, row_to_json("company".*) as "company", "parties"."data" as "parties", "invoices"."data" as "invoices", row_to_json("billingAddress".*) as "billingAddress"'
      'FROM "accounts"'
      'LEFT JOIN (${MemberCompanyViewQueryable().query}) "company"'
      'ON "accounts"."company_id" = "company"."id"'
      'LEFT JOIN ('
      '  SELECT "accounts_parties"."account_id",'
      '    to_jsonb(array_agg("parties".*)) as data'
      '  FROM "accounts_parties"'
      '  LEFT JOIN (${GuestPartyViewQueryable().query}) "parties"'
      '  ON "parties"."id" = "accounts_parties"."party_id"'
      '  GROUP BY "accounts_parties"."account_id"'
      ') "parties"'
      'ON "accounts"."id" = "parties"."account_id"'
      'LEFT JOIN ('
      '  SELECT "invoices"."account_id",'
      '    to_jsonb(array_agg("invoices".*)) as data'
      '  FROM (${OwnerInvoiceViewQueryable().query}) "invoices"'
      '  GROUP BY "invoices"."account_id"'
      ') "invoices"'
      'ON "accounts"."id" = "invoices"."account_id"'
      'LEFT JOIN (${BillingAddressQueryable().query}) "billingAddress"'
      'ON "accounts"."id" = "billingAddress"."account_id"';

  @override
  String get tableAlias => 'accounts';

  @override
  FullAccountView decode(TypedMap map) => FullAccountView(
      company: map.getOpt('company', MemberCompanyViewQueryable().decoder),
      parties: map.getListOpt('parties', GuestPartyViewQueryable().decoder) ?? const [],
      invoices: map.getListOpt('invoices', OwnerInvoiceViewQueryable().decoder) ?? const [],
      id: map.get('id', TypeEncoder.i.decode),
      firstName: map.get('first_name', TypeEncoder.i.decode),
      lastName: map.get('last_name', TypeEncoder.i.decode),
      location: map.get('location', LatLngConverter().decode),
      billingAddress: map.getOpt('billingAddress', BillingAddressQueryable().decoder));
}

class FullAccountView {
  FullAccountView({
    this.company,
    required this.parties,
    required this.invoices,
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.location,
    this.billingAddress,
  });

  final MemberCompanyView? company;
  final List<GuestPartyView> parties;
  final List<OwnerInvoiceView> invoices;
  final int id;
  final String firstName;
  final String lastName;
  final LatLng location;
  final BillingAddress? billingAddress;
}

class UserAccountViewQueryable extends KeyedViewQueryable<UserAccountView, int> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(int key) => TypeEncoder.i.encode(key);

  @override
  String get query =>
      'SELECT "accounts".*, row_to_json("company".*) as "company", "parties"."data" as "parties", "invoices"."data" as "invoices", row_to_json("billingAddress".*) as "billingAddress"'
      'FROM "accounts"'
      'LEFT JOIN (${MemberCompanyViewQueryable().query}) "company"'
      'ON "accounts"."company_id" = "company"."id"'
      'LEFT JOIN ('
      '  SELECT "accounts_parties"."account_id",'
      '    to_jsonb(array_agg("parties".*)) as data'
      '  FROM "accounts_parties"'
      '  LEFT JOIN (${GuestPartyViewQueryable().query}) "parties"'
      '  ON "parties"."id" = "accounts_parties"."party_id"'
      '  GROUP BY "accounts_parties"."account_id"'
      ') "parties"'
      'ON "accounts"."id" = "parties"."account_id"'
      'LEFT JOIN ('
      '  SELECT "invoices"."account_id",'
      '    to_jsonb(array_agg("invoices".*)) as data'
      '  FROM (${OwnerInvoiceViewQueryable().query}) "invoices"'
      '  GROUP BY "invoices"."account_id"'
      ') "invoices"'
      'ON "accounts"."id" = "invoices"."account_id"'
      'LEFT JOIN (${BillingAddressQueryable().query}) "billingAddress"'
      'ON "accounts"."id" = "billingAddress"."account_id"';

  @override
  String get tableAlias => 'accounts';

  @override
  UserAccountView decode(TypedMap map) => UserAccountView(
      company: map.getOpt('company', MemberCompanyViewQueryable().decoder),
      parties: map.getListOpt('parties', GuestPartyViewQueryable().decoder) ?? const [],
      invoices: map.getListOpt('invoices', OwnerInvoiceViewQueryable().decoder) ?? const [],
      id: map.get('id', TypeEncoder.i.decode),
      firstName: map.get('first_name', TypeEncoder.i.decode),
      lastName: map.get('last_name', TypeEncoder.i.decode),
      location: map.get('location', LatLngConverter().decode),
      billingAddress: map.getOpt('billingAddress', BillingAddressQueryable().decoder));
}

class UserAccountView {
  UserAccountView({
    this.company,
    required this.parties,
    required this.invoices,
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.location,
    this.billingAddress,
  });

  final MemberCompanyView? company;
  final List<GuestPartyView> parties;
  final List<OwnerInvoiceView> invoices;
  final int id;
  final String firstName;
  final String lastName;
  final LatLng location;
  final BillingAddress? billingAddress;
}

class CompanyAccountViewQueryable extends KeyedViewQueryable<CompanyAccountView, int> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(int key) => TypeEncoder.i.encode(key);

  @override
  String get query =>
      'SELECT "accounts".*, ${FilterByField('sponsor_id', '=', 'company_id').transform('parties', 'accounts')}'
      'FROM "accounts"'
      'LEFT JOIN ('
      '  SELECT "accounts_parties"."account_id",'
      '    to_jsonb(array_agg("parties".*)) as data'
      '  FROM "accounts_parties"'
      '  LEFT JOIN (${CompanyPartyViewQueryable().query}) "parties"'
      '  ON "parties"."id" = "accounts_parties"."party_id"'
      '  GROUP BY "accounts_parties"."account_id"'
      ') "parties"'
      'ON "accounts"."id" = "parties"."account_id"';

  @override
  String get tableAlias => 'accounts';

  @override
  CompanyAccountView decode(TypedMap map) => CompanyAccountView(
      parties: map.getListOpt('parties', CompanyPartyViewQueryable().decoder) ?? const [],
      id: map.get('id', TypeEncoder.i.decode),
      firstName: map.get('first_name', TypeEncoder.i.decode),
      lastName: map.get('last_name', TypeEncoder.i.decode),
      location: map.get('location', LatLngConverter().decode));
}

class CompanyAccountView {
  CompanyAccountView({
    required this.parties,
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.location,
  });

  final List<CompanyPartyView> parties;
  final int id;
  final String firstName;
  final String lastName;
  final LatLng location;
}
