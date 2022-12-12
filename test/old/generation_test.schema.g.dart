// ignore_for_file: prefer_relative_imports
import 'package:stormberry/internals.dart';

import 'generation_test.dart';

extension Repositories on Database {
  UserRepository get users => UserRepository._(this);
  AccountRepository get accounts => AccountRepository._(this);
  LegacyAccountRepository get legacyAccounts => LegacyAccountRepository._(this);
}

final registry = ModelRegistry({
  typeOf<EnumValue>(): EnumTypeConverter<EnumValue>(EnumValue.values),
  typeOf<CustomEnumValue>(): CustomEnumConverter(),
});

abstract class UserRepository
    implements
        ModelRepository,
        ModelRepositoryInsert<UserInsertRequest>,
        ModelRepositoryUpdate<UserUpdateRequest>,
        ModelRepositoryDelete<String> {
  factory UserRepository._(Database db) = _UserRepository;

  Future<User?> queryUser(String id);
  Future<List<User>> queryUsers([QueryParams? params]);
}

class _UserRepository extends BaseRepository
    with
        RepositoryInsertMixin<UserInsertRequest>,
        RepositoryUpdateMixin<UserUpdateRequest>,
        RepositoryDeleteMixin<String>
    implements UserRepository {
  _UserRepository(Database db) : super(db: db);

  @override
  Future<User?> queryUser(String id) {
    return queryOne(id, UserQueryable());
  }

  @override
  Future<List<User>> queryUsers([QueryParams? params]) {
    return queryMany(UserQueryable(), params);
  }

  @override
  Future<void> insert(Database db, List<UserInsertRequest> requests) async {
    if (requests.isEmpty) return;

    await db.query(
      'INSERT INTO "users" ( "id", "name", "account_id", "enum_value", "custom_enum_value" )\n'
      'VALUES ${requests.map((r) => '( ${registry.encode(r.id)}, ${registry.encode(r.name)}, ${registry.encode(r.accountId)}, ${registry.encode(r.enumValue)}, ${registry.encode(r.customEnumValue)} )').join(', ')}\n'
      'ON CONFLICT ( "id" ) DO UPDATE SET "name" = EXCLUDED."name", "account_id" = EXCLUDED."account_id", "enum_value" = EXCLUDED."enum_value", "custom_enum_value" = EXCLUDED."custom_enum_value"',
    );
  }

  @override
  Future<void> update(Database db, List<UserUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query(
      'UPDATE "users"\n'
      'SET "name" = COALESCE(UPDATED."name"::text, "users"."name"), "account_id" = COALESCE(UPDATED."account_id"::text, "users"."account_id"), "enum_value" = COALESCE(UPDATED."enum_value"::jsonb, "users"."enum_value"), "custom_enum_value" = COALESCE(UPDATED."custom_enum_value"::int8, "users"."custom_enum_value")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${registry.encode(r.id)}, ${registry.encode(r.name)}, ${registry.encode(r.accountId)}, ${registry.encode(r.enumValue)}, ${registry.encode(r.customEnumValue)} )').join(', ')} )\n'
      'AS UPDATED("id", "name", "account_id", "enum_value", "custom_enum_value")\n'
      'WHERE "users"."id" = UPDATED."id"',
    );
  }

  @override
  Future<void> delete(Database db, List<String> keys) async {
    if (keys.isEmpty) return;
    await db.query(
      'DELETE FROM "users"\n'
      'WHERE "users"."id" IN ( ${keys.map((k) => registry.encode(k)).join(',')} )',
    );
  }
}

abstract class AccountRepository
    implements
        ModelRepository,
        ModelRepositoryInsert<AccountInsertRequest>,
        ModelRepositoryUpdate<AccountUpdateRequest>,
        ModelRepositoryDelete<String> {
  factory AccountRepository._(Database db) = _AccountRepository;

  Future<SuperSecretAccountView?> querySuperSecretView(String id);
  Future<List<SuperSecretAccountView>> querySuperSecretViews([QueryParams? params]);
}

class _AccountRepository extends BaseRepository
    with
        RepositoryInsertMixin<AccountInsertRequest>,
        RepositoryUpdateMixin<AccountUpdateRequest>,
        RepositoryDeleteMixin<String>
    implements AccountRepository {
  _AccountRepository(Database db) : super(db: db);

  @override
  Future<SuperSecretAccountView?> querySuperSecretView(String id) {
    return queryOne(id, SuperSecretAccountViewQueryable());
  }

  @override
  Future<List<SuperSecretAccountView>> querySuperSecretViews([QueryParams? params]) {
    return queryMany(SuperSecretAccountViewQueryable(), params);
  }

  @override
  Future<void> insert(Database db, List<AccountInsertRequest> requests) async {
    if (requests.isEmpty) return;

    await db.query(
      'INSERT INTO "accounts" ( "id" )\n'
      'VALUES ${requests.map((r) => '( ${registry.encode(r.id)} )').join(', ')}\n'
      'ON CONFLICT ( "id" ) DO UPDATE SET ',
    );
  }

  @override
  Future<void> update(Database db, List<AccountUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query(
      'UPDATE "accounts"\n'
      'SET \n'
      'FROM ( VALUES ${requests.map((r) => '( ${registry.encode(r.id)} )').join(', ')} )\n'
      'AS UPDATED("id")\n'
      'WHERE "accounts"."id" = UPDATED."id"',
    );
  }

  @override
  Future<void> delete(Database db, List<String> keys) async {
    if (keys.isEmpty) return;
    await db.query(
      'DELETE FROM "accounts"\n'
      'WHERE "accounts"."id" IN ( ${keys.map((k) => registry.encode(k)).join(',')} )',
    );
  }
}

abstract class LegacyAccountRepository
    implements
        ModelRepository,
        ModelRepositoryInsert<LegacyAccountInsertRequest>,
        ModelRepositoryUpdate<LegacyAccountUpdateRequest>,
        ModelRepositoryDelete<String> {
  factory LegacyAccountRepository._(Database db) = _LegacyAccountRepository;

  Future<LegacyAccount?> queryLegacyAccount(String id);
  Future<List<LegacyAccount>> queryLegacyAccounts([QueryParams? params]);
}

class _LegacyAccountRepository extends BaseRepository
    with
        RepositoryInsertMixin<LegacyAccountInsertRequest>,
        RepositoryUpdateMixin<LegacyAccountUpdateRequest>,
        RepositoryDeleteMixin<String>
    implements LegacyAccountRepository {
  _LegacyAccountRepository(Database db) : super(db: db);

  @override
  Future<LegacyAccount?> queryLegacyAccount(String id) {
    return queryOne(id, LegacyAccountQueryable());
  }

  @override
  Future<List<LegacyAccount>> queryLegacyAccounts([QueryParams? params]) {
    return queryMany(LegacyAccountQueryable(), params);
  }

  @override
  Future<void> insert(Database db, List<LegacyAccountInsertRequest> requests) async {
    if (requests.isEmpty) return;

    await db.query(
      'INSERT INTO "customTableName" ( "id" )\n'
      'VALUES ${requests.map((r) => '( ${registry.encode(r.id)} )').join(', ')}\n'
      'ON CONFLICT ( "id" ) DO UPDATE SET ',
    );
  }

  @override
  Future<void> update(Database db, List<LegacyAccountUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query(
      'UPDATE "customTableName"\n'
      'SET \n'
      'FROM ( VALUES ${requests.map((r) => '( ${registry.encode(r.id)} )').join(', ')} )\n'
      'AS UPDATED("id")\n'
      'WHERE "customTableName"."id" = UPDATED."id"',
    );
  }

  @override
  Future<void> delete(Database db, List<String> keys) async {
    if (keys.isEmpty) return;
    await db.query(
      'DELETE FROM "customTableName"\n'
      'WHERE "customTableName"."id" IN ( ${keys.map((k) => registry.encode(k)).join(',')} )',
    );
  }
}

class UserInsertRequest {
  UserInsertRequest(
      {required this.id,
      required this.name,
      required this.accountId,
      required this.enumValue,
      required this.customEnumValue});
  String id;
  String name;
  String accountId;
  EnumValue enumValue;
  CustomEnumValue customEnumValue;
}

class AccountInsertRequest {
  AccountInsertRequest({required this.id});
  String id;
}

class LegacyAccountInsertRequest {
  LegacyAccountInsertRequest({required this.id});
  String id;
}

class UserUpdateRequest {
  UserUpdateRequest({required this.id, this.name, this.accountId, this.enumValue, this.customEnumValue});
  String id;
  String? name;
  String? accountId;
  EnumValue? enumValue;
  CustomEnumValue? customEnumValue;
}

class AccountUpdateRequest {
  AccountUpdateRequest({required this.id});
  String id;
}

class LegacyAccountUpdateRequest {
  LegacyAccountUpdateRequest({required this.id});
  String id;
}

class UserQueryable extends KeyedViewQueryable<User, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => registry.encode(key);

  @override
  String get tableName => 'users_view';

  @override
  String get tableAlias => 'users';

  @override
  User decode(TypedMap map) => UserView(
      id: map.get('id', registry.decode),
      name: map.get('name', registry.decode),
      account: map.get('account', AccountQueryable().decoder),
      enumValue: map.get('enum_value', registry.decode),
      customEnumValue: map.get('custom_enum_value', registry.decode));
}

class UserView implements User {
  UserView(
      {required this.id,
      required this.name,
      required this.account,
      required this.enumValue,
      required this.customEnumValue});

  @override
  final String id;
  @override
  final String name;
  @override
  final Account account;
  @override
  final EnumValue enumValue;
  @override
  final CustomEnumValue customEnumValue;
}

class SuperSecretAccountViewQueryable extends KeyedViewQueryable<SuperSecretAccountView, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => registry.encode(key);

  @override
  String get tableName => 'super_secret_accounts_view';

  @override
  String get tableAlias => 'accounts';

  @override
  SuperSecretAccountView decode(TypedMap map) => SuperSecretAccountView(id: map.get('id', registry.decode));
}

class SuperSecretAccountView {
  SuperSecretAccountView({required this.id});

  final String id;
}

class AccountQueryable extends KeyedViewQueryable<Account, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => registry.encode(key);

  @override
  String get tableName => 'accounts_view';

  @override
  String get tableAlias => 'accounts';

  @override
  Account decode(TypedMap map) => AccountView(id: map.get('id', registry.decode));
}

class AccountView implements Account {
  AccountView({required this.id});

  @override
  final String id;
}

class LegacyAccountQueryable extends KeyedViewQueryable<LegacyAccount, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => registry.encode(key);

  @override
  String get tableName => 'custom_table_name_view';

  @override
  String get tableAlias => 'customTableName';

  @override
  LegacyAccount decode(TypedMap map) => LegacyAccountView(id: map.get('id', registry.decode));
}

class LegacyAccountView implements LegacyAccount {
  LegacyAccountView({required this.id});

  @override
  final String id;
}
