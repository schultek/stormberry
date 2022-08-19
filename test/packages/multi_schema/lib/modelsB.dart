import 'package:stormberry/stormberry.dart';

@Model(views: [
  View('ViewB', [
    Field.hidden('data'),
  ]),
])
abstract class ModelB {
  String get data;
}
