
import 'package:stormberry/stormberry.dart';

import 'account.dart';
import 'company.dart';

part 'invoice.schema.dart';

@Model(views: [#Owner])
abstract class Invoice {
  @PrimaryKey()
  String get id;
  String get title;
  String get invoiceId;

  @HiddenIn(#Owner)
  Account? get account;

  @HiddenIn(#Owner)
  Company? get company;
}