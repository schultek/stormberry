// ignore_for_file: prefer_relative_imports
import 'package:stormberry/internals.dart';
import 'package:serialization_test/models.dart';

extension Repositories on Database {
  UserRepository get users => UserRepository._(this);
  CompanyRepository get companies => CompanyRepository._(this);
}

final registry = ModelRegistry({});

abstract class UserRepository
    implements
        ModelRepository,
        ModelRepositoryInsert<UserInsertRequest>,
        ModelRepositoryUpdate<UserUpdateRequest>,
        ModelRepositoryDelete<String> {
  factory UserRepository._(Database db) = _UserRepository;

  Future<DefaultUserView?> queryDefaultView(String id);
  Future<List<DefaultUserView>> queryDefaultViews([QueryParams? params]);
  Future<PublicUserView?> queryPublicView(String id);
  Future<List<PublicUserView>> queryPublicViews([QueryParams? params]);
}

class _UserRepository extends BaseRepository
    with
        RepositoryInsertMixin<UserInsertRequest>,
        RepositoryUpdateMixin<UserUpdateRequest>,
        RepositoryDeleteMixin<String>
    implements UserRepository {
  _UserRepository(Database db) : super(db: db);

  @override
  Future<DefaultUserView?> queryDefaultView(String id) {
    return queryOne(id, DefaultUserViewQueryable());
  }

  @override
  Future<List<DefaultUserView>> queryDefaultViews([QueryParams? params]) {
    return queryMany(DefaultUserViewQueryable(), params);
  }

  @override
  Future<PublicUserView?> queryPublicView(String id) {
    return queryOne(id, PublicUserViewQueryable());
  }

  @override
  Future<List<PublicUserView>> queryPublicViews([QueryParams? params]) {
    return queryMany(PublicUserViewQueryable(), params);
  }

  @override
  Future<void> insert(Database db, List<UserInsertRequest> requests) async {
    if (requests.isEmpty) return;

    await db.query("""
          INSERT INTO "users" ( "company_id", "id", "name", "security_number" )
          VALUES ${requests.map((r) => '( ${registry.encode(r.companyId)}, ${registry.encode(r.id)}, ${registry.encode(r.name)}, ${registry.encode(r.securityNumber)} )').join(', ')}
ON CONFLICT ( "id" ) DO UPDATE SET "company_id" = EXCLUDED."company_id", "name" = EXCLUDED."name", "security_number" = EXCLUDED."security_number"
        """);
  }

  @override
  Future<void> update(Database db, List<UserUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query("""
            UPDATE "users"
            SET "company_id" = COALESCE(UPDATED."company_id"::text, "users"."company_id"), "name" = COALESCE(UPDATED."name"::text, "users"."name"), "security_number" = COALESCE(UPDATED."security_number"::text, "users"."security_number")
            FROM ( VALUES ${requests.map((r) => '( ${registry.encode(r.companyId)}, ${registry.encode(r.id)}, ${registry.encode(r.name)}, ${registry.encode(r.securityNumber)} )').join(', ')} )
            AS UPDATED("company_id", "id", "name", "security_number")
            WHERE "users"."id" = UPDATED."id"
          """);
  }

  @override
  Future<void> delete(Database db, List<String> keys) async {
    if (keys.isEmpty) return;
    await db.query("""
          DELETE FROM "users"
          WHERE "users"."id" IN ( ${keys.map((k) => registry.encode(k)).join(',')} )
        """);
  }
}

abstract class CompanyRepository
    implements
        ModelRepository,
        ModelRepositoryInsert<CompanyInsertRequest>,
        ModelRepositoryUpdate<CompanyUpdateRequest>,
        ModelRepositoryDelete<String> {
  factory CompanyRepository._(Database db) = _CompanyRepository;

  Future<DefaultCompanyView?> queryDefaultView(String id);
  Future<List<DefaultCompanyView>> queryDefaultViews([QueryParams? params]);
}

class _CompanyRepository extends BaseRepository
    with
        RepositoryInsertMixin<CompanyInsertRequest>,
        RepositoryUpdateMixin<CompanyUpdateRequest>,
        RepositoryDeleteMixin<String>
    implements CompanyRepository {
  _CompanyRepository(Database db) : super(db: db);

  @override
  Future<DefaultCompanyView?> queryDefaultView(String id) {
    return queryOne(id, DefaultCompanyViewQueryable());
  }

  @override
  Future<List<DefaultCompanyView>> queryDefaultViews([QueryParams? params]) {
    return queryMany(DefaultCompanyViewQueryable(), params);
  }

  @override
  Future<void> insert(Database db, List<CompanyInsertRequest> requests) async {
    if (requests.isEmpty) return;

    await db.query("""
          INSERT INTO "companies" ( "id", "member_id" )
          VALUES ${requests.map((r) => '( ${registry.encode(r.id)}, ${registry.encode(r.memberId)} )').join(', ')}
ON CONFLICT ( "id" ) DO UPDATE SET "member_id" = EXCLUDED."member_id"
        """);
  }

  @override
  Future<void> update(Database db, List<CompanyUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query("""
            UPDATE "companies"
            SET "member_id" = COALESCE(UPDATED."member_id"::text, "companies"."member_id")
            FROM ( VALUES ${requests.map((r) => '( ${registry.encode(r.id)}, ${registry.encode(r.memberId)} )').join(', ')} )
            AS UPDATED("id", "member_id")
            WHERE "companies"."id" = UPDATED."id"
          """);
  }

  @override
  Future<void> delete(Database db, List<String> keys) async {
    if (keys.isEmpty) return;
    await db.query("""
          DELETE FROM "companies"
          WHERE "companies"."id" IN ( ${keys.map((k) => registry.encode(k)).join(',')} )
        """);
  }
}

class UserInsertRequest {
  UserInsertRequest({this.companyId, required this.id, required this.name, required this.securityNumber});
  String? companyId;
  String id;
  String name;
  String securityNumber;
}

class CompanyInsertRequest {
  CompanyInsertRequest({required this.id, required this.memberId});
  String id;
  String memberId;
}

class UserUpdateRequest {
  UserUpdateRequest({this.companyId, required this.id, this.name, this.securityNumber});
  String? companyId;
  String id;
  String? name;
  String? securityNumber;
}

class CompanyUpdateRequest {
  CompanyUpdateRequest({required this.id, required this.memberId});
  String id;
  String memberId;
}

class DefaultUserViewQueryable extends KeyedViewQueryable<DefaultUserView, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => registry.encode(key);

  @override
  String get tableName => 'default_users_view';

  @override
  String get tableAlias => 'users';

  @override
  DefaultUserView decode(TypedMap map) => DefaultUserView(
      id: map.get('id', registry.decode),
      name: map.get('name', registry.decode),
      securityNumber: map.get('security_number', registry.decode));
}

@MappableClass()
class DefaultUserView {
  DefaultUserView({required this.id, required this.name, required this.securityNumber});

  final String id;
  final String name;
  final String securityNumber;
}

class PublicUserViewQueryable extends KeyedViewQueryable<PublicUserView, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => registry.encode(key);

  @override
  String get tableName => 'public_users_view';

  @override
  String get tableAlias => 'users';

  @override
  PublicUserView decode(TypedMap map) =>
      PublicUserView(id: map.get('id', registry.decode), name: map.get('name', registry.decode));
}

@MappableClass()
class PublicUserView {
  PublicUserView({required this.id, required this.name});

  final String id;
  final String name;
}

class DefaultCompanyViewQueryable extends KeyedViewQueryable<DefaultCompanyView, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => registry.encode(key);

  @override
  String get tableName => 'default_companies_view';

  @override
  String get tableAlias => 'companies';

  @override
  DefaultCompanyView decode(TypedMap map) => DefaultCompanyView(
      id: map.get('id', registry.decode), member: map.get('member', PublicUserViewQueryable().decoder));
}

@MappableClass()
class DefaultCompanyView {
  DefaultCompanyView({required this.id, required this.member});

  final String id;
  final PublicUserView member;
}
