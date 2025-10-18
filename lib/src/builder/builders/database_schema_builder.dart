import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';

class DatabaseSchemaBuilder implements Builder {
  DatabaseSchemaBuilder();

  @override
  Future<void> build(BuildStep buildStep) async {
    var allSchemas =
        await buildStep
            .findAssets(Glob('lib/**.schema.json'))
            .asyncMap((id) => buildStep.readAsString(id))
            .map((c) => jsonDecode(c))
            .toList();

    var fullSchema = <String, dynamic>{};
    for (var schema in allSchemas) {
      fullSchema.addAll(schema as Map<String, dynamic>);
    }

    final output =
        '// GENERATED CODE - DO NOT MODIFY BY HAND\n\n'
        '// ignore_for_file: type=lint\n'
        '// dart format off\n\n'
        'import \'package:stormberry/migrate.dart\';\n\n'
        'final DatabaseSchema schema = DatabaseSchema.fromMap(${const JsonEncoder.withIndent('  ').convert(fullSchema)});\n';

    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, 'lib/database.schema.dart'),
      output,
    );
  }

  @override
  Map<String, List<String>> get buildExtensions => {
    r'$lib$': ['database.schema.dart'],
  };
}
