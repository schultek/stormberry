import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:stormberry/stormberry.dart';
import 'package:yaml/yaml.dart';

import 'src/differentiator.dart';
import 'src/patcher.dart';
import 'src/schema.dart';

Future<void> main(List<String> args) async {
  bool dryRun = args.contains('--dry-run');
  String? dbName = args.where((a) => a.startsWith('-db=')).map((a) => a.split('=')[1]).firstOrNull;
  bool applyChanges = args.contains('--apply-changes');

  var pubspecYaml = File('pubspec.yaml');

  if (!pubspecYaml.existsSync()) {
    print('Cannot find pubspec.yaml file in current directory.');
    exit(1);
  }

  var packageName = loadYaml(await pubspecYaml.readAsString())['name'] as String;

  var buildYaml = File('build.yaml');

  if (!buildYaml.existsSync()) {
    print('Cannot find build.yaml file in current directory.');
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
    print('Cannot find stormberry generation targets in build.yaml. '
        'Make sure you have the stormberry builder configured with at least one generation target.');
    exit(1);
  }

  var schema = DatabaseSchema.empty();

  for (var target in generateTargets) {
    var schemaPath = target.replaceFirst('.dart', '.runner.g.dart');
    var file = File('.dart_tool/build/generated/$packageName/$schemaPath');
    if (!file.existsSync()) {
      print('Could not run migration for target $target. Did you run the build script?');
      exit(1);
    }

    var port = ReceivePort();
    await Isolate.spawnUri(
      file.absolute.uri,
      [],
      port.sendPort,
      packageConfig: Uri.parse('.dart_tool/package_config.json'),
    );

    var schemaMap = jsonDecode(await port.first as String);
    var targetSchema = DatabaseSchema.fromMap(schemaMap as Map<String, dynamic>);

    schema = schema.mergeWith(targetSchema);
  }

  if (dbName == null && Platform.environment['DB_NAME'] == null) {
    stdout.write('Select a database to update: ');
    dbName = stdin.readLineSync(encoding: Encoding.getByName('utf-8')!);
  }

  var db = Database(database: dbName);

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
