import 'database.dart';
import 'schema.dart';

/// Used to annotate a class as a database table
class Table {
  final List<View> views;
  final List<Action> actions;
  final List<Query> queries;
  final List<TableIndex> indexes;
  const Table({
    this.views = const [],
    this.actions = const [],
    this.queries = const [],
    this.indexes = const [],
  });
}

/// Used to define views for classes annotated with [Table]
class View {
  final String name;
  final List<Field> fields;
  const View([this.name = '', this.fields = const []]);
}

/// Used to define fields of [View]s
class Field {
  final String name;
  final FieldMode mode;

  final String? viewAs;
  final String? filteredBy;

  const Field.hidden(this.name)
      : mode = FieldMode.hidden,
        viewAs = null,
        filteredBy = null;
  const Field.view(this.name, {required String as})
      : mode = FieldMode.view,
        viewAs = as,
        filteredBy = null;
  const Field.filtered(this.name, {required String by})
      : mode = FieldMode.filtered,
        viewAs = null,
        filteredBy = by;
}

enum FieldMode { hidden, view, filtered }

/// Used to annotate a field as the primary key of the table
class PrimaryKey {
  const PrimaryKey();
}

/// Extend this to define an action on a table
abstract class Action<T> {
  const Action();
  Future<void> apply(Database db, T request);
}

/// Default insert action
class SingleInsertAction implements Action {
  const SingleInsertAction();

  @override
  Future<void> apply(Database db, dynamic request) {
    throw UnimplementedError();
  }
}

/// Default multi-insert action
class MultiInsertAction implements Action {
  const MultiInsertAction();

  @override
  Future<void> apply(Database db, dynamic request) {
    throw UnimplementedError();
  }
}

/// Default update action
class SingleUpdateAction implements Action {
  const SingleUpdateAction();

  @override
  Future<void> apply(Database db, dynamic request) {
    throw UnimplementedError();
  }
}

/// Default multi-update action
class MultiUpdateAction implements Action {
  const MultiUpdateAction();

  @override
  Future<void> apply(Database db, dynamic request) {
    throw UnimplementedError();
  }
}

/// Extend this to define a query on a table
abstract class Query<T, U> {
  const Query();
  Future<T> apply(Database db, U params);
}

/// Default query
class SingleQuery implements Query {
  final String? viewName;
  const SingleQuery() : viewName = null;
  const SingleQuery.forView(String name) : viewName = name;
  @override
  Future apply(Database db, dynamic params) => throw UnimplementedError();
}

/// Default multi-query
class MultiQuery implements Query {
  final String? viewName;
  const MultiQuery() : viewName = null;
  const MultiQuery.forView(String name) : viewName = name;
  @override
  Future apply(Database db, dynamic params) => throw UnimplementedError();
}

/// Extend this to define a custom type converter
class TypeConverter<T> {
  /// The sql type to be converted
  final String? type;
  const TypeConverter([this.type]);

  dynamic encode(T value) => throw UnimplementedError();
  T decode(dynamic value) => throw UnimplementedError();
}
