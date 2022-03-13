class QueryParams {
  final String? where;
  final String? orderBy;
  final int? limit;
  final int? offset;

  const QueryParams({this.where, this.orderBy, this.limit, this.offset});
}
