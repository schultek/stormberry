import 'database.dart';
import 'table_index.dart';
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

/// Used to annotate a relational field and specify a binding target.
///
/// The binding target must be a field of the referenced model that
/// refers back to this model. That field must also use the `@BindTo`
/// annotation set to this field, in order to form a closed loop.
class BindTo {
  const BindTo(this.name);

  final Symbol name;
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
