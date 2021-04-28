import 'src/database.dart';
import 'src/schema.dart';

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

class View {
  final String name;
  final List<Field> fields;
  const View([this.name = '', this.fields = const []]);
}

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

class PrimaryKey {
  const PrimaryKey();
}

class Column {
  const Column();
}

abstract class Action<T> {
  const Action();
  Future<void> apply(Database db, T request);
}

class SingleInsertAction implements Action {
  const SingleInsertAction();

  @override
  Future<void> apply(Database db, dynamic request) {
    throw UnimplementedError();
  }
}

class MultiInsertAction implements Action {
  const MultiInsertAction();

  @override
  Future<void> apply(Database db, dynamic request) {
    throw UnimplementedError();
  }
}

class SingleUpdateAction implements Action {
  const SingleUpdateAction();

  @override
  Future<void> apply(Database db, dynamic request) {
    throw UnimplementedError();
  }
}

class MultiUpdateAction implements Action {
  const MultiUpdateAction();

  @override
  Future<void> apply(Database db, dynamic request) {
    throw UnimplementedError();
  }
}

abstract class Query<T, U> {
  const Query();
  Future<T> apply(Database db, U params);
}

class SingleQuery implements Query {
  final String? viewName;
  const SingleQuery() : viewName = null;
  const SingleQuery.forView(String name) : viewName = name;
  @override
  Future apply(Database db, dynamic params) {
    throw UnimplementedError();
  }
}

class MultiQuery implements Query {
  final String? viewName;
  const MultiQuery() : viewName = null;
  const MultiQuery.forView(String name) : viewName = name;
  @override
  Future apply(Database db, dynamic params) {
    throw UnimplementedError();
  }
}

class TypeConverter<T> {
  final String? type;
  const TypeConverter([this.type]);

  dynamic encode(T value) => throw UnimplementedError();
  T decode(dynamic value) => throw UnimplementedError();
}
