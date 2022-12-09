import 'database.dart';
import 'transformer.dart';

/// Used to annotate a class as a database model
class Model {
  final List<TableIndex> indexes;
  final String? tableName;
  final dynamic annotateWith;

  const Model({
    this.indexes = const [],
    this.tableName,
    this.annotateWith,
  });
}

class ChangedIn {
  final String name;

  const ChangedIn(this.name);
}

class HiddenIn extends ChangedIn {
  const HiddenIn(String name) : super(name);
}

class ViewedIn extends ChangedIn {
  final String as;

  const ViewedIn(String name, {required this.as}) : super(name);
}

class TransformedIn extends ChangedIn {
  final Transformer by;

  const TransformedIn(String name, {required this.by}) : super(name);
}

/// Used to annotate a field as the primary key of the table
class PrimaryKey {
  const PrimaryKey();
}

/// Used to annotate a field as an auto increment value
/// Can only be applied to an integer field
class AutoIncrement {
  const AutoIncrement();
}

/// Extend this to define a custom action
abstract class Action<T> {
  const Action();
  Future<void> apply(Database db, T request);
}

/// Extend this to define a custom query
abstract class Query<T, U> {
  const Query();
  Future<T> apply(Database db, U params);
}

/// Used to define indexes on a table
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
      joinedColumns.hashCode ^ name.hashCode ^ unique.hashCode ^ algorithm.hashCode ^ condition.hashCode;
}

// ignore: constant_identifier_names
enum IndexAlgorithm { BTREE, GIST, HASH, GIN, BRIN, SPGIST }
