import 'package:build/build.dart';
import 'package:path/path.dart' as path;

import '../generators/repository_generator.dart';
import '../schema.dart';
import 'output_builder.dart';

class SchemaBuilder extends OutputBuilder {
  SchemaBuilder(BuilderOptions options) : super('dart', options);

  @override
  String buildTarget(BuildStep buildStep, AssetState asset) {
    return '''
      // ignore_for_file: annotate_overrides
      
      part of '${path.basename(buildStep.inputId.path)}';
      
      ${RepositoryGenerator().generateRepositories(asset)}
    ''';
  }
}
