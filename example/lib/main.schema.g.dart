// ignore_for_file: unnecessary_cast, prefer_relative_imports, unused_element, prefer_single_quotes
import 'dart:convert';
import 'package:dartabase/dartabase.dart';
import 'package:dartabase_example/main.dart';
const databaseSchema = DatabaseSchema({
  'accounts': TableSchema(
    'accounts',
    columns: {
      'id': ColumnSchema('id', type: 'text'),
      'first_name': ColumnSchema('first_name', type: 'text'),
      'last_name': ColumnSchema('last_name', type: 'text'),
      'age': ColumnSchema('age', type: 'int8'),
      'gender': ColumnSchema('gender', type: 'text'),
      'vehicles': ColumnSchema('vehicles', type: '_text'),
      'send_invoices_via_email': ColumnSchema('send_invoices_via_email', type: 'bool'),
      'location': ColumnSchema('location', type: 'point'),
      'cards': ColumnSchema('cards', type: '_jsonb'),
      'customer_id': ColumnSchema('customer_id', type: 'text'),
      'company_id': ColumnSchema('company_id', type: 'text', isNullable: true),
    },
    constraints: [
      PrimaryKeyConstraint(null, 'id'),
      ForeignKeyConstraint(null, 'company_id', 'companies', 'id', ForeignKeyAction.setNull, ForeignKeyAction.cascade),
      UniqueConstraint(null, 'company_id'),
    ],
  ),
  'billing_addresses': TableSchema(
    'billing_addresses',
    columns: {
      'account_id': ColumnSchema('account_id', type: 'text', isNullable: true),
      'company_id': ColumnSchema('company_id', type: 'text', isNullable: true),
      'name': ColumnSchema('name', type: 'text'),
      'street': ColumnSchema('street', type: 'text'),
      'city': ColumnSchema('city', type: 'text'),
    },
    constraints: [
      ForeignKeyConstraint(null, 'account_id', 'accounts', 'id', ForeignKeyAction.cascade, ForeignKeyAction.cascade),
      ForeignKeyConstraint(null, 'company_id', 'companies', 'id', ForeignKeyAction.cascade, ForeignKeyAction.cascade),
      UniqueConstraint(null, 'account_id'),
    ],
  ),
  'companies': TableSchema(
    'companies',
    columns: {
      'id': ColumnSchema('id', type: 'text'),
    },
    constraints: [
      PrimaryKeyConstraint(null, 'id'),
    ],
  ),
  
  
});

extension DatabaseTables on Database {
  AccountTable get accounts => AccountTable._instanceFor(this);
  BillingAddressTable get billingAddresses => BillingAddressTable._instanceFor(this);
  CompanyTable get companies => CompanyTable._instanceFor(this);
}

class AccountTable {
  AccountTable._(this._db);
  final Database _db;
  static AccountTable? _instance;
  static AccountTable _instanceFor(Database db) {
    if (_instance == null || _instance!._db != db) {
      _instance = AccountTable._(db);
    }
    return _instance!;
  }

  Future<UserAccountView?> queryUserView(String id) async {
    return (await UserAccountViewQuery().apply(_db, QueryParams(
      where: '"id" = \'$id\'',
      limit: 1,
    ))).firstOrNull;
  }
  
  Future<Account?> queryOne(String id) async {
    return (await AccountQuery().apply(_db, QueryParams(
      where: '"id" = \'$id\'',
      limit: 1,
    ))).firstOrNull;
  }
  
  Future<List<AdminAccountView>> queryAdminViews([QueryParams? params]) {
    return AdminAccountViewQuery().apply(_db, params ?? QueryParams());
  }
  
  Future<void> insertOne(AccountInsertRequest request) {
    return _db.runTransaction(() => AccountInsertAction().apply(_db, [request]));
  }
  
  Future<void> updateOne(AccountUpdateRequest request) {
    return _db.runTransaction(() => AccountUpdateAction().apply(_db, [request]));
  }
  
  Future<void> executeToggleEmailNotification(bool request) {
    return _db.runTransaction(() => ToggleEmailNotification().apply(_db, request));
  }
}

class BillingAddressTable {
  BillingAddressTable._(this._db);
  final Database _db;
  static BillingAddressTable? _instance;
  static BillingAddressTable _instanceFor(Database db) {
    if (_instance == null || _instance!._db != db) {
      _instance = BillingAddressTable._(db);
    }
    return _instance!;
  }

  
}

class CompanyTable {
  CompanyTable._(this._db);
  final Database _db;
  static CompanyTable? _instance;
  static CompanyTable _instanceFor(Database db) {
    if (_instance == null || _instance!._db != db) {
      _instance = CompanyTable._(db);
    }
    return _instance!;
  }

  
}

class UserAccountView {
  UserAccountView(this.id, this.firstName, this.lastName, this.age, this.gender, this.vehicles, this.sendInvoicesViaEmail, this.location, this.cards, this.billingAddress, this.company);
  UserAccountView.fromMap(Map<String, dynamic> map)
    : id = map.get('id'),
      firstName = map.get('first_name'),
      lastName = map.get('last_name'),
      age = map.get('age'),
      gender = map.get('gender'),
      vehicles = map.getList('vehicles'),
      sendInvoicesViaEmail = map.get('send_invoices_via_email'),
      location = map.get('location'),
      cards = map.getList('cards'),
      billingAddress = map.getOpt('billingAddress'),
      company = map.getOpt('company');
  
  String id;
  String firstName;
  String lastName;
  int age;
  String gender;
  List<String> vehicles;
  bool sendInvoicesViaEmail;
  LatLng location;
  List<ChargeCard> cards;
  BillingAddress? billingAddress;
  MemberCompanyView? company;
}

class AdminAccountView {
  AdminAccountView(this.id, this.firstName, this.lastName, this.age, this.gender, this.vehicles, this.sendInvoicesViaEmail, this.location, this.cards, this.customerId, this.billingAddress, this.company);
  AdminAccountView.fromMap(Map<String, dynamic> map)
    : id = map.get('id'),
      firstName = map.get('first_name'),
      lastName = map.get('last_name'),
      age = map.get('age'),
      gender = map.get('gender'),
      vehicles = map.getList('vehicles'),
      sendInvoicesViaEmail = map.get('send_invoices_via_email'),
      location = map.get('location'),
      cards = map.getList('cards'),
      customerId = map.get('customer_id'),
      billingAddress = map.getOpt('billingAddress'),
      company = map.getOpt('company');
  
  String id;
  String firstName;
  String lastName;
  int age;
  String gender;
  List<String> vehicles;
  bool sendInvoicesViaEmail;
  LatLng location;
  List<ChargeCard> cards;
  String customerId;
  BillingAddress? billingAddress;
  MemberCompanyView? company;
}

class CompanyAccountView {
  CompanyAccountView(this.id, this.firstName, this.lastName, this.age, this.gender, this.vehicles, this.sendInvoicesViaEmail, this.location);
  CompanyAccountView.fromMap(Map<String, dynamic> map)
    : id = map.get('id'),
      firstName = map.get('first_name'),
      lastName = map.get('last_name'),
      age = map.get('age'),
      gender = map.get('gender'),
      vehicles = map.getList('vehicles'),
      sendInvoicesViaEmail = map.get('send_invoices_via_email'),
      location = map.get('location');
  
  String id;
  String firstName;
  String lastName;
  int age;
  String gender;
  List<String> vehicles;
  bool sendInvoicesViaEmail;
  LatLng location;
}

class MemberCompanyView {
  MemberCompanyView(this.id, this.addresses);
  MemberCompanyView.fromMap(Map<String, dynamic> map)
    : id = map.get('id'),
      addresses = map.getList('addresses');
  
  String id;
  List<BillingAddress> addresses;
}

class QueryParams {
  String? where;
  String? orderBy;
  int? limit;
  int? offset;
  QueryParams({this.where, this.orderBy, this.limit, this.offset});
}

class UserAccountViewQuery implements Query<List<UserAccountView>, QueryParams> {
  @override
  Future<List<UserAccountView>> apply(Database db, QueryParams params) async {
    var time = DateTime.now();
    var res = await db.query("""
      ${_getQueryStatement()}
      ${params.where != null ? "WHERE ${params.where}" : ""}
      ${params.orderBy != null ? "ORDER BY ${params.orderBy}" : ""}
      ${params.limit != null ? "LIMIT ${params.limit}" : ""}
      ${params.offset != null ? "OFFSET ${params.offset}" : ""}
    """);
    
    var results = res.map((row) => _decode<UserAccountView>(row.toColumnMap())).toList();
    print('Queried ${results.length} rows in ${DateTime.now().difference(time)}');
    return results;
  }
  
  static String _getQueryStatement() {
    return """
      SELECT "accounts".* , row_to_json("billingAddress".*) as "billingAddress", row_to_json("company".*) as "company"
      FROM "accounts"
      LEFT JOIN (
        ${BillingAddressQuery._getQueryStatement()}
      ) "billingAddress"
      ON "accounts"."id" = "billingAddress"."account_id"
      LEFT JOIN (
        ${MemberCompanyViewQuery._getQueryStatement()}
      ) "company"
      ON "accounts"."company_id" = "company"."id"
    """;
  }
}

class BillingAddressQuery implements Query<List<BillingAddress>, QueryParams> {
  @override
  Future<List<BillingAddress>> apply(Database db, QueryParams params) async {
    var time = DateTime.now();
    var res = await db.query("""
      ${_getQueryStatement()}
      ${params.where != null ? "WHERE ${params.where}" : ""}
      ${params.orderBy != null ? "ORDER BY ${params.orderBy}" : ""}
      ${params.limit != null ? "LIMIT ${params.limit}" : ""}
      ${params.offset != null ? "OFFSET ${params.offset}" : ""}
    """);
    
    var results = res.map((row) => _decode<BillingAddress>(row.toColumnMap())).toList();
    print('Queried ${results.length} rows in ${DateTime.now().difference(time)}');
    return results;
  }
  
  static String _getQueryStatement() {
    return """
      SELECT "billing_addresses".* 
      FROM "billing_addresses"
      
    """;
  }
}

extension BillingAddressDecoder on BillingAddress {
  static BillingAddress fromMap(Map<String, dynamic> map) {
    return BillingAddress(map.get('name'), map.get('street'), map.get('city'));
  }
}

class MemberCompanyViewQuery implements Query<List<MemberCompanyView>, QueryParams> {
  @override
  Future<List<MemberCompanyView>> apply(Database db, QueryParams params) async {
    var time = DateTime.now();
    var res = await db.query("""
      ${_getQueryStatement()}
      ${params.where != null ? "WHERE ${params.where}" : ""}
      ${params.orderBy != null ? "ORDER BY ${params.orderBy}" : ""}
      ${params.limit != null ? "LIMIT ${params.limit}" : ""}
      ${params.offset != null ? "OFFSET ${params.offset}" : ""}
    """);
    
    var results = res.map((row) => _decode<MemberCompanyView>(row.toColumnMap())).toList();
    print('Queried ${results.length} rows in ${DateTime.now().difference(time)}');
    return results;
  }
  
  static String _getQueryStatement() {
    return """
      SELECT "companies".* , row_to_json("addresses".*) as "addresses"
      FROM "companies"
      LEFT JOIN (
        SELECT "billing_addresses"."company_id",
          array_to_json(array_agg(row_to_json("billing_addresses"))) as data
        FROM ( ${BillingAddressQuery._getQueryStatement()} ) "billing_addresses"
        GROUP BY "billing_addresses"."company_id"
      ) "addresses"
      ON "companies"."id" = "addresses"."company_id"
    """;
  }
}

class AccountQuery implements Query<List<Account>, QueryParams> {
  @override
  Future<List<Account>> apply(Database db, QueryParams params) async {
    var time = DateTime.now();
    var res = await db.query("""
      ${_getQueryStatement()}
      ${params.where != null ? "WHERE ${params.where}" : ""}
      ${params.orderBy != null ? "ORDER BY ${params.orderBy}" : ""}
      ${params.limit != null ? "LIMIT ${params.limit}" : ""}
      ${params.offset != null ? "OFFSET ${params.offset}" : ""}
    """);
    
    var results = res.map((row) => _decode<Account>(row.toColumnMap())).toList();
    print('Queried ${results.length} rows in ${DateTime.now().difference(time)}');
    return results;
  }
  
  static String _getQueryStatement() {
    return """
      SELECT "accounts".* , row_to_json("billingAddress".*) as "billingAddress", row_to_json("company".*) as "company"
      FROM "accounts"
      LEFT JOIN (
        ${BillingAddressQuery._getQueryStatement()}
      ) "billingAddress"
      ON "accounts"."id" = "billingAddress"."account_id"
      LEFT JOIN (
        ${CompanyQuery._getQueryStatement()}
      ) "company"
      ON "accounts"."company_id" = "company"."id"
    """;
  }
}

class CompanyQuery implements Query<List<Company>, QueryParams> {
  @override
  Future<List<Company>> apply(Database db, QueryParams params) async {
    var time = DateTime.now();
    var res = await db.query("""
      ${_getQueryStatement()}
      ${params.where != null ? "WHERE ${params.where}" : ""}
      ${params.orderBy != null ? "ORDER BY ${params.orderBy}" : ""}
      ${params.limit != null ? "LIMIT ${params.limit}" : ""}
      ${params.offset != null ? "OFFSET ${params.offset}" : ""}
    """);
    
    var results = res.map((row) => _decode<Company>(row.toColumnMap())).toList();
    print('Queried ${results.length} rows in ${DateTime.now().difference(time)}');
    return results;
  }
  
  static String _getQueryStatement() {
    return """
      SELECT "companies".* , row_to_json("addresses".*) as "addresses"
      FROM "companies"
      LEFT JOIN (
        SELECT "billing_addresses"."company_id",
          array_to_json(array_agg(row_to_json("billing_addresses"))) as data
        FROM ( ${BillingAddressQuery._getQueryStatement()} ) "billing_addresses"
        GROUP BY "billing_addresses"."company_id"
      ) "addresses"
      ON "companies"."id" = "addresses"."company_id"
    """;
  }
}

extension CompanyDecoder on Company {
  static Company fromMap(Map<String, dynamic> map) {
    return Company(map.get('id'), map.getList('addresses'));
  }
}

extension AccountDecoder on Account {
  static Account fromMap(Map<String, dynamic> map) {
    return Account(map.get('id'), map.get('first_name'), map.get('last_name'), map.get('age'), map.get('gender'), map.getList('vehicles'), map.get('send_invoices_via_email'), map.get('location'), map.getList('cards'), map.get('customer_id'), map.getOpt('billingAddress'), map.getOpt('company'));
  }
}

class AdminAccountViewQuery implements Query<List<AdminAccountView>, QueryParams> {
  @override
  Future<List<AdminAccountView>> apply(Database db, QueryParams params) async {
    var time = DateTime.now();
    var res = await db.query("""
      ${_getQueryStatement()}
      ${params.where != null ? "WHERE ${params.where}" : ""}
      ${params.orderBy != null ? "ORDER BY ${params.orderBy}" : ""}
      ${params.limit != null ? "LIMIT ${params.limit}" : ""}
      ${params.offset != null ? "OFFSET ${params.offset}" : ""}
    """);
    
    var results = res.map((row) => _decode<AdminAccountView>(row.toColumnMap())).toList();
    print('Queried ${results.length} rows in ${DateTime.now().difference(time)}');
    return results;
  }
  
  static String _getQueryStatement() {
    return """
      SELECT "accounts".* , row_to_json("billingAddress".*) as "billingAddress", row_to_json("company".*) as "company"
      FROM "accounts"
      LEFT JOIN (
        ${BillingAddressQuery._getQueryStatement()}
      ) "billingAddress"
      ON "accounts"."id" = "billingAddress"."account_id"
      LEFT JOIN (
        ${MemberCompanyViewQuery._getQueryStatement()}
      ) "company"
      ON "accounts"."company_id" = "company"."id"
    """;
  }
}



class AccountInsertRequest {
  String id;
  String firstName;
  String lastName;
  int age;
  String gender;
  List<String> vehicles;
  bool sendInvoicesViaEmail;
  LatLng location;
  List<ChargeCard> cards;
  String customerId;
  BillingAddress? billingAddress;
  String? companyId;
  
  AccountInsertRequest(this.id, this.firstName, this.lastName, this.age, this.gender, this.vehicles, this.sendInvoicesViaEmail, this.location, this.cards, this.customerId, this.billingAddress, this.companyId);
}

class AccountInsertAction implements Action<List<AccountInsertRequest>> {
  @override
  Future<void> apply(Database db, List<AccountInsertRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query("""
      INSERT INTO "accounts" ( "id", "first_name", "last_name", "age", "gender", "vehicles", "send_invoices_via_email", "location", "cards", "customer_id", "company_id" )
      VALUES ${requests.map((r) => '( ${_encode(r.id)}, ${_encode(r.firstName)}, ${_encode(r.lastName)}, ${_encode(r.age)}, ${_encode(r.gender)}, ${_encode(r.vehicles)}, ${_encode(r.sendInvoicesViaEmail)}, ${_encode(r.location)}, ${_encode(r.cards)}, ${_encode(r.customerId)}, ${_encode(r.companyId)} )')}
      ON CONFLICT ( "id" ) DO UPDATE SET "first_name" = EXCLUDED."first_name", "last_name" = EXCLUDED."last_name", "age" = EXCLUDED."age", "gender" = EXCLUDED."gender", "vehicles" = EXCLUDED."vehicles", "send_invoices_via_email" = EXCLUDED."send_invoices_via_email", "location" = EXCLUDED."location", "cards" = EXCLUDED."cards", "customer_id" = EXCLUDED."customer_id", "company_id" = EXCLUDED."company_id"
    """);

    await BillingAddressInsertAction().apply(db, requests.where((r) => r.billingAddress != null).map((r) {
      return BillingAddressInsertRequest(r.id, null, r.billingAddress!.name, r.billingAddress!.street, r.billingAddress!.city);
    }).toList());
  }
}

class BillingAddressInsertRequest {
  String? accountId;
  String? companyId;
  String name;
  String street;
  String city;
  
  BillingAddressInsertRequest(this.accountId, this.companyId, this.name, this.street, this.city);
}

class BillingAddressInsertAction implements Action<List<BillingAddressInsertRequest>> {
  @override
  Future<void> apply(Database db, List<BillingAddressInsertRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query("""
      INSERT INTO "billing_addresses" ( "account_id", "company_id", "name", "street", "city" )
      VALUES ${requests.map((r) => '( ${_encode(r.accountId)}, ${_encode(r.companyId)}, ${_encode(r.name)}, ${_encode(r.street)}, ${_encode(r.city)} )')}
      ON CONFLICT ( "account_id" ) DO UPDATE SET "name" = EXCLUDED."name", "street" = EXCLUDED."street", "city" = EXCLUDED."city"
    """);
  }
}

class AccountUpdateRequest {
  String id;
  String? firstName;
  String? lastName;
  int? age;
  String? gender;
  List<String>? vehicles;
  bool? sendInvoicesViaEmail;
  LatLng? location;
  List<ChargeCard>? cards;
  String? customerId;
  BillingAddress? billingAddress;
  String? companyId;
  
  AccountUpdateRequest(this.id, this.firstName, this.lastName, this.age, this.gender, this.vehicles, this.sendInvoicesViaEmail, this.location, this.cards, this.customerId, this.billingAddress, this.companyId);
}

class AccountUpdateAction implements Action<List<AccountUpdateRequest>> {
  @override
  Future<void> apply(Database db, List<AccountUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query("""
      UPDATE "accounts"
      SET "first_name" = COALESCE(UPDATED."first_name", "accounts"."first_name"),
          "last_name" = COALESCE(UPDATED."last_name", "accounts"."last_name"),
          "age" = COALESCE(UPDATED."age", "accounts"."age"),
          "gender" = COALESCE(UPDATED."gender", "accounts"."gender"),
          "vehicles" = COALESCE(UPDATED."vehicles", "accounts"."vehicles"),
          "send_invoices_via_email" = COALESCE(UPDATED."send_invoices_via_email", "accounts"."send_invoices_via_email"),
          "location" = COALESCE(UPDATED."location", "accounts"."location"),
          "cards" = COALESCE(UPDATED."cards", "accounts"."cards"),
          "customer_id" = COALESCE(UPDATED."customer_id", "accounts"."customer_id"),
          "company_id" = COALESCE(UPDATED."company_id", "accounts"."company_id")
      FROM ( VALUES ${requests.map((r) => '( ${db.enc(r.id)}, ${db.enc(r.firstName)}, ${db.enc(r.lastName)}, ${db.enc(r.age)}, ${db.enc(r.gender)}, ${db.enc(r.vehicles)}, ${db.enc(r.sendInvoicesViaEmail)}, ${db.enc(r.location)}, ${db.enc(r.cards)}, ${db.enc(r.customerId)}, ${db.enc(r.companyId)} )').join(', ')} )
      AS UPDATED("id", "first_name", "last_name", "age", "gender", "vehicles", "send_invoices_via_email", "location", "cards", "customer_id", "company_id")
      WHERE "id" = UPDATED."id"
    """);

    await BillingAddressUpdateAction().apply(db, requests.where((r) => r.billingAddress != null).map((r) {
      return BillingAddressUpdateRequest(r.id, null, r.billingAddress!.name, r.billingAddress!.street, r.billingAddress!.city);
    }).toList());
  }
}

class BillingAddressUpdateRequest {
  String? accountId;
  String? companyId;
  String? name;
  String? street;
  String? city;
  
  BillingAddressUpdateRequest(this.accountId, this.companyId, this.name, this.street, this.city);
}

class BillingAddressUpdateAction implements Action<List<BillingAddressUpdateRequest>> {
  @override
  Future<void> apply(Database db, List<BillingAddressUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query("""
      UPDATE "billing_addresses"
      SET "name" = COALESCE(UPDATED."name", "billing_addresses"."name"),
          "street" = COALESCE(UPDATED."street", "billing_addresses"."street"),
          "city" = COALESCE(UPDATED."city", "billing_addresses"."city")
      FROM ( VALUES ${requests.map((r) => '( ${db.enc(r.accountId)}, ${db.enc(r.companyId)}, ${db.enc(r.name)}, ${db.enc(r.street)}, ${db.enc(r.city)} )').join(', ')} )
      AS UPDATED("account_id", "company_id", "name", "street", "city")
      WHERE "account_id" = UPDATED."account_id" AND "company_id" = UPDATED."company_id"
    """);
  }
}



var _typeConverters = <Type, TypeConverter>{
  _typeOf<LatLng>(): LatLngConverter(),
};
var _decoders = <Type, Function>{
  _typeOf<UserAccountView>(): (Map<String, dynamic> v) => UserAccountView.fromMap(v),
  _typeOf<AdminAccountView>(): (Map<String, dynamic> v) => AdminAccountView.fromMap(v),
  _typeOf<CompanyAccountView>(): (Map<String, dynamic> v) => CompanyAccountView.fromMap(v),
  _typeOf<MemberCompanyView>(): (Map<String, dynamic> v) => MemberCompanyView.fromMap(v),
  _typeOf<BillingAddress>(): (Map<String, dynamic> v) => BillingAddressDecoder.fromMap(v),
  _typeOf<Company>(): (Map<String, dynamic> v) => CompanyDecoder.fromMap(v),
  _typeOf<Account>(): (Map<String, dynamic> v) => AccountDecoder.fromMap(v),
};


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

dynamic _encode(dynamic value) {
  if (value == null) return null;
  try {
    return PostgresTextEncoder().convert(value);
  } catch (_) {
    if (_typeConverters[value.runtimeType] != null) {
      var encoded = _typeConverters[value.runtimeType]!.encode(value);
      return PostgresTextEncoder().convert(encoded);
    } else {
      throw ConverterException('Cannot encode value $value of type ${value.runtimeType}. Unknown type. Did you forgot to include the class or register a custom type converter?');
    }
  }
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
      throw ConverterException(
          'Parameter ${this[key]} with key $key is not a List');
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
