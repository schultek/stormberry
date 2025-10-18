import 'dart:convert';

import 'package:build/build.dart';
import '../schema.dart';
import 'output_builder.dart';

class JsonBuilder extends OutputBuilder {
  JsonBuilder(BuilderOptions options) : super('json', options);

  @override
  String buildTarget(BuildStep buildStep, AssetState asset) {
    return const JsonEncoder.withIndent('  ').convert(asset.getJsonData());
  }
}
