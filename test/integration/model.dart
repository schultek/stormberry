import 'package:stormberry/stormberry.dart';

part 'model.schema.dart';

@Model()
abstract class Author {
  @PrimaryKey()
  String get id;

  String get name;

  bool get verified;
}

@Model()
abstract class Book {
  @PrimaryKey()
  String get id;

  String get title;

  Author get author;
}
