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
      'location': ColumnSchema('location', type: 'point'),
      'company_id': ColumnSchema('company_id', type: 'text', isNullable: true),
    },
    constraints: [
      PrimaryKeyConstraint(null, 'id'),
      ForeignKeyConstraint(null, 'company_id', 'companies', 'id', ForeignKeyAction.setNull, ForeignKeyAction.cascade),
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
      'party_id': ColumnSchema('party_id', type: 'text', isNullable: true),
      'id': ColumnSchema('id', type: 'text'),
    },
    constraints: [
      PrimaryKeyConstraint(null, 'id'),
      ForeignKeyConstraint(null, 'party_id', 'parties', 'id', ForeignKeyAction.setNull, ForeignKeyAction.cascade),
      UniqueConstraint(null, 'party_id'),
    ],
  ),
  'invoices': TableSchema(
    'invoices',
    columns: {
      'account_id': ColumnSchema('account_id', type: 'text', isNullable: true),
      'company_id': ColumnSchema('company_id', type: 'text', isNullable: true),
      'id': ColumnSchema('id', type: 'text'),
      'title': ColumnSchema('title', type: 'text'),
      'invoice_id': ColumnSchema('invoice_id', type: 'text'),
    },
    constraints: [
      PrimaryKeyConstraint(null, 'id'),
      ForeignKeyConstraint(null, 'account_id', 'accounts', 'id', ForeignKeyAction.setNull, ForeignKeyAction.cascade),
      ForeignKeyConstraint(null, 'company_id', 'companies', 'id', ForeignKeyAction.setNull, ForeignKeyAction.cascade),
    ],
  ),
  'parties': TableSchema(
    'parties',
    columns: {
      'id': ColumnSchema('id', type: 'text'),
      'name': ColumnSchema('name', type: 'text'),
      'sponsor_id': ColumnSchema('sponsor_id', type: 'text', isNullable: true),
    },
    constraints: [
      PrimaryKeyConstraint(null, 'id'),
      ForeignKeyConstraint(null, 'sponsor_id', 'companies', 'id', ForeignKeyAction.setNull, ForeignKeyAction.cascade),
      UniqueConstraint(null, 'sponsor_id'),
    ],
  ),
  
  'accounts_parties': TableSchema(
    'accounts_parties',
    columns: {
      'account_id': ColumnSchema('account_id', type: 'text'),
      'party_id': ColumnSchema('party_id', type: 'text'),
    },
    constraints: [
      PrimaryKeyConstraint(null, 'account_id", "party_id'),
      ForeignKeyConstraint(null, 'account_id', 'accounts', 'id', ForeignKeyAction.cascade, ForeignKeyAction.cascade),
      ForeignKeyConstraint(null, 'party_id', 'parties', 'id', ForeignKeyAction.cascade, ForeignKeyAction.cascade),
    ],
  ),
  
});

extension DatabaseTables on Database {
  AccountTable get accounts => AccountTable._instanceFor(this);
  BillingAddressTable get billingAddresses => BillingAddressTable._instanceFor(this);
  CompanyTable get companies => CompanyTable._instanceFor(this);
  InvoiceTable get invoices => InvoiceTable._instanceFor(this);
  PartyTable get parties => PartyTable._instanceFor(this);
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
      where: '"accounts"."id" = \'$id\'',
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

class InvoiceTable {
  InvoiceTable._(this._db);
  final Database _db;
  static InvoiceTable? _instance;
  static InvoiceTable _instanceFor(Database db) {
    if (_instance == null || _instance!._db != db) {
      _instance = InvoiceTable._(db);
    }
    return _instance!;
  }

  
}

class PartyTable {
  PartyTable._(this._db);
  final Database _db;
  static PartyTable? _instance;
  static PartyTable _instanceFor(Database db) {
    if (_instance == null || _instance!._db != db) {
      _instance = PartyTable._(db);
    }
    return _instance!;
  }

  
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
      invoices = map.getList('invoices'),
      parties = map.getList('parties');
  
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
      invoices = map.getList('invoices'),
      parties = map.getList('parties');
  
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
  CompanyAccountView(this.id, this.firstName, this.lastName, this.location);
  CompanyAccountView.fromMap(Map<String, dynamic> map)
    : id = map.get('id'),
      firstName = map.get('first_name'),
      lastName = map.get('last_name'),
      location = map.get('location');
  
  String id;
  String firstName;
  String lastName;
  LatLng location;
}

class AdminCompanyView {
  AdminCompanyView(this.members, this.id, this.addresses, this.invoices);
  AdminCompanyView.fromMap(Map<String, dynamic> map)
    : members = map.getList('members'),
      id = map.get('id'),
      addresses = map.getList('addresses'),
      invoices = map.getList('invoices');
  
  List<CompanyAccountView> members;
  String id;
  List<BillingAddress> addresses;
  List<OwnerInvoiceView> invoices;
}

class MemberCompanyView {
  MemberCompanyView(this.id, this.addresses);
  MemberCompanyView.fromMap(Map<String, dynamic> map)
    : id = map.get('id'),
      addresses = map.getList('addresses');
  
  String id;
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
  GuestPartyView(this.id, this.name, this.sponsor);
  GuestPartyView.fromMap(Map<String, dynamic> map)
    : id = map.get('id'),
      name = map.get('name'),
      sponsor = map.getOpt('sponsor');
  
  String id;
  String name;
  MemberCompanyView? sponsor;
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
      SELECT "accounts".* , row_to_json("billingAddress".*) as "billingAddress", row_to_json("company".*) as "company", row_to_json("invoices".*) as "invoices", row_to_json("parties".*) as "parties"
      FROM "accounts"
      LEFT JOIN ( ${BillingAddressQuery._getQueryStatement()} ) "billingAddress"
      ON "accounts"."id" = "billingAddress"."account_id"
      LEFT JOIN ( ${MemberCompanyViewQuery._getQueryStatement()} ) "company"
      ON "accounts"."company_id" = "company"."id"
      LEFT JOIN (
        SELECT "invoices"."account_id",
          array_to_json(array_agg(row_to_json("invoices"))) as data
        FROM ( ${OwnerInvoiceViewQuery._getQueryStatement()} ) "invoices"
        GROUP BY "invoices"."account_id"
      ) "invoices"
      ON "accounts"."id" = "invoices"."account_id"
      LEFT JOIN (
        SELECT "accounts_parties"."account_id",
          array_to_json(array_agg(row_to_json("parties"))) as data
        FROM "accounts_parties"
        LEFT JOIN ( ${GuestPartyViewQuery._getQueryStatement()} ) "parties"
        ON "parties"."id" = "accounts_parties"."party_id"
        GROUP BY "accounts_parties"."account_id"
      ) "parties"
      ON "accounts"."id" = "parties"."account_id"
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

class OwnerInvoiceViewQuery implements Query<List<OwnerInvoiceView>, QueryParams> {
  @override
  Future<List<OwnerInvoiceView>> apply(Database db, QueryParams params) async {
    var time = DateTime.now();
    var res = await db.query("""
      ${_getQueryStatement()}
      ${params.where != null ? "WHERE ${params.where}" : ""}
      ${params.orderBy != null ? "ORDER BY ${params.orderBy}" : ""}
      ${params.limit != null ? "LIMIT ${params.limit}" : ""}
      ${params.offset != null ? "OFFSET ${params.offset}" : ""}
    """);
    
    var results = res.map((row) => _decode<OwnerInvoiceView>(row.toColumnMap())).toList();
    print('Queried ${results.length} rows in ${DateTime.now().difference(time)}');
    return results;
  }
  
  static String _getQueryStatement() {
    return """
      SELECT "invoices".* 
      FROM "invoices"
      
    """;
  }
}

class GuestPartyViewQuery implements Query<List<GuestPartyView>, QueryParams> {
  @override
  Future<List<GuestPartyView>> apply(Database db, QueryParams params) async {
    var time = DateTime.now();
    var res = await db.query("""
      ${_getQueryStatement()}
      ${params.where != null ? "WHERE ${params.where}" : ""}
      ${params.orderBy != null ? "ORDER BY ${params.orderBy}" : ""}
      ${params.limit != null ? "LIMIT ${params.limit}" : ""}
      ${params.offset != null ? "OFFSET ${params.offset}" : ""}
    """);
    
    var results = res.map((row) => _decode<GuestPartyView>(row.toColumnMap())).toList();
    print('Queried ${results.length} rows in ${DateTime.now().difference(time)}');
    return results;
  }
  
  static String _getQueryStatement() {
    return """
      SELECT "parties".* , row_to_json("sponsor".*) as "sponsor"
      FROM "parties"
      LEFT JOIN ( ${MemberCompanyViewQuery._getQueryStatement()} ) "sponsor"
      ON "parties"."sponsor_id" = "sponsor"."id"
    """;
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
      SELECT "accounts".* , row_to_json("billingAddress".*) as "billingAddress", row_to_json("company".*) as "company", row_to_json("invoices".*) as "invoices", row_to_json("parties".*) as "parties"
      FROM "accounts"
      LEFT JOIN ( ${BillingAddressQuery._getQueryStatement()} ) "billingAddress"
      ON "accounts"."id" = "billingAddress"."account_id"
      LEFT JOIN ( ${MemberCompanyViewQuery._getQueryStatement()} ) "company"
      ON "accounts"."company_id" = "company"."id"
      LEFT JOIN (
        SELECT "invoices"."account_id",
          array_to_json(array_agg(row_to_json("invoices"))) as data
        FROM ( ${OwnerInvoiceViewQuery._getQueryStatement()} ) "invoices"
        GROUP BY "invoices"."account_id"
      ) "invoices"
      ON "accounts"."id" = "invoices"."account_id"
      LEFT JOIN (
        SELECT "accounts_parties"."account_id",
          array_to_json(array_agg(row_to_json("parties"))) as data
        FROM "accounts_parties"
        LEFT JOIN ( ${GuestPartyViewQuery._getQueryStatement()} ) "parties"
        ON "parties"."id" = "accounts_parties"."party_id"
        GROUP BY "accounts_parties"."account_id"
      ) "parties"
      ON "accounts"."id" = "parties"."account_id"
    """;
  }
}





class AccountInsertRequest {
  String id;
  String firstName;
  String lastName;
  LatLng location;
  BillingAddress? billingAddress;
  String? companyId;
  
  AccountInsertRequest(this.id, this.firstName, this.lastName, this.location, this.billingAddress, this.companyId);
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
      VALUES ${requests.map((r) => '( ${_encode(r.accountId)}, ${_encode(r.companyId)}, ${_encode(r.name)}, ${_encode(r.street)}, ${_encode(r.city)} )').join(', ')}
      ON CONFLICT ( "account_id" ) DO UPDATE SET "name" = EXCLUDED."name", "street" = EXCLUDED."street", "city" = EXCLUDED."city"
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
      SET "first_name" = COALESCE(UPDATED."first_name", "accounts"."first_name"),
          "last_name" = COALESCE(UPDATED."last_name", "accounts"."last_name"),
          "location" = COALESCE(UPDATED."location", "accounts"."location"),
          "company_id" = COALESCE(UPDATED."company_id", "accounts"."company_id")
      FROM ( VALUES ${requests.map((r) => '( ${_encode(r.id)}, ${_encode(r.firstName)}, ${_encode(r.lastName)}, ${_encode(r.location)}, ${_encode(r.companyId)} )').join(', ')} )
      AS UPDATED("id", "first_name", "last_name", "location", "company_id")
      WHERE "id" = UPDATED."id"
    """);

    await BillingAddressUpdateAction().apply(db, requests.where((r) => r.billingAddress != null).map((r) {
      return BillingAddressUpdateRequest(accountId: r.id, name: r.billingAddress!.name, street: r.billingAddress!.street, city: r.billingAddress!.city);
    }).toList());
  }
}

class BillingAddressUpdateRequest {
  String? accountId;
  String? companyId;
  String? name;
  String? street;
  String? city;
  
  BillingAddressUpdateRequest({this.accountId, this.companyId, this.name, this.street, this.city});
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
      FROM ( VALUES ${requests.map((r) => '( ${_encode(r.accountId)}, ${_encode(r.companyId)}, ${_encode(r.name)}, ${_encode(r.street)}, ${_encode(r.city)} )').join(', ')} )
      AS UPDATED("account_id", "company_id", "name", "street", "city")
      WHERE "account_id" = UPDATED."account_id" AND "company_id" = UPDATED."company_id"
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
  _typeOf<AdminCompanyView>(): (Map<String, dynamic> v) => AdminCompanyView.fromMap(v),
  _typeOf<MemberCompanyView>(): (Map<String, dynamic> v) => MemberCompanyView.fromMap(v),
  _typeOf<OwnerInvoiceView>(): (Map<String, dynamic> v) => OwnerInvoiceView.fromMap(v),
  _typeOf<GuestPartyView>(): (Map<String, dynamic> v) => GuestPartyView.fromMap(v),
  _typeOf<BillingAddress>(): (Map<String, dynamic> v) => BillingAddressDecoder.fromMap(v),
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
    var encoded = PostgresTextEncoder().convert(value);
    if (value is List) {
      return "'$encoded'";
    } else {
      return encoded;
    }
  } catch (_) {
    if (_typeConverters[value.runtimeType] != null) {
      var encoded = _typeConverters[value.runtimeType]!.encode(value);
      return PostgresTextEncoder().convert(encoded);
    } else {
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
      var v = this[key];
      if (v is Map<String, dynamic> && v['data'] is List) {
        return v.getList<T>('data');
      } else {
        throw ConverterException(
            'Parameter $v with key $key is not a List');
      }
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
