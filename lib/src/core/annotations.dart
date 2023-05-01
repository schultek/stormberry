import 'database.dart';
import 'table_index.dart';
import 'transformer.dart';

/// Used to annotate a class as a database model
///
/// {@category Models}
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

  /// The default view of a model.
  static const Symbol defaultView = #$default$;
}

/// Metadata for the generated classes in order to use serialization for these classes.
///
/// {@category Models}
class ModelMeta {
  /// Metadata for the insert request class.
  final ClassMeta? insert;

  /// Metadata for the update request class.
  final ClassMeta? update;

  /// Metadata for all view classes.
  final ClassMeta? view;

  /// Metadata for specific view classes.
  final Map<Symbol, ClassMeta>? views;

  const ModelMeta({this.insert, this.update, this.view, this.views});

  const ModelMeta.all(ClassMeta meta)
      : insert = meta,
        update = meta,
        view = meta,
        views = null;
}

/// Metadata for a generated class.
///
/// {@category Models}
class ClassMeta {
  /// An annotation to be applied to the generated class.
  final Object? annotation;

  /// Additional mixins for the generated class.
  ///
  /// Supports the '{name}' template which will be replaced with the target class name.
  final String? mixin;

  /// Extends clause for the generated class.
  ///
  /// Supports the '{name}' template which will be replaced with the target class name.
  final String? extend;

  /// Additional interfaces for the generated class.
  ///
  /// Supports the '{name}' template which will be replaced with the target class name.
  final String? implement;

  const ClassMeta({this.annotation, this.mixin, this.extend, this.implement});
}

/// Hides the annotated field in the given view.
///
/// {@category Models}
/// {@category Views}
class HiddenIn {
  final Symbol name;

  const HiddenIn(this.name);
  const HiddenIn.defaultView() : name = Model.defaultView;
}

/// Modified the annotated field in the given view.
///
/// {@category Models}
/// {@category Views}
class ViewedIn {
  final Symbol name;
  final Symbol as;

  const ViewedIn(this.name, {required this.as});
  const ViewedIn.defaultView({required this.as}) : name = Model.defaultView;
}

/// Applies the transformer on the annotated field in the given view.
///
/// {@category Models}
/// {@category Views}
class TransformedIn {
  final Symbol name;
  final Transformer by;

  const TransformedIn(this.name, {required this.by});
  const TransformedIn.defaultView({required this.by}) : name = Model.defaultView;
}

/// Used to annotate a field as the primary key of the table.
///
/// {@category Models}
class PrimaryKey {
  const PrimaryKey();
}

/// Used to annotate a field as an auto increment value.
/// Can only be applied to an integer field.
///
/// {@category Models}
class AutoIncrement {
  const AutoIncrement();
}

/// Used to annotate a relational field and specify a binding target.
///
/// The binding target must be a field of the referenced model that
/// refers back to this model. That field must also use the `@BindTo`
/// annotation set to this field, in order to form a closed loop.
///
/// {@category Models}
class BindTo {
  const BindTo(this.name);

  final Symbol name;
}

/// Extend this to define a custom action.
///
/// {@category Queries & Actions}
abstract class Action<T> {
  const Action();
  Future<void> apply(Database db, T request);
}

/// Extend this to define a custom query.
///
/// {@category Queries & Actions}
abstract class Query<T, U> {
  const Query();
  Future<T> apply(Database db, U params);
}
