import 'package:stormberry/stormberry.dart';

@Model()
abstract class User {
  @PrimaryKey()
  String get id;

  String get name;
}

@Model(views: [View('SuperSecret')])
abstract class Account {
  @PrimaryKey()
  String get id;
}

void main() {}
