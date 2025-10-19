import 'package:stormberry/migrate.dart';
import 'package:stormberry/stormberry.dart';

import 'database.schema.dart';
import 'models/account.dart';
import 'models/address.dart';
import 'models/company.dart';
import 'models/latlng.dart';
import 'models/party.dart';

Future<void> main() async {
  var db = Database(
    port: 2222,
    database: 'dart_test',
    username: 'postgres',
    password: 'postgres',
    useSSL: false,
  );

  db.debugPrint = true;

  await migrate(db);

  await db.companies.deleteOne('abc');
  await db.companies.insertOne(CompanyInsertRequest(id: 'abc', name: 'Minga', addresses: []));

  await db.accounts.deleteMany([0, 1, 2]);

  var accountId = await db.accounts.insertOne(
    AccountInsertRequest(
      firstName: 'Test',
      lastName: 'User',
      location: LatLng(1, 2),
      billingAddress: BillingAddress(
        name: 'Test User',
        street: 'SomeRoad 1',
        city: 'New York',
        postcode: '123',
      ),
      companyId: 'abc',
    ),
  );

  var account = await db.accounts.queryUserView(accountId);
  print((account!.id, account.parties));

  await db.parties.deleteOne('party1');
  await db.parties.insertOne(PartyInsertRequest(id: 'party1', name: 'Party 1', date: 1));

  await db.accounts.updateOne(
    AccountUpdateRequest(id: accountId, parties: UpdateValues.add(['party1'])),
  );

  account = await db.accounts.queryUserView(accountId);
  print((account!.id, account.parties));

  var company = await db.companies.queryFullView('abc');
  print(company!.id);

  await db.close();
}

Future<void> migrate(Database db) async {
  final diff = await schema.computeDiff(db);

  diff.printToConsole();

  try {
    await db.runTx((session) async {
      await diff.patch(session);
    });
    print('Migration succeeded');
  } catch (e) {
    print('Migration failed: $e');
  }
}
