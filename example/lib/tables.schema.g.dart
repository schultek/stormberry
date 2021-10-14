// ignore_for_file: unnecessary_cast, prefer_relative_imports, unused_element, prefer_single_quotes
import 'dart:convert';
import 'package:stormberry/stormberry.dart';
import 'package:stormberry_example/tables.dart';

extension DatabaseTables on Database {
  AccountTable get accounts => BaseTable.get(this, () => AccountTable._(this));
  BillingAddressTable get billingAddresses => BaseTable.get(this, () => BillingAddressTable._(this));
  CompanyTable get companies => BaseTable.get(this, () => CompanyTable._(this));
  InvoiceTable get invoices => BaseTable.get(this, () => InvoiceTable._(this));
  PartyTable get parties => BaseTable.get(this, () => PartyTable._(this));
}

class AccountTable extends BaseTable {
  AccountTable._(Database db) : super(db);

  Future<UserAccountView?> queryUserView(String id) async {
    return queryOne(id, "user_accounts_view", "accounts", "id");
  }
  
  Future<List<AdminAccountView>> queryAdminViews([QueryParams? params]) {
    return queryMany(params ?? QueryParams(), "admin_accounts_view", "accounts");
  }
  
  Future<void> insertOne(AccountInsertRequest request) {
    return run(AccountInsertAction(), [request]);
  }
  
  Future<void> updateOne(AccountUpdateRequest request) {
    return run(AccountUpdateAction(), [request]);
  }
}

class BillingAddressTable extends BaseTable {
  BillingAddressTable._(Database db) : super(db);

  
}

class CompanyTable extends BaseTable {
  CompanyTable._(Database db) : super(db);

  Future<AdminCompanyView?> queryAdminView(String id) async {
    return queryOne(id, "admin_companies_view", "companies", "id");
  }
  
  Future<void> insertOne(CompanyInsertRequest request) {
    return run(CompanyInsertAction(), [request]);
  }
  
  Future<void> deleteOne(String id) {
    return run(CompanyDeleteAction(), [id]);
  }
}

class InvoiceTable extends BaseTable {
  InvoiceTable._(Database db) : super(db);

  
}

class PartyTable extends BaseTable {
  PartyTable._(Database db) : super(db);

  
}

class UserAccountView {
  UserAccountView(this.id, this.firstName, this.lastName, this.location, this.billingAddress, this.company, this.invoices, this.parties);
  UserAccountView.fromMap(Map<String, dynamic> map)
    : id = map.get('id'),
      firstName = map.get('first_name'),
      lastName = map.get('last_name'),
      location = map.get('location'),
      billingAddress = map.getOpt('billingAddress'),
      company = map.getOpt('company'),
      invoices = map.getListOpt('invoices') ?? const [],
      parties = map.getListOpt('parties') ?? const [];
  
  String id;
  String firstName;
  String lastName;
  LatLng location;
  BillingAddress? billingAddress;
  MemberCompanyView? company;
  List<OwnerInvoiceView> invoices;
  List<GuestPartyView> parties;
}

class AdminAccountView {
  AdminAccountView(this.id, this.firstName, this.lastName, this.location, this.billingAddress, this.company, this.invoices, this.parties);
  AdminAccountView.fromMap(Map<String, dynamic> map)
    : id = map.get('id'),
      firstName = map.get('first_name'),
      lastName = map.get('last_name'),
      location = map.get('location'),
      billingAddress = map.getOpt('billingAddress'),
      company = map.getOpt('company'),
      invoices = map.getListOpt('invoices') ?? const [],
      parties = map.getListOpt('parties') ?? const [];
  
  String id;
  String firstName;
  String lastName;
  LatLng location;
  BillingAddress? billingAddress;
  MemberCompanyView? company;
  List<OwnerInvoiceView> invoices;
  List<GuestPartyView> parties;
}

class CompanyAccountView {
  CompanyAccountView(this.id, this.firstName, this.lastName, this.location, this.parties);
  CompanyAccountView.fromMap(Map<String, dynamic> map)
    : id = map.get('id'),
      firstName = map.get('first_name'),
      lastName = map.get('last_name'),
      location = map.get('location'),
      parties = map.getListOpt('parties') ?? const [];
  
  String id;
  String firstName;
  String lastName;
  LatLng location;
  List<CompanyPartyView> parties;
}
extension BillingAddressDecoder on BillingAddress {
  static BillingAddress fromMap(Map<String, dynamic> map) {
    return BillingAddress(map.get('name'), map.get('street'), map.get('postcode'), map.get('city'));
  }
}
class AdminCompanyView {
  AdminCompanyView(this.members, this.id, this.name, this.addresses, this.invoices, this.parties);
  AdminCompanyView.fromMap(Map<String, dynamic> map)
    : members = map.getListOpt('members') ?? const [],
      id = map.get('id'),
      name = map.get('name'),
      addresses = map.getListOpt('addresses') ?? const [],
      invoices = map.getListOpt('invoices') ?? const [],
      parties = map.getListOpt('parties') ?? const [];
  
  List<CompanyAccountView> members;
  String id;
  String name;
  List<BillingAddress> addresses;
  List<OwnerInvoiceView> invoices;
  List<CompanyPartyView> parties;
}

class MemberCompanyView {
  MemberCompanyView(this.id, this.name, this.addresses);
  MemberCompanyView.fromMap(Map<String, dynamic> map)
    : id = map.get('id'),
      name = map.get('name'),
      addresses = map.getListOpt('addresses') ?? const [];
  
  String id;
  String name;
  List<BillingAddress> addresses;
}
class OwnerInvoiceView {
  OwnerInvoiceView(this.id, this.title, this.invoiceId);
  OwnerInvoiceView.fromMap(Map<String, dynamic> map)
    : id = map.get('id'),
      title = map.get('title'),
      invoiceId = map.get('invoice_id');
  
  String id;
  String title;
  String invoiceId;
}
class GuestPartyView {
  GuestPartyView(this.sponsor, this.id, this.name, this.date);
  GuestPartyView.fromMap(Map<String, dynamic> map)
    : sponsor = map.getOpt('sponsor'),
      id = map.get('id'),
      name = map.get('name'),
      date = map.get('date');
  
  MemberCompanyView? sponsor;
  String id;
  String name;
  int date;
}

class CompanyPartyView {
  CompanyPartyView(this.id, this.name, this.date);
  CompanyPartyView.fromMap(Map<String, dynamic> map)
    : id = map.get('id'),
      name = map.get('name'),
      date = map.get('date');
  
  String id;
  String name;
  int date;
}

class AccountInsertRequest {
  String id;
  String firstName;
  String lastName;
  LatLng location;
  BillingAddress? billingAddress;
  String? companyId;
  
  AccountInsertRequest({required this.id, required this.firstName, required this.lastName, required this.location, this.billingAddress, this.companyId});
}

class AccountInsertAction implements Action<List<AccountInsertRequest>> {
  @override
  Future<void> apply(Database db, List<AccountInsertRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query("""
      INSERT INTO "accounts" ( "id", "first_name", "last_name", "location", "company_id" )
      VALUES ${requests.map((r) => '( ${_encode(r.id)}, ${_encode(r.firstName)}, ${_encode(r.lastName)}, ${_encode(r.location)}, ${_encode(r.companyId)} )').join(', ')}
      ON CONFLICT ( "id" ) DO UPDATE SET "first_name" = EXCLUDED."first_name", "last_name" = EXCLUDED."last_name", "location" = EXCLUDED."location", "company_id" = EXCLUDED."company_id"
    """);

    await BillingAddressInsertAction().apply(db, requests.where((r) => r.billingAddress != null).map((r) {
      return BillingAddressInsertRequest(accountId: r.id, companyId: null, name: r.billingAddress!.name, street: r.billingAddress!.street, postcode: r.billingAddress!.postcode, city: r.billingAddress!.city);
    }).toList());
  }
}

class BillingAddressInsertRequest {
  String? accountId;
  String? companyId;
  String name;
  String street;
  String postcode;
  String city;
  
  BillingAddressInsertRequest({this.accountId, this.companyId, required this.name, required this.street, required this.postcode, required this.city});
}

class BillingAddressInsertAction implements Action<List<BillingAddressInsertRequest>> {
  @override
  Future<void> apply(Database db, List<BillingAddressInsertRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query("""
      INSERT INTO "billing_addresses" ( "account_id", "company_id", "name", "street", "postcode", "city" )
      VALUES ${requests.map((r) => '( ${_encode(r.accountId)}, ${_encode(r.companyId)}, ${_encode(r.name)}, ${_encode(r.street)}, ${_encode(r.postcode)}, ${_encode(r.city)} )').join(', ')}
      ON CONFLICT ( "account_id" ) DO UPDATE SET "name" = EXCLUDED."name", "street" = EXCLUDED."street", "postcode" = EXCLUDED."postcode", "city" = EXCLUDED."city"
    """);
  }
}

class AccountUpdateRequest {
  String id;
  String? firstName;
  String? lastName;
  LatLng? location;
  BillingAddress? billingAddress;
  String? companyId;
  
  AccountUpdateRequest({required this.id, this.firstName, this.lastName, this.location, this.billingAddress, this.companyId});
}

class AccountUpdateAction implements Action<List<AccountUpdateRequest>> {
  @override
  Future<void> apply(Database db, List<AccountUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query("""
      UPDATE "accounts"
      SET "first_name" = COALESCE(UPDATED."first_name"::text, "accounts"."first_name"),
          "last_name" = COALESCE(UPDATED."last_name"::text, "accounts"."last_name"),
          "location" = COALESCE(UPDATED."location"::point, "accounts"."location"),
          "company_id" = COALESCE(UPDATED."company_id"::text, "accounts"."company_id")
      FROM ( VALUES ${requests.map((r) => '( ${_encode(r.id)}, ${_encode(r.firstName)}, ${_encode(r.lastName)}, ${_encode(r.location)}, ${_encode(r.companyId)} )').join(', ')} )
      AS UPDATED("id", "first_name", "last_name", "location", "company_id")
      WHERE "accounts"."id" = UPDATED."id"
    """);

    await BillingAddressUpdateAction().apply(db, requests.where((r) => r.billingAddress != null).map((r) {
      return BillingAddressUpdateRequest(accountId: r.id, name: r.billingAddress!.name, street: r.billingAddress!.street, postcode: r.billingAddress!.postcode, city: r.billingAddress!.city);
    }).toList());
  }
}

class BillingAddressUpdateRequest {
  String? accountId;
  String? companyId;
  String? name;
  String? street;
  String? postcode;
  String? city;
  
  BillingAddressUpdateRequest({this.accountId, this.companyId, this.name, this.street, this.postcode, this.city});
}

class BillingAddressUpdateAction implements Action<List<BillingAddressUpdateRequest>> {
  @override
  Future<void> apply(Database db, List<BillingAddressUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query("""
      UPDATE "billing_addresses"
      SET "name" = COALESCE(UPDATED."name"::text, "billing_addresses"."name"),
          "street" = COALESCE(UPDATED."street"::text, "billing_addresses"."street"),
          "postcode" = COALESCE(UPDATED."postcode"::text, "billing_addresses"."postcode"),
          "city" = COALESCE(UPDATED."city"::text, "billing_addresses"."city")
      FROM ( VALUES ${requests.map((r) => '( ${_encode(r.accountId)}, ${_encode(r.companyId)}, ${_encode(r.name)}, ${_encode(r.street)}, ${_encode(r.postcode)}, ${_encode(r.city)} )').join(', ')} )
      AS UPDATED("account_id", "company_id", "name", "street", "postcode", "city")
      WHERE "billing_addresses"."account_id" = UPDATED."account_id" AND "billing_addresses"."company_id" = UPDATED."company_id"
    """);
  }
}

class CompanyInsertRequest {
  String id;
  String name;
  List<BillingAddress> addresses;
  
  CompanyInsertRequest({required this.id, required this.name, required this.addresses});
}

class CompanyInsertAction implements Action<List<CompanyInsertRequest>> {
  @override
  Future<void> apply(Database db, List<CompanyInsertRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query("""
      INSERT INTO "companies" ( "id", "name" )
      VALUES ${requests.map((r) => '( ${_encode(r.id)}, ${_encode(r.name)} )').join(', ')}
      ON CONFLICT ( "id" ) DO UPDATE SET "name" = EXCLUDED."name"
    """);

    await BillingAddressInsertAction().apply(db, requests.expand((r) {
      return r.addresses.map((rr) => BillingAddressInsertRequest(accountId: null, companyId: r.id, name: rr.name, street: rr.street, postcode: rr.postcode, city: rr.city));
    }).toList());
  }
}

class CompanyDeleteAction implements Action<List<String>> {
  @override
  Future<void> apply(Database db, List<String> keys) async {
    if (keys.isEmpty) return;
    await db.query("""
      DELETE FROM "companies"
      WHERE "companies"."id" IN ( ${keys.map((k) => _encode(k)).join(',')} )
    """);
  }
}



var _typeConverters = <Type, TypeConverter>{
  // primitive converters
  _typeOf<dynamic>():  _PrimitiveTypeConverter((dynamic v) => v),
  _typeOf<String>():   _PrimitiveTypeConverter<String>((dynamic v) => v.toString()),
  _typeOf<int>():      _PrimitiveTypeConverter<int>((dynamic v) => num.parse(v.toString()).round()),
  _typeOf<double>():   _PrimitiveTypeConverter<double>((dynamic v) => double.parse(v.toString())),
  _typeOf<num>():      _PrimitiveTypeConverter<num>((dynamic v) => num.parse(v.toString())),
  _typeOf<bool>():     _PrimitiveTypeConverter<bool>((dynamic v) => v is num ? v != 0 : v.toString() == 'true'),
  _typeOf<DateTime>(): _DateTimeConverter(),
  // generated converters
  _typeOf<LatLng>(): LatLngConverter(),
};
var _decoders = <Type, Function>{
  _typeOf<UserAccountView>(): (Map<String, dynamic> v) => UserAccountView.fromMap(v),
  _typeOf<AdminAccountView>(): (Map<String, dynamic> v) => AdminAccountView.fromMap(v),
  _typeOf<CompanyAccountView>(): (Map<String, dynamic> v) => CompanyAccountView.fromMap(v),
  _typeOf<BillingAddress>(): (Map<String, dynamic> v) => BillingAddressDecoder.fromMap(v),
  _typeOf<AdminCompanyView>(): (Map<String, dynamic> v) => AdminCompanyView.fromMap(v),
  _typeOf<MemberCompanyView>(): (Map<String, dynamic> v) => MemberCompanyView.fromMap(v),
  _typeOf<OwnerInvoiceView>(): (Map<String, dynamic> v) => OwnerInvoiceView.fromMap(v),
  _typeOf<GuestPartyView>(): (Map<String, dynamic> v) => GuestPartyView.fromMap(v),
  _typeOf<CompanyPartyView>(): (Map<String, dynamic> v) => CompanyPartyView.fromMap(v),
};


class BaseTable {
  static final _tables = <Type, BaseTable>{};

  final Database _db;
  BaseTable(this._db);

  static T get<T extends BaseTable>(Database db, T Function() fn) {
    return _tables[T]?._db == db ? _tables[T]! as T : _tables[T] = fn();
  }
  
  Future<T?> queryOne<T>(dynamic key, String table, String name, String keyName) async {
    var params = QueryParams(where: '"$name"."$keyName" = ${_encode(key)}', limit: 1);
    return (await query(BasicQuery<T>(table, name), params)).firstOrNull;
  }

  Future<List<T>> queryMany<T>(QueryParams params, String table, String name) {
    return query(BasicQuery<T>(table, name), params);
  }
  
  Future<T> query<T, U>(Query<T, U> query, U params) {
    return query.apply(_db, params);
  }
  
  Future<void> run<T>(Action<T> action, T request) {
    return _db.runTransaction(() => action.apply(_db, request));
  }
}

class QueryParams {
  String? where;
  String? orderBy;
  int? limit;
  int? offset;
  
  QueryParams({this.where, this.orderBy, this.limit, this.offset});
}
        
class BasicQuery<Result> implements Query<List<Result>, QueryParams> {
  BasicQuery(this.table, this.name);

  final String table;
  final String name;

  @override
  Future<List<Result>> apply(Database db, QueryParams params) async {
    var time = DateTime.now();
    var res = await db.query("""
      SELECT * FROM "$table" "$name"
      ${params.where != null ? "WHERE ${params.where}" : ""}
      ${params.orderBy != null ? "ORDER BY ${params.orderBy}" : ""}
      ${params.limit != null ? "LIMIT ${params.limit}" : ""}
      ${params.offset != null ? "OFFSET ${params.offset}" : ""}
    """);

    var results = res.map((row) => _decode<Result>(row.toColumnMap())).toList();
    print('Queried ${results.length} rows in ${DateTime.now().difference(time)}');
    return results;
  }
}

Type _typeOf<T>() => T;

T _decode<T>(dynamic value) {
  if (value.runtimeType == T) {
    return value as T;
  } else {
    if (_decoders[T] != null && value is String) {
      return _decoders[T]!(jsonDecode(value)) as T;
    } else if (_decoders[T] != null && value is Map<String, dynamic>) {
      return _decoders[T]!(value) as T;
    } else if (_typeConverters[T] != null) {
      return _typeConverters[T]!.decode(value) as T;
    } else {
      throw ConverterException('Cannot decode value $value of type ${value.runtimeType} to type $T. Unknown type. Did you forgot to include the class or register a custom type converter?');
    }
  }
}

String? _encode(dynamic value, {bool escape = true}) {
  if (value == null) return null;
  try {
    var encoded = PostgresTextEncoder().convert(value);
    if (!escape) return encoded;
    if (value is Map) return "'${encoded.replaceAll("'", "''")}'";
    return value is List || value is PgPoint ? "'$encoded'" : encoded;
  } catch (_) {
    try {
      if (_typeConverters[value.runtimeType] != null) {
        return _encode(_typeConverters[value.runtimeType]!.encode(value), escape: escape);
      } else if (value is List) {
        return _encode(value.map((v) => _encode(v, escape: false)).toList(), escape: escape);
      } else {
        throw ConverterException('');
      }
    } catch (_) {
      throw ConverterException('Cannot encode value $value of type ${value.runtimeType}. Unknown type. Did you forgot to include the class or register a custom type converter?');
    }
  }
}

class _PrimitiveTypeConverter<T> implements TypeConverter<T> {
  const _PrimitiveTypeConverter(this.decoder);
  final T Function(dynamic value) decoder;
  
  @override dynamic encode(T value) => value;
  @override T decode(dynamic value) => decoder(value);
  @override String? get type => throw UnimplementedError();
}

class _DateTimeConverter implements TypeConverter<DateTime> {
 
  @override
  DateTime decode(dynamic d) {
    if (d is String) {
      return DateTime.parse(d);
    } else if (d is num) {
      return DateTime.fromMillisecondsSinceEpoch(d.round());
    } else {
      throw ConverterException('Cannot decode value of type ${d.runtimeType} to type DateTime, because a value of type String or num is expected.');
    }
  }

  @override String encode(DateTime self) => self.toUtc().toIso8601String();

  @override
  String? get type => throw UnimplementedError();
}

extension on Map<String, dynamic> {
  T get<T>(String key) {
    if (this[key] == null) {
      throw ConverterException('Parameter $key is required.');
    }
    return _decode<T>(this[key]!);
  }

  T? getOpt<T>(String key) {
    if (this[key] == null) {
      return null;
    }
    return get<T>(key);
  }

  List<T> getList<T>(String key) {
    if (this[key] == null) {
      throw ConverterException('Parameter $key is required.');
    } else if (this[key] is! List) {
      throw ConverterException('Parameter $key is not a List');
    }
    List value = this[key] as List<dynamic>;
    return value.map((dynamic item) => _decode<T>(item)).toList();
  }

  List<T>? getListOpt<T>(String key) {
    if (this[key] == null) {
      return null;
    }
    return getList<T>(key);
  }

  Map<K, V> getMap<K, V>(String key) {
    if (this[key] == null) {
      throw ConverterException('Parameter $key is required.');
    } else if (this[key] is! Map) {
      throw ConverterException(
          'Parameter ${this[key]} with key $key is not a Map');
    }
    Map value = this[key] as Map<dynamic, dynamic>;
    return value.map((dynamic key, dynamic value) =>
        MapEntry(_decode<K>(key), _decode<V>(value)));
  }

  Map<K, V>? getMapOpt<K, V>(String key) {
    if (this[key] == null) {
      return null;
    }
    return getMap<K, V>(key);
  }
}

class ConverterException implements Exception {
  final String message;
  const ConverterException(this.message);

  @override
  String toString() => 'ConverterException: $message';
}
