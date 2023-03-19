// ignore_for_file: annotate_overrides

part of 'company.dart';

extension CompanyRepositories on Database {
  CompanyRepository get companies => CompanyRepository._(this);
}

abstract class CompanyRepository
    implements
        ModelRepository,
        ModelRepositoryInsert<CompanyInsertRequest>,
        ModelRepositoryUpdate<CompanyUpdateRequest>,
        ModelRepositoryDelete<String> {
  factory CompanyRepository._(Database db) = _CompanyRepository;

  Future<FullCompanyView?> queryFullView(String id);
  Future<List<FullCompanyView>> queryFullViews([QueryParams? params]);
  Future<MemberCompanyView?> queryMemberView(String id);
  Future<List<MemberCompanyView>> queryMemberViews([QueryParams? params]);
}

class _CompanyRepository extends BaseRepository
    with
        RepositoryInsertMixin<CompanyInsertRequest>,
        RepositoryUpdateMixin<CompanyUpdateRequest>,
        RepositoryDeleteMixin<String>
    implements CompanyRepository {
  _CompanyRepository(super.db) : super(tableName: 'companies', keyName: 'id');

  @override
  Future<FullCompanyView?> queryFullView(String id) {
    return queryOne(id, FullCompanyViewQueryable());
  }

  @override
  Future<List<FullCompanyView>> queryFullViews([QueryParams? params]) {
    return queryMany(FullCompanyViewQueryable(), params);
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
  Future<void> insert(List<CompanyInsertRequest> requests) async {
    if (requests.isEmpty) return;
    var values = QueryValues();
    await db.query(
      'INSERT INTO "companies" ( "id", "name" )\n'
      'VALUES ${requests.map((r) => '( ${values.add(r.id)}:text, ${values.add(r.name)}:text )').join(', ')}\n',
      values.values,
    );

    await db.billingAddresses.insertMany(requests.expand((r) {
      return r.addresses.map((rr) => BillingAddressInsertRequest(
          city: rr.city,
          postcode: rr.postcode,
          name: rr.name,
          street: rr.street,
          accountId: null,
          companyId: r.id));
    }).toList());
  }

  @override
  Future<void> update(List<CompanyUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    var values = QueryValues();
    await db.query(
      'UPDATE "companies"\n'
      'SET "name" = COALESCE(UPDATED."name", "companies"."name")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${values.add(r.id)}:text, ${values.add(r.name)}:text )').join(', ')} )\n'
      'AS UPDATED("id", "name")\n'
      'WHERE "companies"."id" = UPDATED."id"',
      values.values,
    );
    await db.billingAddresses.updateMany(requests.where((r) => r.addresses != null).expand((r) {
      return r.addresses!.map((rr) => BillingAddressUpdateRequest(
          city: rr.city, postcode: rr.postcode, name: rr.name, street: rr.street, companyId: r.id));
    }).toList());
  }
}

class CompanyInsertRequest {
  CompanyInsertRequest({
    required this.id,
    required this.name,
    required this.addresses,
  });

  final String id;
  final String name;
  final List<BillingAddress> addresses;
}

class CompanyUpdateRequest {
  CompanyUpdateRequest({
    required this.id,
    this.name,
    this.addresses,
  });

  final String id;
  final String? name;
  final List<BillingAddress>? addresses;
}

class FullCompanyViewQueryable extends KeyedViewQueryable<FullCompanyView, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => TextEncoder.i.encode(key);

  @override
  String get query =>
      'SELECT "companies".*, "addresses"."data" as "addresses", "members"."data" as "members", "invoices"."data" as "invoices", "parties"."data" as "parties"'
      'FROM "companies"'
      'LEFT JOIN ('
      '  SELECT "billing_addresses"."company_id",'
      '    to_jsonb(array_agg("billing_addresses".*)) as data'
      '  FROM (${BillingAddressViewQueryable().query}) "billing_addresses"'
      '  GROUP BY "billing_addresses"."company_id"'
      ') "addresses"'
      'ON "companies"."id" = "addresses"."company_id"'
      'LEFT JOIN ('
      '  SELECT "accounts"."company_id",'
      '    to_jsonb(array_agg("accounts".*)) as data'
      '  FROM (${CompanyAccountViewQueryable().query}) "accounts"'
      '  GROUP BY "accounts"."company_id"'
      ') "members"'
      'ON "companies"."id" = "members"."company_id"'
      'LEFT JOIN ('
      '  SELECT "invoices"."company_id",'
      '    to_jsonb(array_agg("invoices".*)) as data'
      '  FROM (${OwnerInvoiceViewQueryable().query}) "invoices"'
      '  GROUP BY "invoices"."company_id"'
      ') "invoices"'
      'ON "companies"."id" = "invoices"."company_id"'
      'LEFT JOIN ('
      '  SELECT "parties"."sponsor_id",'
      '    to_jsonb(array_agg("parties".*)) as data'
      '  FROM (${CompanyPartyViewQueryable().query}) "parties"'
      '  GROUP BY "parties"."sponsor_id"'
      ') "parties"'
      'ON "companies"."id" = "parties"."sponsor_id"';

  @override
  String get tableAlias => 'companies';

  @override
  FullCompanyView decode(TypedMap map) => FullCompanyView(
      id: map.get('id'),
      name: map.get('name'),
      addresses: map.getListOpt('addresses', BillingAddressViewQueryable().decoder) ?? const [],
      members: map.getListOpt('members', CompanyAccountViewQueryable().decoder) ?? const [],
      invoices: map.getListOpt('invoices', OwnerInvoiceViewQueryable().decoder) ?? const [],
      parties: map.getListOpt('parties', CompanyPartyViewQueryable().decoder) ?? const []);
}

class FullCompanyView {
  FullCompanyView({
    required this.id,
    required this.name,
    required this.addresses,
    required this.members,
    required this.invoices,
    required this.parties,
  });

  final String id;
  final String name;
  final List<BillingAddressView> addresses;
  final List<CompanyAccountView> members;
  final List<OwnerInvoiceView> invoices;
  final List<CompanyPartyView> parties;
}

class MemberCompanyViewQueryable extends KeyedViewQueryable<MemberCompanyView, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => TextEncoder.i.encode(key);

  @override
  String get query => 'SELECT "companies".*, "addresses"."data" as "addresses"'
      'FROM "companies"'
      'LEFT JOIN ('
      '  SELECT "billing_addresses"."company_id",'
      '    to_jsonb(array_agg("billing_addresses".*)) as data'
      '  FROM (${BillingAddressViewQueryable().query}) "billing_addresses"'
      '  GROUP BY "billing_addresses"."company_id"'
      ') "addresses"'
      'ON "companies"."id" = "addresses"."company_id"';

  @override
  String get tableAlias => 'companies';

  @override
  MemberCompanyView decode(TypedMap map) => MemberCompanyView(
      id: map.get('id'),
      name: map.get('name'),
      addresses: map.getListOpt('addresses', BillingAddressViewQueryable().decoder) ?? const []);
}

class MemberCompanyView {
  MemberCompanyView({
    required this.id,
    required this.name,
    required this.addresses,
  });

  final String id;
  final String name;
  final List<BillingAddressView> addresses;
}
