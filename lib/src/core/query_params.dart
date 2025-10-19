/// Options for customizing queries by filtering, ordering, limiting and offsetting results.
///
/// {@category Repositories}
class QueryParams {
  /// SQL WHERE clause to filter results.
  final String? where;

  /// SQL ORDER BY clause to order results.
  final String? orderBy;

  /// Maximum number of results to return.
  final int? limit;

  /// Number of results to skip.
  final int? offset;

  /// Map of parameter values for the query.
  final Map<String, dynamic>? values;

  const QueryParams({this.where, this.orderBy, this.limit, this.offset, this.values});
}

/// Internal class for managing query parameter values.
class QueryValues {
  final Map<String, dynamic> values = {};
  int key = 0;

  String add(dynamic value) {
    values[key.toString()] = value;
    key += 1;
    return '@${key - 1}';
  }
}
