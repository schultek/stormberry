import 'package:stormberry/stormberry.dart';

import 'account.dart';
import 'address.dart';

part 'company.schema.dart';

@Model()
abstract class Company {
  @PrimaryKey()
  String get id;

  String get name;

  List<BillingAddress> get addresses;

  @HiddenIn('member')
  @ViewedIn('admin', as: 'company')
  List<Account> get members;

  @HiddenIn('member')
  @ViewedIn('admin', as: 'owner')
  List<Invoice> get invoices;

  @HiddenIn('member')
  @ViewedIn('admin', as: 'company')
  List<Party> get parties;
}

@Model()
abstract class Invoice {
  @PrimaryKey()
  String get id;
  String get title;
  String get invoiceId;

  @HiddenIn('owner')
  Account? get account;

  @HiddenIn('owner')
  Company? get company;
}

@Model()
abstract class Party {
  @PrimaryKey()
  String get id;

  String get name;

  @HiddenIn('guest')
  @HiddenIn('company')
  List<Account> get guests;

  @ViewedIn('guest', as: 'member')
  @HiddenIn('company')
  Company? get sponsor;

  int get date;
}
