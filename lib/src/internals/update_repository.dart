import 'base_repository.dart';

abstract class ModelRepositoryUpdate<UpdateRequest> {
  Future<void> updateOne(UpdateRequest request);
  Future<void> updateMany(List<UpdateRequest> requests);
}

mixin RepositoryUpdateMixin<UpdateRequest> on BaseRepository
    implements ModelRepositoryUpdate<UpdateRequest> {
  @override
  Future<void> updateOne(UpdateRequest request) => update([request]);
  @override
  Future<void> updateMany(List<UpdateRequest> requests) => update(requests);

  Future<void> update(List<UpdateRequest> requests);
}

class UpdateValues<T> {
  final ValueMode mode;
  final List<T> values;

  UpdateValues.set(this.values) : mode = ValueMode.set;
  UpdateValues.add(this.values) : mode = ValueMode.add;
  UpdateValues.remove(this.values) : mode = ValueMode.remove;
}

enum ValueMode { set, add, remove }
