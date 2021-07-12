import 'package:stormberry/stormberry.dart';

import 'tables.dart';

Future<void> main() async {
  var db = Database(
      port: 5433,
      database: 'dart_test',
      user: 'dart',
      password: 'dart',
      useSSL: false);

  await db.accounts.insertOne(AccountInsertRequest(
    '123',
    'Test',
    'User',
    LatLng(1, 2),
    BillingAddress('Test User', 'SomeRoad 1', 'New York'),
    null,
  ));

  var account = await db.accounts.queryUserView('123');

  print(account!.id);
}
