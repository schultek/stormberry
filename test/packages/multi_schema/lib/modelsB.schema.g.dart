// ignore_for_file: prefer_relative_imports
import 'package:stormberry/internals.dart';

import 'modelsB.dart';

extension Repositories on Database {
  ModelBRepository get modelBs => ModelBRepository._(this);
}

final registry = ModelRegistry({});

abstract class ModelBRepository
    implements ModelRepository, ModelRepositoryInsert<ModelBInsertRequest>, ModelRepositoryUpdate<ModelBUpdateRequest> {
  factory ModelBRepository._(Database db) = _ModelBRepository;

  Future<List<ViewBModelBView>> queryViewBViews([QueryParams? params]);
}

class _ModelBRepository extends BaseRepository
    with RepositoryInsertMixin<ModelBInsertRequest>, RepositoryUpdateMixin<ModelBUpdateRequest>
    implements ModelBRepository {
  _ModelBRepository(Database db) : super(db: db);

  @override
  Future<List<ViewBModelBView>> queryViewBViews([QueryParams? params]) {
    return queryMany(ViewBModelBViewQueryable(), params);
  }

  @override
  Future<void> insert(Database db, List<ModelBInsertRequest> requests) async {
    if (requests.isEmpty) return;

    await db.query(
      'INSERT INTO "model_bs" ( "data" )\n'
      'VALUES ${requests.map((r) => '( ${registry.encode(r.data)} )').join(', ')}\n',
    );
  }

  @override
  Future<void> update(Database db, List<ModelBUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query(
      'UPDATE "model_bs"\n'
      'SET "data" = COALESCE(UPDATED."data"::text, "model_bs"."data")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${registry.encode(r.data)} )').join(', ')} )\n'
      'AS UPDATED("data")\n'
      'WHERE ',
    );
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

class ViewBModelBViewQueryable extends ViewQueryable<ViewBModelBView> {
  @override
  String get tableName => 'view_b_model_bs_view';

  @override
  String get tableAlias => 'model_bs';

  @override
  ViewBModelBView decode(TypedMap map) => ViewBModelBView();
}

class ViewBModelBView {
  ViewBModelBView();
}
