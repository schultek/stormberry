import 'package:stormberry/stormberry.dart';

import 'models/account.dart';
import 'models/address.dart';
import 'models/company.dart';
import 'models/latlng.dart';

Future<void> main() async {
  var db = Database(
    port: 2222,
    database: 'dart_test',
    user: 'postgres',
    password: 'postgres',
    useSSL: false,
  );

  db.debugPrint = true;

  await db.companies.deleteOne('abc');

  await db.companies.insertOne(CompanyInsertRequest(
    id: 'abc',
    name: 'Minga',
    addresses: [],
  ));

  await db.accounts.deleteMany([0, 1, 2]);

  var accountId = await db.accounts.insertOne(AccountInsertRequest(
    firstName: 'Test',
    lastName: 'User',
    location: LatLng(1, 2),
    billingAddress: BillingAddress(name: 'Test User', street: 'SomeRoad 1', city: 'New York', postcode: '123'),
    companyId: 'abc',
  ));

  var account = await db.accounts.queryUserView(accountId);

  print(account!.id);

  var company = await db.companies.queryFullView('abc');

  print(company!.id);

  await db.close();
}
