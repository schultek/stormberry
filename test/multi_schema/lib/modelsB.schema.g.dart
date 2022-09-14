// ignore_for_file: prefer_relative_imports
import 'package:stormberry/internals.dart';
import 'package:multi_schema_test/modelsB.dart';

extension Repositories on Database {
  ModelBRepository get modelBs => ModelBRepository._(this);
}

final registry = ModelRegistry({});

abstract class ModelBRepository
    implements ModelRepository, ModelRepositoryInsert<ModelBInsertRequest>, ModelRepositoryUpdate<ModelBUpdateRequest> {
  factory ModelBRepository._(Database db) = _ModelBRepository;

  Future<List<ViewbModelBView>> queryViewbViews([QueryParams? params]);
}

class _ModelBRepository extends BaseRepository
    with RepositoryInsertMixin<ModelBInsertRequest>, RepositoryUpdateMixin<ModelBUpdateRequest>
    implements ModelBRepository {
  _ModelBRepository(Database db) : super(db: db);

  @override
  Future<List<ViewbModelBView>> queryViewbViews([QueryParams? params]) {
    return queryMany(ViewbModelBViewQueryable(), params);
  }

  @override
  Future<void> insert(Database db, List<ModelBInsertRequest> requests) async {
    if (requests.isEmpty) return;

    await db.query("""
          INSERT INTO "model_bs" ( "data" )
          VALUES ${requests.map((r) => '( ${registry.encode(r.data)} )').join(', ')}
        """);
  }

  @override
  Future<void> update(Database db, List<ModelBUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query("""
            UPDATE "model_bs"
            SET "data" = COALESCE(UPDATED."data"::text, "model_bs"."data")
            FROM ( VALUES ${requests.map((r) => '( ${registry.encode(r.data)} )').join(', ')} )
            AS UPDATED("data")
            WHERE 
          """);
  }
}

class ModelBInsertRequest {
  ModelBInsertRequest({required this.data});
  String data;
}

class ModelBUpdateRequest {
  ModelBUpdateRequest({this.data});
  String? data;
}

class ViewbModelBViewQueryable extends ViewQueryable<ViewbModelBView> {
  @override
  String get tableName => 'viewb_model_bs_view';

  @override
  String get tableAlias => 'model_bs';

  @override
  ViewbModelBView decode(TypedMap map) => ViewbModelBView();
}

class ViewbModelBView {
  ViewbModelBView();
}
