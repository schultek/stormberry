import 'package:stormberry/src/cli/migration/differentiator.dart';
import 'package:stormberry/src/cli/migration/patcher.dart';
import 'package:stormberry/src/cli/migration/schema.dart';
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
      user: 'postgres',
      password: 'postgres',
      useSSL: false,
      debugPrint: true,
    );
    if (schema != null) {
      await tester.db.migrateTo(schema);
    }
  });

  tearDown(() async {
    if (cleanup) {
      await tester.db.query('DROP SCHEMA public CASCADE;');
      await tester.db.query('CREATE SCHEMA public;');
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

    await runTransaction(() async {
      await patchSchema(this, diff);
    });

    return diff;
  }
}
