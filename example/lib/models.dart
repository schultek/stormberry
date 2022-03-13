import 'package:stormberry/stormberry.dart';

import 'models.schema.g.dart';

export 'models.schema.g.dart';

@Model(views: [
  View('User', [
    Field.hidden('customerId'),
    Field.view('company', as: 'member'),
    Field.view('chargeLocks', as: 'user'),
    Field.view('parties', as: 'guest'),
    Field.view('invoices', as: 'owner'),
  ]),
  View('Admin', [
    Field.view('company', as: 'member'),
    Field.view('chargeLocks', as: 'user'),
    Field.view('parties', as: 'guest'),
    Field.view('invoices', as: 'owner'),
  ]),
  View('Company', [
    Field.hidden('customerId'),
    Field.hidden('cards'),
    Field.hidden('billingAddress'),
    Field.hidden('invoices'),
    Field.hidden('company'),
    Field('parties', viewAs: 'company', transformer: FilterByField('sponsor_id', '=', 'company_id')),
  ]),
])
abstract class Account {
  @PrimaryKey()
  String get id;

  // Fields
  String get firstName;
  String get lastName;

  // Custom Type
  LatLng get location;

  // Foreign Object
  BillingAddress? get billingAddress;

  List<Invoice> get invoices;
  Company? get company;

  List<Party> get parties;
}

class LatLng {
  double latitude, longitude;
  LatLng(this.latitude, this.longitude);
}

@TypeConverter('point')
class LatLngConverter extends TypeConverter<LatLng> {
  @override
  dynamic encode(LatLng value) => PgPoint(value.latitude, value.longitude);

  @override
  LatLng decode(dynamic value) {
    if (value is PgPoint) {
      return LatLng(value.latitude, value.longitude);
    } else {
      var m = RegExp(r'\((.+),(.+)\)').firstMatch(value.toString());
      var lat = double.parse(m!.group(1)!.trim());
      var lng = double.parse(m.group(2)!.trim());
      return LatLng(lat, lng);
    }
  }
}

@Model()
abstract class BillingAddress {
  String get name;
  String get street;
  String get city;
  String get postcode;

  factory BillingAddress({
    required String name,
    required String street,
    required String city,
    required String postcode,
  }) = BillingAddressView;
}

@Model(views: [
  View('Admin', [
    Field.view('invoices', as: 'owner'),
    Field.view('members', as: 'company'),
    Field.view('parties', as: 'company'),
  ]),
  View('Member', [
    Field.hidden('members'),
    Field.hidden('invoices'),
    Field.hidden('parties'),
  ])
])
abstract class Company {
  @PrimaryKey()
  String get id;

  String get name;

  List<BillingAddress> get addresses;
  List<Account> get members;
  List<Invoice> get invoices;
  List<Party> get parties;
}

@Model(views: [
  View('Owner', [
    Field.hidden('account'),
    Field.hidden('company'),
  ])
])
abstract class Invoice {
  @PrimaryKey()
  String get id;
  String get title;
  String get invoiceId;

  Account? get account;
  Company? get company;
}

@Model(views: [
  View('Guest', [
    Field.hidden('guests'),
    Field.view('sponsor', as: 'member'),
  ]),
  View('Company', [
    Field.hidden('sponsor'),
    Field.hidden('guests'),
  ]),
])
abstract class Party {
  @PrimaryKey()
  String get id;

  String get name;

  List<Account> get guests;

  Company? get sponsor;

  int get date;
}
