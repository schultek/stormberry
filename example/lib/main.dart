import 'package:dartabase/dartabase.dart';

@Table(views: [
  View('User', [
    Field.hidden('customerId'),
    Field.view('company', as: 'member'),
    Field.view('chargeLocks', as: 'user'),
  ]),
  View('Admin', [
    Field.view('company', as: 'member'),
    Field.view('chargeLocks', as: 'user'),
  ]),
  View('Company', [
    Field.hidden('customerId'),
    Field.hidden('cards'),
    Field.hidden('billingAddress'),
    Field.hidden('invoices'),
    Field.hidden('company'),
    Field.filtered('chargeLocations', by: 'is_private = false')
  ])
], actions: [
  SingleInsertAction(),
  SingleUpdateAction(),
  ToggleEmailNotification(),
], queries: [
  SingleQuery.forView('User'),
  MultiQuery.forView('Admin'),
])
class Account {
  @PrimaryKey()
  String id;

  // Fields
  String firstName, lastName;
  int age;
  String gender;
  List<String> vehicles;
  bool sendInvoicesViaEmail;
  String customerId;
  List<ChargeCard> cards;

  LatLng location;

  // Secondary objects
  BillingAddress? billingAddress;
  // List<ChargeTariffUidLock> chargeLocks;

  // // Reference objects
  // List<Invoice> invoices;
  Company? company;
  //
  // // Custom objects

  Account(
    this.id,
    this.firstName,
    this.lastName,
    this.age,
    this.gender,
    this.vehicles,
    this.sendInvoicesViaEmail,
    this.location,
    this.cards,
    this.customerId,
    this.billingAddress,
    this.company,
    /* this.invoices, this.chargeLocks*/
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

class ChargeCard {
  String type, uid, name;
  ChargeCard(this.name, this.uid, this.type);
}

class ToggleEmailNotification extends Action<bool> {
  const ToggleEmailNotification();

  @override
  Future<void> apply(Database db, bool request) async {
    print('TOGGLING EMAIL TO $request');
  }
}

@Table()
class BillingAddress {
  String name, street, city;

  BillingAddress(this.name, this.street, this.city);
}

@Table(views: [View('member')])
class Company {
  @PrimaryKey()
  String id;

  List<BillingAddress> addresses;

  Company(this.id, this.addresses);
}
