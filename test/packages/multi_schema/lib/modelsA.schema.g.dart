// ignore_for_file: prefer_relative_imports
import 'package:stormberry/internals.dart';
import 'package:multi_schema_test/modelsA.dart';

extension Repositories on Database {
  ModelARepository get modelAs => ModelARepository._(this);
}

final registry = ModelRegistry({});

abstract class ModelARepository
    implements ModelRepository, ModelRepositoryInsert<ModelAInsertRequest>, ModelRepositoryUpdate<ModelAUpdateRequest> {
  factory ModelARepository._(Database db) = _ModelARepository;

  Future<List<ViewaModelAView>> queryViewaViews([QueryParams? params]);
}

class _ModelARepository extends BaseRepository
    with RepositoryInsertMixin<ModelAInsertRequest>, RepositoryUpdateMixin<ModelAUpdateRequest>
    implements ModelARepository {
  _ModelARepository(Database db) : super(db: db);

  @override
  Future<List<ViewaModelAView>> queryViewaViews([QueryParams? params]) {
    return queryMany(ViewaModelAViewQueryable(), params);
  }

  @override
  Future<void> insert(Database db, List<ModelAInsertRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query("""
          INSERT INTO "model_as" ( "data" )
          VALUES ${requests.map((r) => '( ${registry.encode(r.data)} )').join(', ')}
          
        """);
  }

  @override
  Future<void> update(Database db, List<ModelAUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query("""
            UPDATE "model_as"
            SET "data" = COALESCE(UPDATED."data"::text, "model_as"."data")
            FROM ( VALUES ${requests.map((r) => '( ${registry.encode(r.data)} )').join(', ')} )
            AS UPDATED("data")
            WHERE 
          """);
  }
}

class ModelAInsertRequest {
  ModelAInsertRequest({required this.data});
  String data;
}

class ModelAUpdateRequest {
  ModelAUpdateRequest({this.data});
  String? data;
}

class ViewaModelAViewQueryable extends ViewQueryable<ViewaModelAView> {
  @override
  String get tableName => 'viewa_model_as_view';

  @override
  String get tableAlias => 'model_as';

  @override
  ViewaModelAView decode(TypedMap map) => ViewaModelAView();
}

class ViewaModelAView {
  ViewaModelAView();
}
