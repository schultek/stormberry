import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:stormberry/src/cli/runner.dart';

Future<void> main(List<String> args) async {
  var runner = CommandRunner<void>(
    'stormberry',
    'Tool for migrating your database to the schema generated from your models.',
  )..addCommand(MigrateCommand());

  try {
    await runner.run(args);
    exit(0);
  } on UsageException catch (e) {
    print('${e.message}\n${e.usage}');
    exit(1);
  } catch (e, st) {
    print('$e\n$st');
    exit(1);
  }
}
