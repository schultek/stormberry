import 'package:stormberry/stormberry.dart';

part 'schema_2.schema.dart';

@Model()
abstract class Author {
  @PrimaryKey()
  String get id;

  String get name;
}

@Model()
abstract class Book {
  @PrimaryKey()
  String get id;

  String get title;

  int get rating;

  Author get author;
}