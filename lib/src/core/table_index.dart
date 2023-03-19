/// Used to define indexes on a table
///
/// {@category Models}
class TableIndex {
  final List<String> columns;
  final String name;
  final bool unique;
  final IndexAlgorithm algorithm;
  final String? condition;

  const TableIndex({
    required this.name,
    this.columns = const [],
    this.unique = false,
    this.algorithm = IndexAlgorithm.BTREE,
    this.condition,
  });

  String get joinedColumns => columns.map((c) => '"$c"').join(', ');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableIndex &&
          runtimeType == other.runtimeType &&
          joinedColumns == other.joinedColumns &&
          name == other.name &&
          unique == other.unique &&
          algorithm == other.algorithm &&
          condition == other.condition;

  @override
  int get hashCode =>
      joinedColumns.hashCode ^
      name.hashCode ^
      unique.hashCode ^
      algorithm.hashCode ^
      condition.hashCode;
}

/// The algorithm for an index.
///
/// {@category Models}
// ignore: constant_identifier_names
enum IndexAlgorithm { BTREE, GIST, HASH, GIN, BRIN, SPGIST }
