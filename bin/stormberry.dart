import 'dart:convert';
import 'dart:io';

import 'package:stormberry/stormberry.dart';
import 'package:yaml/yaml.dart';

import 'src/differentiator.dart';
import 'src/patcher.dart';
import 'src/schema.dart';

Future<void> main(List<String> args) async {
  bool dryRun = args.contains('--dry-run');
  String? dbName = args.where((a) => a.startsWith('-db=')).map((a) => a.split('=')[1]).firstOrNull;
  bool applyChanges = args.contains('--apply-changes');

  var buildYaml = File('build.yaml');

  if (!buildYaml.existsSync()) {
    stdout.write('Cannot find build.yaml file in current directory.');
    exit(1);
  }

  var content = loadYaml(await buildYaml.readAsString());

  List<String>? generateTargets = (content['targets'] as YamlMap?)
      ?.values
      .map((t) => t['builders']?['stormberry'])
      .where((b) => b != null)
      .expand((b) => b['generate_for'] as List)
      .map((d) => d as String)
      .toList();

  if (generateTargets == null || generateTargets.isEmpty) {
    stdout.write(
        'Cannot find stormberry generation targets in build.yaml. Make sure you have the stormberry builder configured with at least one generation target.');
    exit(1);
  }

  var schemaPath = generateTargets.first.replaceFirst('.dart', '.schema.g.json');

  var file = File(schemaPath);
  if (!file.existsSync()) {
    stdout.write('Could not find file $schemaPath, did you run the build script?');
    exit(1);
  }
  var schemaMap = jsonDecode(await file.readAsString());
  var schema = DatabaseSchema.fromMap(schemaMap as Map<String, dynamic>);

  if (dbName == null && Platform.environment['DB_NAME'] == null) {
    stdout.write('Select a database to update: ');
    dbName = stdin.readLineSync(encoding: Encoding.getByName('utf-8')!);
  }

  var db = Database(debugPrint: false, database: dbName);

  await db.open();

  print('Getting schema changes of ${db.name}');
  print('=========================');

  var diff = await getSchemaDiff(db, schema);

  if (diff.hasChanges) {
    printDiff(diff);
    print('=========================');

    if (dryRun) {
      print('DATABASE SCHEME HAS CHANGES, EXITING');
      await db.close();
      exit(1);
    } else {
      await db.startTransaction();

      String? answerApplyChanges;
      if (!applyChanges) {
        stdout.write('Do you want to apply these changes? (yes/no): ');
        answerApplyChanges = stdin.readLineSync(encoding: Encoding.getByName('utf-8')!);
      }

      if (applyChanges || answerApplyChanges == 'yes') {
        print('Database schema changed, applying updates now:');

        try {
          db.debugPrint = true;
          await patchSchema(db, diff);
        } catch (_) {
          db.cancelTransaction();
        }
      } else {
        db.cancelTransaction();
      }

      var updateWasSuccessFull = await db.finishTransaction();

      print('========================');
      if (updateWasSuccessFull) {
        print('---\nDATABASE UPDATE SUCCESSFUL');
      } else {
        print('---\nALL CHANGES REVERTED, EXITING');
      }

      await db.close();
      exit(updateWasSuccessFull ? 0 : 1);
    }
  } else {
    print('NO CHANGES, ALL DONE');
  }
}
