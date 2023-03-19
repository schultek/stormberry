// ignore_for_file: annotate_overrides

part of 'account.dart';

extension AccountRepositories on Database {
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
    var values = QueryValues();
    var rows = await db.query(
      'INSERT INTO "accounts" ( "first_name", "last_name", "location", "company_id" )\n'
      'VALUES ${requests.map((r) => '( ${values.add(r.firstName)}:text, ${values.add(r.lastName)}:text, ${values.add(LatLngConverter().tryEncode(r.location))}:point, ${values.add(r.companyId)}:text )').join(', ')}\n'
      'RETURNING "id"',
      values.values,
    );
    var result = rows.map<int>((r) => TextEncoder.i.decode(r.toColumnMap()['id'])).toList();

    await db.billingAddresses.insertMany(requests.where((r) => r.billingAddress != null).map((r) {
      return BillingAddressInsertRequest(
          city: r.billingAddress!.city,
          postcode: r.billingAddress!.postcode,
          name: r.billingAddress!.name,
          street: r.billingAddress!.street,
          accountId: result[requests.indexOf(r)],
          companyId: null);
    }).toList());

    return result;
  }

  @override
  Future<void> update(List<AccountUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    var values = QueryValues();
    await db.query(
      'UPDATE "accounts"\n'
      'SET "first_name" = COALESCE(UPDATED."first_name", "accounts"."first_name"), "last_name" = COALESCE(UPDATED."last_name", "accounts"."last_name"), "location" = COALESCE(UPDATED."location", "accounts"."location"), "company_id" = COALESCE(UPDATED."company_id", "accounts"."company_id")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${values.add(r.id)}:int8, ${values.add(r.firstName)}:text, ${values.add(r.lastName)}:text, ${values.add(LatLngConverter().tryEncode(r.location))}:point, ${values.add(r.companyId)}:text )').join(', ')} )\n'
      'AS UPDATED("id", "first_name", "last_name", "location", "company_id")\n'
      'WHERE "accounts"."id" = UPDATED."id"',
      values.values,
    );
    await db.billingAddresses.updateMany(requests.where((r) => r.billingAddress != null).map((r) {
      return BillingAddressUpdateRequest(
          city: r.billingAddress!.city,
          postcode: r.billingAddress!.postcode,
          name: r.billingAddress!.name,
          street: r.billingAddress!.street,
          accountId: r.id);
    }).toList());
  }
}

class AccountInsertRequest {
  AccountInsertRequest({
    required this.firstName,
    required this.lastName,
    required this.location,
    this.billingAddress,
    this.companyId,
  });

  final String firstName;
  final String lastName;
  final LatLng location;
  final BillingAddress? billingAddress;
  final String? companyId;
}

class AccountUpdateRequest {
  AccountUpdateRequest({
    required this.id,
    this.firstName,
    this.lastName,
    this.location,
    this.billingAddress,
    this.companyId,
  });

  final int id;
  final String? firstName;
  final String? lastName;
  final LatLng? location;
  final BillingAddress? billingAddress;
  final String? companyId;
}

class FullAccountViewQueryable extends KeyedViewQueryable<FullAccountView, int> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(int key) => TextEncoder.i.encode(key);

  @override
  String get query =>
      'SELECT "accounts".*, row_to_json("billingAddress".*) as "billingAddress", "invoices"."data" as "invoices", row_to_json("company".*) as "company", "parties"."data" as "parties"'
      'FROM "accounts"'
      'LEFT JOIN (${BillingAddressViewQueryable().query}) "billingAddress"'
      'ON "accounts"."id" = "billingAddress"."account_id"'
      'LEFT JOIN ('
      '  SELECT "invoices"."account_id",'
      '    to_jsonb(array_agg("invoices".*)) as data'
      '  FROM (${OwnerInvoiceViewQueryable().query}) "invoices"'
      '  GROUP BY "invoices"."account_id"'
      ') "invoices"'
      'ON "accounts"."id" = "invoices"."account_id"'
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
      'ON "accounts"."id" = "parties"."account_id"';

  @override
  String get tableAlias => 'accounts';

  @override
  FullAccountView decode(TypedMap map) => FullAccountView(
      id: map.get('id'),
      firstName: map.get('first_name'),
      lastName: map.get('last_name'),
      location: map.get('location', LatLngConverter().decode),
      billingAddress: map.getOpt('billingAddress', BillingAddressViewQueryable().decoder),
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
  final BillingAddressView? billingAddress;
  final List<OwnerInvoiceView> invoices;
  final MemberCompanyView? company;
  final List<GuestPartyView> parties;
}

class UserAccountViewQueryable extends KeyedViewQueryable<UserAccountView, int> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(int key) => TextEncoder.i.encode(key);

  @override
  String get query =>
      'SELECT "accounts".*, row_to_json("billingAddress".*) as "billingAddress", "invoices"."data" as "invoices", row_to_json("company".*) as "company", "parties"."data" as "parties"'
      'FROM "accounts"'
      'LEFT JOIN (${BillingAddressViewQueryable().query}) "billingAddress"'
      'ON "accounts"."id" = "billingAddress"."account_id"'
      'LEFT JOIN ('
      '  SELECT "invoices"."account_id",'
      '    to_jsonb(array_agg("invoices".*)) as data'
      '  FROM (${OwnerInvoiceViewQueryable().query}) "invoices"'
      '  GROUP BY "invoices"."account_id"'
      ') "invoices"'
      'ON "accounts"."id" = "invoices"."account_id"'
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
      'ON "accounts"."id" = "parties"."account_id"';

  @override
  String get tableAlias => 'accounts';

  @override
  UserAccountView decode(TypedMap map) => UserAccountView(
      id: map.get('id'),
      firstName: map.get('first_name'),
      lastName: map.get('last_name'),
      location: map.get('location', LatLngConverter().decode),
      billingAddress: map.getOpt('billingAddress', BillingAddressViewQueryable().decoder),
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
  final BillingAddressView? billingAddress;
  final List<OwnerInvoiceView> invoices;
  final MemberCompanyView? company;
  final List<GuestPartyView> parties;
}

class CompanyAccountViewQueryable extends KeyedViewQueryable<CompanyAccountView, int> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(int key) => TextEncoder.i.encode(key);

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
      id: map.get('id'),
      firstName: map.get('first_name'),
      lastName: map.get('last_name'),
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
