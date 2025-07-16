import 'dart:convert';

import 'package:build/build.dart';
import 'package:path/path.dart' as path;

import '../generators/join_json_generator.dart';
import '../generators/table_json_generator.dart';
import '../schema.dart';
import 'output_builder.dart';

class DartBuilder extends OutputBuilder {
  DartBuilder(BuilderOptions options) : super('data.dart', options);

  @override
  String buildTarget(BuildStep buildStep, AssetState asset) {
    final jsonString =
        const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      for (var element in asset.tables.values) //
        element.tableName: TableJsonGenerator().generateJsonSchema(element),
      for (var element in asset.joinTables.values) //
        element.tableName: JoinJsonGenerator().generateJsonSchema(element),
    });

    return '''
// ignore_for_file: prefer_single_quotes, public_member_api_docs, inference_failure_on_collection_literal, lines_longer_than_80_chars, document_ignores
// Generated file, do not edit.

part of '${path.basename(buildStep.inputId.path)}';

const schema = $jsonString;
''';
  }
}
