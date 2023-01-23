import 'package:stormberry/stormberry.dart';

part 'schema_2.schema.dart';

@Model()
abstract class Author {
  @PrimaryKey()
  String get id;

  String get name;
}

@Model(indexes: [
  TableIndex(name: 'rating_index', columns: ['rating'])
])
abstract class Book {
  @AutoIncrement()
  @PrimaryKey()
  int get id;

  String get title;

  int get rating;

  Author get author;
}
