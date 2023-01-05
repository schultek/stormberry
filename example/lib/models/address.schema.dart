part of 'address.dart';

extension Repositories on Database {
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
  _BillingAddressRepository(Database db) : super(db: db);

  @override
  Future<List<BillingAddress>> queryBillingAddresses([QueryParams? params]) {
    return queryMany(BillingAddressQueryable(), params);
  }

  @override
  Future<void> insert(Database db, List<BillingAddressInsertRequest> requests) async {
    if (requests.isEmpty) return;

    await db.query(
      'INSERT INTO "billing_addresses" ( "account_id", "company_id", "city", "postcode", "name", "street" )\n'
      'VALUES ${requests.map((r) => '( ${TypeEncoder.i.encode(r.accountId)}, ${TypeEncoder.i.encode(r.companyId)}, ${TypeEncoder.i.encode(r.city)}, ${TypeEncoder.i.encode(r.postcode)}, ${TypeEncoder.i.encode(r.name)}, ${TypeEncoder.i.encode(r.street)} )').join(', ')}\n'
      'ON CONFLICT ( "account_id" ) DO UPDATE SET "city" = EXCLUDED."city", "postcode" = EXCLUDED."postcode", "name" = EXCLUDED."name", "street" = EXCLUDED."street"',
    );
  }

  @override
  Future<void> update(Database db, List<BillingAddressUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query(
      'UPDATE "billing_addresses"\n'
      'SET "city" = COALESCE(UPDATED."city"::text, "billing_addresses"."city"), "postcode" = COALESCE(UPDATED."postcode"::text, "billing_addresses"."postcode"), "name" = COALESCE(UPDATED."name"::text, "billing_addresses"."name"), "street" = COALESCE(UPDATED."street"::text, "billing_addresses"."street")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${TypeEncoder.i.encode(r.accountId)}, ${TypeEncoder.i.encode(r.companyId)}, ${TypeEncoder.i.encode(r.city)}, ${TypeEncoder.i.encode(r.postcode)}, ${TypeEncoder.i.encode(r.name)}, ${TypeEncoder.i.encode(r.street)} )').join(', ')} )\n'
      'AS UPDATED("account_id", "company_id", "city", "postcode", "name", "street")\n'
      'WHERE "billing_addresses"."account_id" = UPDATED."account_id" AND "billing_addresses"."company_id" = UPDATED."company_id"',
    );
  }
}

class BillingAddressInsertRequest {
  BillingAddressInsertRequest({
    this.accountId,
    this.companyId,
    required this.city,
    required this.postcode,
    required this.name,
    required this.street,
  });

  int? accountId;
  String? companyId;
  String city;
  String postcode;
  String name;
  String street;
}

class BillingAddressUpdateRequest {
  BillingAddressUpdateRequest({
    this.accountId,
    this.companyId,
    this.city,
    this.postcode,
    this.name,
    this.street,
  });

  int? accountId;
  String? companyId;
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
      city: map.get('city', TypeEncoder.i.decode),
      postcode: map.get('postcode', TypeEncoder.i.decode),
      name: map.get('name', TypeEncoder.i.decode),
      street: map.get('street', TypeEncoder.i.decode));
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
