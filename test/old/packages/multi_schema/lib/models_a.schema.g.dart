// ignore_for_file: prefer_relative_imports
import 'package:stormberry/internals.dart';

import 'models_a.dart';

extension Repositories on Database {
  ModelARepository get modelAs => ModelARepository._(this);
}

final registry = ModelRegistry({});

abstract class ModelARepository
    implements ModelRepository, ModelRepositoryInsert<ModelAInsertRequest>, ModelRepositoryUpdate<ModelAUpdateRequest> {
  factory ModelARepository._(Database db) = _ModelARepository;

  Future<List<ViewAModelAView>> queryViewAViews([QueryParams? params]);
}

class _ModelARepository extends BaseRepository
    with RepositoryInsertMixin<ModelAInsertRequest>, RepositoryUpdateMixin<ModelAUpdateRequest>
    implements ModelARepository {
  _ModelARepository(Database db) : super(db: db);

  @override
  Future<List<ViewAModelAView>> queryViewAViews([QueryParams? params]) {
    return queryMany(ViewAModelAViewQueryable(), params);
  }

  @override
  Future<void> insert(Database db, List<ModelAInsertRequest> requests) async {
    if (requests.isEmpty) return;

    await db.query(
      'INSERT INTO "model_as" ( "data" )\n'
      'VALUES ${requests.map((r) => '( ${registry.encode(r.data)} )').join(', ')}\n',
    );
  }

  @override
  Future<void> update(Database db, List<ModelAUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query(
      'UPDATE "model_as"\n'
      'SET "data" = COALESCE(UPDATED."data"::text, "model_as"."data")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${registry.encode(r.data)} )').join(', ')} )\n'
      'AS UPDATED("data")\n'
      'WHERE ',
    );
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

class ViewAModelAViewQueryable extends ViewQueryable<ViewAModelAView> {
  @override
  String get tableName => 'view_a_model_as_view';

  @override
  String get tableAlias => 'model_as';

  @override
  ViewAModelAView decode(TypedMap map) => ViewAModelAView();
}

class ViewAModelAView {
  ViewAModelAView();
}
