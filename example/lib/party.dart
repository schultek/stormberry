import 'package:stormberry/stormberry.dart';

import 'account.dart';
import 'company.dart';

part 'party.schema.dart';

@Model(views: [#Guest, #Company])
abstract class Party {
  @PrimaryKey()
  String get id;

  String get name;

  @HiddenIn(#Guest)
  @HiddenIn(#Company)
  List<Account> get guests;

  @ViewedIn(#Guest, as: #Member)
  @HiddenIn(#Company)
  Company? get sponsor;

  int get date;
}
