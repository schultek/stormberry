part of 'address.dart';

extension AddressRepositories on Database {
  BillingAddressRepository get billingAddresses => BillingAddressRepository._(this);
}

abstract class BillingAddressRepository
    implements
        ModelRepository,
        ModelRepositoryInsert<BillingAddressInsertRequest>,
        ModelRepositoryUpdate<BillingAddressUpdateRequest> {
  factory BillingAddressRepository._(Database db) = _BillingAddressRepository;

  Future<List<BillingAddress>> queryBillingAddresses([QueryParams? params]);
}

class _BillingAddressRepository extends BaseRepository
    with RepositoryInsertMixin<BillingAddressInsertRequest>, RepositoryUpdateMixin<BillingAddressUpdateRequest>
    implements BillingAddressRepository {
  _BillingAddressRepository(super.db) : super(tableName: 'billing_addresses');

  @override
  Future<List<BillingAddress>> queryBillingAddresses([QueryParams? params]) {
    return queryMany(BillingAddressQueryable(), params);
  }

  @override
  Future<void> insert(List<BillingAddressInsertRequest> requests) async {
    if (requests.isEmpty) return;

    var values = QueryValues();
    await db.query(
      'INSERT INTO "billing_addresses" ( "company_id", "account_id", "city", "postcode", "name", "street" )\n'
      'VALUES ${requests.map((r) => '( ${values.add(r.companyId)}, ${values.add(r.accountId)}, ${values.add(r.city)}, ${values.add(r.postcode)}, ${values.add(r.name)}, ${values.add(r.street)} )').join(', ')}\n',
      values.values,
    );
  }

  @override
  Future<void> update(List<BillingAddressUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    var values = QueryValues();
    await db.query(
      'UPDATE "billing_addresses"\n'
      'SET "city" = COALESCE(UPDATED."city"::text, "billing_addresses"."city"), "postcode" = COALESCE(UPDATED."postcode"::text, "billing_addresses"."postcode"), "name" = COALESCE(UPDATED."name"::text, "billing_addresses"."name"), "street" = COALESCE(UPDATED."street"::text, "billing_addresses"."street")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${values.add(r.companyId)}, ${values.add(r.accountId)}, ${values.add(r.city)}, ${values.add(r.postcode)}, ${values.add(r.name)}, ${values.add(r.street)} )').join(', ')} )\n'
      'AS UPDATED("company_id", "account_id", "city", "postcode", "name", "street")\n'
      'WHERE "billing_addresses"."company_id" = UPDATED."company_id" AND "billing_addresses"."account_id" = UPDATED."account_id"',
      values.values,
    );
  }
}

class BillingAddressInsertRequest {
  BillingAddressInsertRequest({
    this.companyId,
    this.accountId,
    required this.city,
    required this.postcode,
    required this.name,
    required this.street,
  });

  String? companyId;
  int? accountId;
  String city;
  String postcode;
  String name;
  String street;
}

class BillingAddressUpdateRequest {
  BillingAddressUpdateRequest({
    this.companyId,
    this.accountId,
    this.city,
    this.postcode,
    this.name,
    this.street,
  });

  String? companyId;
  int? accountId;
  String? city;
  String? postcode;
  String? name;
  String? street;
}

class BillingAddressQueryable extends ViewQueryable<BillingAddress> {
  @override
  String get query => 'SELECT "billing_addresses".*'
      'FROM "billing_addresses"';

  @override
  String get tableAlias => 'billing_addresses';

  @override
  BillingAddress decode(TypedMap map) => BillingAddressView(
      city: map.get('city', TextEncoder.i.decode),
      postcode: map.get('postcode', TextEncoder.i.decode),
      name: map.get('name', TextEncoder.i.decode),
      street: map.get('street', TextEncoder.i.decode));
}

class BillingAddressView implements BillingAddress {
  BillingAddressView({
    required this.city,
    required this.postcode,
    required this.name,
    required this.street,
  });

  @override
  final String city;
  @override
  final String postcode;
  @override
  final String name;
  @override
  final String street;
}
