import 'base_repository.dart';

abstract class ModelRepositoryUpdate<UpdateRequest> {
  /// Updates a single row.
  Future<void> updateOne(UpdateRequest request);

  /// Updates multiple rows.
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

/// Helper class to represent updates on a list of values.
///
/// Use [UpdateValues.set] to replace the entire list,
/// [UpdateValues.add] to add values to the list,
/// and [UpdateValues.remove] to remove values from the list.
class UpdateValues<T> {
  final ValueMode mode;
  final List<T> values;

  /// Creates an [UpdateValues] instance to replace the entire list with [values].
  UpdateValues.set(this.values) : mode = ValueMode.set;

  /// Creates an [UpdateValues] instance to add [values] to the list.
  UpdateValues.add(this.values) : mode = ValueMode.add;

  /// Creates an [UpdateValues] instance to remove [values] from the list.
  UpdateValues.remove(this.values) : mode = ValueMode.remove;
}

enum ValueMode { set, add, remove }
