import 'dart:convert';

import 'package:build/build.dart';
import '../generators/join_json_generator.dart';
import '../generators/table_json_generator.dart';
import '../schema.dart';
import 'output_builder.dart';

class JsonBuilder extends OutputBuilder {
  JsonBuilder(BuilderOptions options) : super('json', options);

  @override
  String buildTarget(BuildStep buildStep, AssetState asset) {
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      for (var element in asset.tables.values) //
        element.tableName: TableJsonGenerator().generateJsonSchema(element),
      for (var element in asset.joinTables.values) //
        element.tableName: JoinJsonGenerator().generateJsonSchema(element),
    });
  }
}
