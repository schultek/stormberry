part of 'company.dart';

extension Repositories on Database {
  CompanyRepository get companies => CompanyRepository._(this);
}

final registry = ModelRegistry();

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
  _CompanyRepository(Database db) : super(db: db);

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

class CompanyInsertRequest {
  CompanyInsertRequest({required this.id, required this.name, required this.addresses});
  String id;
  String name;
  List<BillingAddress> addresses;
}

class CompanyUpdateRequest {
  CompanyUpdateRequest({required this.id, this.name, this.addresses});
  String id;
  String? name;
  List<BillingAddress>? addresses;
}

class FullCompanyViewQueryable extends KeyedViewQueryable<FullCompanyView, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => registry.encode(key);

  @override
  String get tableName => 'full_companies_view';

  @override
  String get tableAlias => 'companies';

  @override
  FullCompanyView decode(TypedMap map) => FullCompanyView(
      invoices: map.getListOpt('invoices', OwnerInvoiceViewQueryable().decoder) ?? const [],
      parties: map.getListOpt('parties', CompanyPartyViewQueryable().decoder) ?? const [],
      members: map.getListOpt('members', CompanyAccountViewQueryable().decoder) ?? const [],
      id: map.get('id', registry.decode),
      name: map.get('name', registry.decode),
      addresses: map.getListOpt('addresses', BillingAddressQueryable().decoder) ?? const []);
}

class FullCompanyView {
  FullCompanyView({
    required this.invoices,
    required this.parties,
    required this.members,
    required this.id,
    required this.name,
    required this.addresses,
  });

  final List<OwnerInvoiceView> invoices;
  final List<CompanyPartyView> parties;
  final List<CompanyAccountView> members;
  final String id;
  final String name;
  final List<BillingAddress> addresses;
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
