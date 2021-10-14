import 'package:stormberry/stormberry.dart';

import 'tables.dart';

Future<void> main() async {
  var db = Database(
    port: 5433,
    database: 'dart_test',
    user: 'dart',
    password: 'dart',
    useSSL: false,
  );

  await db.accounts.insertOne(AccountInsertRequest(
    id: '123',
    firstName: 'Test',
    lastName: 'User',
    location: LatLng(1, 2),
    billingAddress: BillingAddress('Test User', 'SomeRoad 1', 'New York', '123'),
    companyId: 'abc',
  ));

  await db.companies.insertOne(CompanyInsertRequest(
    id: 'abc',
    name: 'Minga',
    addresses: [],
  ));

  var account = await db.accounts.queryUserView('123');

  print(account!.id);

  var company = await db.companies.queryAdminView('abc');

  print(company!.id);
}
