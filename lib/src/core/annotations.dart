import 'database.dart';
import 'transformer.dart';

/// Used to annotate a class as a database model
class Model {
  /// The list of views this model defined.
  final List<Symbol> views;

  /// A list of indexes that should be created for this table.
  final List<TableIndex> indexes;

  /// A custom name for this table.
  final String? tableName;

  /// Metadata for the generated classes in order to use serialization for these classes.
  final ModelMeta? meta;

  const Model({
    this.views = const [],
    this.indexes = const [],
    this.tableName,
    this.meta,
  });
}

/// Metadata for the generated classes in order to use serialization for these classes.
class ModelMeta {
  /// Metadata for the insert request class.
  final ClassMeta? insert;

  /// Metadata for the update request class.
  final ClassMeta? update;

  /// Metadata for the view classes.
  final ClassMeta? view;

  const ModelMeta({this.insert, this.update, this.view});

  const ModelMeta.all(ClassMeta meta)
      : insert = meta,
        update = meta,
        view = meta;
}

/// Metadata for a generated class.
class ClassMeta {
  /// An annotation to be applied to the generated class.
  final Object? annotation;

  /// Additional mixins for the generated class.
  final String? mixin;

  /// Extends clause for the generated class.
  final String? extend;

  /// Additional interfaces for the generated class.
  final String? implement;

  const ClassMeta({this.annotation, this.mixin, this.extend, this.implement});
}

/// Base class for the view modifiers.
class ChangedIn {
  final Symbol name;

  const ChangedIn(this.name);
}

/// Hides the annotated field in the given view.
class HiddenIn extends ChangedIn {
  const HiddenIn(Symbol name) : super(name);
}

/// Modified the annotated field in the given view.
class ViewedIn extends ChangedIn {
  final Symbol as;

  const ViewedIn(Symbol name, {required this.as}) : super(name);
}

/// Applies the transformer on the annotated field in the given view.
class TransformedIn extends ChangedIn {
  final Transformer by;

  const TransformedIn(Symbol name, {required this.by}) : super(name);
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
      joinedColumns.hashCode ^
      name.hashCode ^
      unique.hashCode ^
      algorithm.hashCode ^
      condition.hashCode;
}

/// The algorithm for an index.
// ignore: constant_identifier_names
enum IndexAlgorithm { BTREE, GIST, HASH, GIN, BRIN, SPGIST }
