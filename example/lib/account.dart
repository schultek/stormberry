import 'package:stormberry/stormberry.dart';

import 'address.dart';
import 'company.dart';
import 'latlng.dart';

part 'account.schema.dart';

@Model()
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
  @HiddenIn('company')
  BillingAddress? get billingAddress;

  @HiddenIn('company')
  @ViewedIn('admin', as: 'owner')
  @ViewedIn('user', as: 'owner')
  List<Invoice> get invoices;

  @HiddenIn('company')
  @ViewedIn('admin', as: 'member')
  @ViewedIn('user', as: 'member')
  Company? get company;

  @ViewedIn('company', as: 'company')
  @TransformedIn('company', by: FilterByField('sponsor_id', '=', 'company_id'))
  @ViewedIn('admin', as: 'guest')
  @ViewedIn('user', as: 'guest')
  List<Party> get parties;
}
