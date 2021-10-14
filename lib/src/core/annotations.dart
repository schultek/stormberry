import 'database.dart';

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

  final bool isHidden;
  final String? viewAs;
  final Transformer? transformer;

  const Field(this.name, {this.viewAs, this.isHidden = false, this.transformer});

  const Field.hidden(this.name)
      : isHidden = true,
        viewAs = null,
        transformer = null;
  const Field.view(this.name, {required String as})
      : isHidden = false,
        viewAs = as,
        transformer = null;
  const Field.transform(this.name, this.transformer)
      : isHidden = false,
        viewAs = null;
}

class Transformer {
  final String statement;
  const Transformer(this.statement);
}

class ListTransformer extends Transformer {
  const ListTransformer({String? select, String? where})
      : super(
          '''
    array_to_json(ARRAY ((
      SELECT ${select ?? '*'} 
      FROM jsonb_array_elements({{key}}.data) AS {{key}}
      ${where != null ? 'WHERE $where' : ''}
    )) ) AS {{key}}
  ''',
        );
}

class FilterByField extends FilterByValue {
  const FilterByField(String key, String operand, String value) : super(key, operand, '{{table}}.$value');
}

class FilterByValue extends ListTransformer {
  const FilterByValue(String key, String operand, String value)
      : super(where: "({{key}} -> '$key') $operand to_jsonb ($value)");
}

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

/// Default delete action
class SingleDeleteAction implements Action {
  const SingleDeleteAction();

  @override
  Future<void> apply(Database db, dynamic request) {
    throw UnimplementedError();
  }
}

/// Default multi-delete action
class MultiDeleteAction implements Action {
  const MultiDeleteAction();

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
  final String viewName;
  const SingleQuery.forView(String name) : viewName = name;
  @override
  Future apply(Database db, dynamic params) => throw UnimplementedError();
}

/// Default multi-query
class MultiQuery implements Query {
  final String viewName;
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

/// Used to define indexes on a table
class TableIndex {
  final List<String> columns;
  final String name;
  final bool unique;
  final IndexAlgorithm algorithm;
  final String? condition;

  const TableIndex({
    this.columns = const [],
    required this.name,
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
