import 'package:stormberry/stormberry.dart';

import 'address.dart';
import 'company.dart';
import 'invoice.dart';
import 'latlng.dart';
import 'party.dart';

part 'account.schema.dart';

@Model(views: [#Full, #User, #Company])
abstract class Account {
  @PrimaryKey()
  @AutoIncrement()
  int get id;

  // Fields
  String get firstName;
  String get lastName;

  // Custom Type
  @UseConverter(LatLngConverter())
  LatLng get location;

  // Foreign Object
  @HiddenIn(#Company)
  BillingAddress? get billingAddress;

  @HiddenIn(#Company)
  @ViewedIn(#Full, as: #Owner)
  @ViewedIn(#User, as: #Owner)
  List<Invoice> get invoices;

  @HiddenIn(#Company)
  @ViewedIn(#Full, as: #Member)
  @ViewedIn(#User, as: #Member)
  Company? get company;

  @ViewedIn(#Company, as: #Company)
  @TransformedIn(#Company, by: FilterByField('sponsor_id', '=', 'company_id'))
  @ViewedIn(#Full, as: #Guest)
  @ViewedIn(#User, as: #Guest)
  List<Party> get parties;
}
