// ignore_for_file: annotate_overrides

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

  Future<List<BillingAddressView>> queryBillingAddresses([QueryParams? params]);
}

class _BillingAddressRepository extends BaseRepository
    with
        RepositoryInsertMixin<BillingAddressInsertRequest>,
        RepositoryUpdateMixin<BillingAddressUpdateRequest>
    implements BillingAddressRepository {
  _BillingAddressRepository(super.db) : super(tableName: 'billing_addresses');

  @override
  Future<List<BillingAddressView>> queryBillingAddresses([QueryParams? params]) {
    return queryMany(BillingAddressViewQueryable(), params);
  }

  @override
  Future<void> insert(List<BillingAddressInsertRequest> requests) async {
    if (requests.isEmpty) return;
    var values = QueryValues();
    await db.query(
      'INSERT INTO "billing_addresses" ( "city", "postcode", "name", "street", "account_id", "company_id" )\n'
      'VALUES ${requests.map((r) => '( ${values.add(r.city)}:text, ${values.add(r.postcode)}:text, ${values.add(r.name)}:text, ${values.add(r.street)}:text, ${values.add(r.accountId)}:int8, ${values.add(r.companyId)}:text )').join(', ')}\n',
      values.values,
    );
  }

  @override
  Future<void> update(List<BillingAddressUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    var values = QueryValues();
    await db.query(
      'UPDATE "billing_addresses"\n'
      'SET "city" = COALESCE(UPDATED."city", "billing_addresses"."city"), "postcode" = COALESCE(UPDATED."postcode", "billing_addresses"."postcode"), "name" = COALESCE(UPDATED."name", "billing_addresses"."name"), "street" = COALESCE(UPDATED."street", "billing_addresses"."street")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${values.add(r.city)}:text, ${values.add(r.postcode)}:text, ${values.add(r.name)}:text, ${values.add(r.street)}:text, ${values.add(r.accountId)}:int8, ${values.add(r.companyId)}:text )').join(', ')} )\n'
      'AS UPDATED("city", "postcode", "name", "street", "account_id", "company_id")\n'
      'WHERE "billing_addresses"."account_id" = UPDATED."account_id" AND "billing_addresses"."company_id" = UPDATED."company_id"',
      values.values,
    );
  }
}

class BillingAddressInsertRequest {
  BillingAddressInsertRequest({
    required this.city,
    required this.postcode,
    required this.name,
    required this.street,
    this.accountId,
    this.companyId,
  });

  final String city;
  final String postcode;
  final String name;
  final String street;
  final int? accountId;
  final String? companyId;
}

class BillingAddressUpdateRequest {
  BillingAddressUpdateRequest({
    this.city,
    this.postcode,
    this.name,
    this.street,
    this.accountId,
    this.companyId,
  });

  final String? city;
  final String? postcode;
  final String? name;
  final String? street;
  final int? accountId;
  final String? companyId;
}

class BillingAddressViewQueryable extends ViewQueryable<BillingAddressView> {
  @override
  String get query => 'SELECT "billing_addresses".*'
      'FROM "billing_addresses"';

  @override
  String get tableAlias => 'billing_addresses';

  @override
  BillingAddressView decode(TypedMap map) => BillingAddressView(
      city: map.get('city'),
      postcode: map.get('postcode'),
      name: map.get('name'),
      street: map.get('street'));
}

class BillingAddressView implements BillingAddress {
  BillingAddressView({
    required this.city,
    required this.postcode,
    required this.name,
    required this.street,
  });

  final String city;
  final String postcode;
  final String name;
  final String street;
}
