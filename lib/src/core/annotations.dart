import 'database.dart';

/// Used to annotate a class as a database model
class Model {
  final List<View> views;
  final List<TableIndex> indexes;
  const Model({
    this.views = const [],
    this.indexes = const [],
  });
}

/// Used to define views for classes annotated with [Model]
class View {
  final String name;
  final List<Field> fields;
  final dynamic annotation;
  const View([this.name = '', this.fields = const [], this.annotation]);
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

abstract class Transformer {
  const Transformer();

  String transform(String column, String table);
}

abstract class ListTransformer extends Transformer {
  const ListTransformer();

  String? select(String column, String table) => null;
  String? where(String column, String table) => null;

  @override
  String transform(String column, String table) {
    var w = where(column, table);
    return 'array_to_json(ARRAY ((\n'
        '  SELECT ${select(column, table) ?? '*'}\n'
        '  FROM jsonb_array_elements("$column".data) AS "$column"\n'
        '${w != null ? '  WHERE $w\n' : ''}'
        ')) ) AS "$column"';
  }
}

class FilterByField extends FilterByValue {
  final String _value;

  const FilterByField(String key, String operand, this._value) : super(key, operand);

  @override
  String value(String column, String table) {
    return '$table.$_value';
  }
}

abstract class FilterByValue extends ListTransformer {
  final String key;
  final String operand;

  const FilterByValue(this.key, this.operand);

  String value(String column, String table);

  @override
  String? where(String column, String table) {
    return "($column -> '$key') $operand to_jsonb (${value(column, table)})";
  }
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
