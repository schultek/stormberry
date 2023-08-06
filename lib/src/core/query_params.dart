import 'package:postgres/postgres_v3_experimental.dart';

/// {@category Repositories}
class QueryParams {
  final String? where;
  final String? orderBy;
  final int? limit;
  final int? offset;
  final List<PgTypedParameter>? values;

  const QueryParams(
      {this.where, this.orderBy, this.limit, this.offset, this.values});
}

/// {@nodoc}
class QueryValues {
  final List<PgTypedParameter> values = [];

  static PgTypedParameter withType(dynamic value) {
    final type = switch (value) {
      int() => PgDataType.bigInteger,
      double() => PgDataType.double,
      bool() => PgDataType.boolean,
      DateTime() => PgDataType.timestampWithTimezone,
      String() => PgDataType.text,
      PgPoint() => PgDataType.point,
      Map() || List() => PgDataType.json,
      _ => throw ArgumentError.value(value, 'value', 'Unsupported type'),
    };

    return PgTypedParameter(type, value);
  }

  String add(dynamic value, [String? type]) {
    if (type != null) {
      values.add(PgTypedParameter(PgDataType.bySubstitutionName[type]!, value));
    } else {
      values.add(withType(value));
    }

    final oneBasedIndex = values.length;

    return '\$$oneBasedIndex';
  }
}
