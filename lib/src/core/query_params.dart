/// {@category Repositories}
class QueryParams {
  final String? where;
  final String? orderBy;
  final int? limit;
  final int? offset;
  final Map<String, dynamic>? values;

  const QueryParams({this.where, this.orderBy, this.limit, this.offset, this.values});
}

/// {@nodoc}
class QueryValues {
  final Map<String, dynamic> values = {};
  int key = 0;

  String add(dynamic value) {
    values[key.toString()] = value;
    key += 1;
    return '@${key - 1}';
  }
}
