import 'package:dart_mappable/dart_mappable.dart';
import 'package:stormberry/stormberry.dart';

export 'package:dart_mappable/dart_mappable.dart';
export 'models.schema.g.dart';
export 'models.mapper.g.dart';

@Model(views: [
  View('Default', [], MappableClass()),
  View('Public', [Field.hidden('securityNumber')], MappableClass()),
])
abstract class User {
  @PrimaryKey()
  String get id;

  String get name;
  String get securityNumber;
}

@Model(views: [
  View('Default', [Field.view('member', as: 'Public')], MappableClass()),
])
abstract class Company {
  @PrimaryKey()
  String get id;

  User get member;
}
