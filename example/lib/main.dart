import 'package:stormberry/stormberry.dart';

import 'models.dart';

Future<void> main() async {
  var db = Database(
    port: 2222,
    database: 'dart_test',
    user: 'postgres',
    password: 'postgres',
    useSSL: false,
  );

  db.debugPrint = true;

  await db.companies.insertOne(CompanyInsertRequest(
    id: 'abc',
    name: 'Minga',
    addresses: [],
  ));

  await db.accounts.insertOne(AccountInsertRequest(
    id: '123',
    firstName: 'Test',
    lastName: 'User',
    location: LatLng(1, 2),
    billingAddress: BillingAddress(name: 'Test User', street: 'SomeRoad 1', city: 'New York', postcode: '123'),
    companyId: 'abc',
  ));

  var account = await db.accounts.queryUserView('123');

  print(account!.id);

  var company = await db.companies.queryAdminView('abc');

  print(company!.id);

  await db.close();
}
