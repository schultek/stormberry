import 'base_repository.dart';

abstract class ModelRepositoryInsert<InsertRequest> {
  Future<void> insertOne(InsertRequest request);
  Future<void> insertMany(List<InsertRequest> requests);
}

abstract class KeyedModelRepositoryInsert<InsertRequest> {
  Future<int> insertOne(InsertRequest request);
  Future<List<int>> insertMany(List<InsertRequest> requests);
}

mixin RepositoryInsertMixin<InsertRequest> on BaseRepository
    implements ModelRepositoryInsert<InsertRequest> {
  Future<void> insert(List<InsertRequest> requests);

  @override
  Future<void> insertOne(InsertRequest request) => transaction(() => insert([request]));
  @override
  Future<void> insertMany(List<InsertRequest> requests) => transaction(() => insert(requests));
}

mixin KeyedRepositoryInsertMixin<InsertRequest> on BaseRepository
    implements KeyedModelRepositoryInsert<InsertRequest> {
  Future<List<int>> insert(List<InsertRequest> requests);

  @override
  Future<int> insertOne(InsertRequest request) =>
      transaction(() => insert([request])).then((r) => r.first);
  @override
  Future<List<int>> insertMany(List<InsertRequest> requests) => transaction(() => insert(requests));
}
