import 'package:stormberry/stormberry.dart';

part 'model.schema.dart';

@Model()
abstract class A {
  @PrimaryKey()
  String get id;

  String get a;
  int get b;
  double get c;
  bool get d;
  List<int> get e;
  List<double> get f;
}

@Model()
abstract class B {
  @PrimaryKey()
  @AutoIncrement()
  int get id;

  A get a;

  String get b;
  int get c;
  double get d;
  bool get e;
}

@Model(views: [#Full, #Part])
abstract class C {
  @PrimaryKey()
  String get id;

  @ViewedIn(#Full, as: #Part)
  @HiddenIn(#Part)
  List<D> get ds;
}

@Model(views: [#Full, #Part])
abstract class D {
  @PrimaryKey()
  String get id;

  @ViewedIn(#Full, as: #Part)
  @HiddenIn(#Part)
  List<C> get cs;
}
