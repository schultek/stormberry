/// {@category Models}
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

/// {@category Models}
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
