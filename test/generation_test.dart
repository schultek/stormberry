import 'package:stormberry/stormberry.dart';

@Model()
abstract class User {
  @PrimaryKey()
  String get id;

  String get name;
  Account get account;
}

@Model(views: [View('SuperSecret')])
abstract class Account {
  @PrimaryKey()
  String get id;
}

void main() {}
