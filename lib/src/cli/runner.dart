import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:yaml/yaml.dart';

import '../../stormberry.dart';
import 'migration/differentiator.dart';
import 'migration/output.dart';
import 'migration/patcher.dart';
import 'migration/schema.dart';

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

    argParser.addFlag(
      'defaults',
      negatable: false,
      help: 'Whether to use default values for the not-provided connection props. If this is false '
          'the cli will ask for all missing props.',
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

    var pubspecYaml = File('pubspec.yaml');

    if (!pubspecYaml.existsSync()) {
      print('Cannot find pubspec.yaml file in current directory.');
      exit(1);
    }

    var packageName = loadYaml(await pubspecYaml.readAsString())['name'] as String;

    var schema =
        await DatabaseSchema.load('.dart_tool/build/generated/$packageName/lib/**.schema.json');

    if (schema.tables.isEmpty) {
      print('Could not run migration, because there are no models found. Did you run the build?');
      exit(1);
    }

    var dbName =
        resolveProperty<String>(arg: 'db', env: 'DB_NAME', prompt: 'Select a database to update: ');
    var dbHost = resolveProperty<String>(
        arg: 'host', env: 'DB_HOST_ADDRESS', prompt: 'Enter the database host address: ');
    var dbPort =
        resolveProperty<int>(arg: 'port', env: 'DB_PORT', prompt: 'Enter the database port: ');
    var dbUsername = resolveProperty<String>(
        arg: 'username', env: 'DB_USERNAME', prompt: 'Enter the database username: ');
    var dbPassword = resolveProperty<String>(
        arg: 'password',
        env: 'DB_PASSWORD',
        prompt: 'Enter the database password: ',
        obscureInput: true);
    var useSSL = resolveProperty<bool>(arg: 'ssl', env: 'DB_SSL');
    var isUnixSocket = resolveProperty<bool>(arg: 'unix-socket', env: 'DB_SOCKET');

    var db = Database(
      host: dbHost,
      port: dbPort,
      database: dbName,
      password: dbPassword,
      username: dbUsername,
      useSSL: useSSL,
      isUnixSocket: isUnixSocket,
    );

    await db.open();

    print('Getting schema changes of $dbName');
    print('=========================');

    var diff = await schema.computeDiff(db);

    if (diff.hasChanges) {
      diff.printToConsole();
      print('=========================');

      if (dryRun) {
        print('DATABASE SCHEME HAS CHANGES, EXITING');
        await db.close();
        exit(1);
      } else {
        if (output == null) {
          String? answerApplyChanges;
          if (!applyChanges) {
            stdout.write('Do you want to apply these changes? (yes/no): ');
            answerApplyChanges = stdin.readLineSync(encoding: Encoding.getByName('utf-8')!);
          }

          var updateWasSuccessFull = false;

          if (applyChanges || answerApplyChanges == 'yes') {
            print('Database schema changed, applying updates now:');

            db.debugPrint = true;
            updateWasSuccessFull = await db.runTx((session) async {
              await diff.patch(db);
              return true;
            });
            db.debugPrint = false;
          }

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

  T? resolveProperty<T>({
    required String arg,
    required String env,
    String? prompt,
    bool obscureInput = false,
  }) {
    var result = argResults![arg];
    if (result != null) {
      if (result is T) {
        return result;
      } else if (result is String && T == int) {
        return int.tryParse(result) as T;
      }
    }

    bool useDefaults = argResults!['defaults'] as bool;
    if (useDefaults || Platform.environment[env] != null) {
      return null;
    }

    if (prompt != null) {
      stdout.write(prompt);

      if (obscureInput) {
        stdin.echoMode = false;
      }

      var input = stdin.readLineSync(encoding: Encoding.getByName('utf-8')!);

      if (obscureInput) {
        stdin.echoMode = true;
        stdout.writeln();
      }

      if (input != null && input.isNotEmpty) {
        if (T == String) {
          return input as T;
        } else if (T == int) {
          return int.tryParse(input) as T?;
        } else if (T == bool) {
          return input == 'yes'
              ? true as T
              : input == 'no'
                  ? false as T
                  : null;
        }
      }
    }

    return null;
  }
}
