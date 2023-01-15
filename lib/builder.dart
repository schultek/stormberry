import 'package:build/build.dart';

import 'src/builder/builders/runner_builder.dart';
import 'src/builder/builders/schema_builder.dart';
import 'src/builder/builders/analyzing_builder.dart';

export 'src/core/case_style.dart' show CaseStyle, TextTransform;

Builder analyzeSchema(BuilderOptions options) => AnalyzingBuilder(options);

Builder buildSchema(BuilderOptions options) => SchemaBuilder(options);

Builder buildRunner(BuilderOptions options) => RunnerBuilder(options);
