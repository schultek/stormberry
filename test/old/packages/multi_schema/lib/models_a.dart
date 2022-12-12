import 'package:stormberry/stormberry.dart';

@Model(views: [
  View('ViewA', [
    Field.hidden('data'),
  ]),
])
abstract class ModelA {
  String get data;
}
