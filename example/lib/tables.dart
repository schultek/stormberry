import 'package:stormberry/stormberry.dart';

export 'tables.schema.g.dart';

@Table(views: [
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
], actions: [
  SingleInsertAction(),
  SingleUpdateAction(),
], queries: [
  SingleQuery.forView('User'),
  MultiQuery.forView('Admin'),
])
class Account {
  @PrimaryKey()
  String id;

  // Fields
  String firstName, lastName;

  // Custom Type
  LatLng location;

  // Foreign Object
  BillingAddress? billingAddress;

  List<Invoice> invoices;
  Company? company;

  List<Party> parties;

  Account(
    this.id,
    this.firstName,
    this.lastName,
    this.location,
    this.billingAddress,
    this.company,
    this.invoices,
    this.parties,
  );
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

@Table()
class BillingAddress {
  String name, street, city;
  String postcode;

  BillingAddress(this.name, this.street, this.postcode, this.city);
}

@Table(views: [
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
], actions: [
  SingleInsertAction(),
  SingleDeleteAction(),
], queries: [
  SingleQuery.forView('Admin'),
])
class Company {
  @PrimaryKey()
  String id;

  String name;

  List<BillingAddress> addresses;
  List<Account> members;
  List<Invoice> invoices;
  List<Party> parties;

  Company(this.id, this.name, this.addresses, this.members, this.invoices, this.parties);
}

@Table(views: [
  View('Owner', [
    Field.hidden('account'),
    Field.hidden('company'),
  ])
])
class Invoice {
  @PrimaryKey()
  String id;
  String title, invoiceId;

  Account? account;
  Company? company;

  Invoice(
    this.id,
    this.title,
    this.invoiceId,
    this.account,
    this.company,
  );
}

@Table(views: [
  View('Guest', [
    Field.hidden('guests'),
    Field.view('sponsor', as: 'member'),
  ]),
  View('Company', [
    Field.hidden('sponsor'),
    Field.hidden('guests'),
  ]),
])
class Party {
  @PrimaryKey()
  String id;

  String name;

  List<Account> guests;

  Company? sponsor;

  int date;

  Party(this.id, this.name, this.guests, this.sponsor, this.date);
}
