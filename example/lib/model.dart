import 'package:stormberry/stormberry.dart';

part 'model.schema.dart';

@Model()
abstract class A {
  @PrimaryKey()
  String get id;

  B get b;
}

@Model()
abstract class B {
  @PrimaryKey()
  String get id;

  A? get a;
}
