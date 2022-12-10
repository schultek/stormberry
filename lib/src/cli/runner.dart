import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:args/command_runner.dart';
import 'package:yaml/yaml.dart';

import '../../stormberry.dart';
import 'differentiator.dart';
import 'output.dart';
import 'patcher.dart';
import 'schema.dart';

class MigrateCommand extends Command<void> {
  MigrateCommand() {
    argParser.addFlag(
      'dry-run',
      negatable: false,
      help: 'Returns exit code 1 if there are any pending migrations. '
          'Does not apply any changes to the database.',
    );
    argParser.addOption('db', help: 'Set the database name.');
    argParser.addOption('host', help: 'Set the database host.');
    argParser.addOption('port', help: 'Set the database port.');
    argParser.addOption('username', help: 'Set the database username.');
    argParser.addOption('password', help: 'Set the database password.');

    argParser.addFlag(
      'ssl',
      negatable: true,
      defaultsTo: null,
      help: 'Whether or not this connection should connect securely.',
    );

    argParser.addFlag(
      'unix-socket',
      negatable: true,
      defaultsTo: null,
      help: 'Whether or not the connection is made via unix socket.',
    );

    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Specify an output directory. This will write all migrations into .sql '
          'files instead of writing to the database.',
    );

    argParser.addFlag(
      'apply-changes',
      negatable: false,
      help: 'Applies all changes to the database without asking for confirmation.',
    );
  }

  @override
  String get description => 'Migrates the database to the generated schema.';

  @override
  String get name => 'migrate';

  @override
  Future<void> run() async {
    bool dryRun = argResults!['dry-run'] as bool;
    String? output = argResults!['output'] as String?;
    bool applyChanges = argResults!['apply-changes'] as bool;
    String? dbHostAddress = argResults!['host'] as String?;
    int? dbPort = argResults!['port'] as int?;
    String? dbName = argResults!['db'] as String?;
    String? dbUsername = argResults!['username'] as String?;
    String? dbPassword = argResults!['password'] as String?;
    bool? dbSSL = argResults!['ssl'] as bool?;
    bool? dbSocket = argResults!['unix-socket'] as bool?;

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
        //automaticPackageResolution: true,
      );

      var schemaMap = jsonDecode(await port.first as String);
      var targetSchema = DatabaseSchema.fromMap(schemaMap as Map<String, dynamic>);

      schema = schema.mergeWith(targetSchema);
    }

    if (dbName == null && Platform.environment['DB_NAME'] == null) {
      stdout.write('Select a database to update : ');
      dbName = stdin.readLineSync(encoding: Encoding.getByName('utf-8')!);
    }

    if (dbHostAddress == null &&
        Platform.environment['DB_HOST_ADDRESS'] == null) {
      stdout.write('Enter the DB host address : ');
      dbHostAddress =
          stdin.readLineSync(encoding: Encoding.getByName('utf-8')!);

      if (dbHostAddress?.isEmpty ?? true) {
        dbHostAddress = null;
      }
    }

    if (dbPort == null && Platform.environment['DB_PORT'] == null) {
      stdout.write('Enter the DB port : ');
      final input = stdin.readLineSync();

      dbPort = int.tryParse(input ?? '');
    }

    if (dbUsername == null && Platform.environment['DB_USERNAME'] == null) {
      stdout.write('Enter the DB username : ');
      dbUsername = stdin.readLineSync(encoding: Encoding.getByName('utf-8')!);

      if (dbUsername?.isEmpty ?? true) {
        dbUsername = null;
      }
    }

    if (dbPassword == null && Platform.environment['DB_PASSWORD'] == null) {
      stdout.write('Enter the DB password : ');
      stdin.echoMode = false;

      dbPassword = stdin.readLineSync(encoding: Encoding.getByName('utf-8')!);

      stdin.echoMode = true;
      stdout.writeln();

      if (dbPassword?.isEmpty ?? true) {
        dbPassword = null;
      }
    }

    bool? useSSL;
    bool? isUnixSocket;

    if (dbSSL == null && Platform.environment['DB_SSL'] == null) {
      stdout.write('Use SSL ? (yes/no): ');
      final input = stdin.readLineSync(encoding: Encoding.getByName('utf-8')!);

      useSSL = input == null ? null : input == 'yes';
    }

    if (dbSocket == null && Platform.environment['DB_SOCKET'] == null) {
      stdout.write('Use unix socket ? (yes/no): ');
      final input = stdin.readLineSync(encoding: Encoding.getByName('utf-8')!);

      isUnixSocket = input == null ? null : input == 'yes';
    }

    var db = Database(
      database: dbName,
      host: dbHostAddress,
      port: dbPort,
      useSSL: useSSL,
      password: dbPassword,
      user: dbUsername,
      isUnixSocket: isUnixSocket,
    );

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
        if (output == null) {
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
        } else {
          await db.close();
          var dir = Directory(output);

          String? answerApplyChanges;
          if (!applyChanges) {
            stdout.write('Do you want to write these migrations to ${dir.path}? (yes/no): ');
            answerApplyChanges = stdin.readLineSync(encoding: Encoding.getByName('utf-8')!);
          }

          if (applyChanges || answerApplyChanges == 'yes') {
            if (!dir.existsSync()) {
              dir.createSync(recursive: true);
            }

            await outputSchema(dir, diff);
          }
        }
      }
    } else {
      print('NO CHANGES, ALL DONE');
    }
  }
}
