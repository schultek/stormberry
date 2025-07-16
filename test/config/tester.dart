import 'package:stormberry/stormberry.dart';
import 'package:test/test.dart';

class StormberryTester {
  late Database db;
}

StormberryTester useTester({String? schema, bool cleanup = false}) {
  var tester = StormberryTester();

  setUp(() async {
    tester.db = Database(
      host: 'localhost',
      port: 5432,
      database: 'postgres',
      username: 'postgres',
      password: 'postgres',
    );
    if (schema != null) {
      await tester.db.migrateTo(schema);
    }
  });

  tearDown(() async {
    if (cleanup) {
      await tester.db.execute('DROP SCHEMA public CASCADE;');
      await tester.db.execute('CREATE SCHEMA public;');
    }
    await tester.db.close();
  });

  return tester;
}

extension SchemaChanger on Database {
  Future<DatabaseSchemaDiff> migrateTo(String glob, {bool log = true}) async {
    var schema = await DatabaseSchema.load(
      '.dart_tool/build/generated/stormberry/test/$glob.schema.json',
    );

    var diff = await getSchemaDiff(this, schema);
    if (log) {
      printDiff(diff);
    }

    await runTx((session) async {
      await patchSchema(session, diff);
    });

    return diff;
  }
}
