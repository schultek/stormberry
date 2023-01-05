class QueryParams {
  final String? where;
  final String? orderBy;
  final int? limit;
  final int? offset;

  const QueryParams({this.where, this.orderBy, this.limit, this.offset});
}

class QueryValues {
  final Map<String, dynamic> values = {};
  int key = 0;

  String add(dynamic value) {
    values[key.toString()] = value;
    key += 1;
    return '@${key-1}';
  }
}