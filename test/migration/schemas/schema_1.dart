import 'package:stormberry/stormberry.dart';

part 'schema_1.schema.dart';

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

  Author get author;
}