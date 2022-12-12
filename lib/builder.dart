import 'dart:async';

import 'package:build/build.dart';

import 'src/builder/stormberry_builder.dart';

export 'src/core/case_style.dart' show CaseStyle, TextTransform;

Builder analyzeSchema(BuilderOptions options) => StormberryBuilder(options);

Builder buildSchema(BuilderOptions options) => SchemaBuilder();

Builder buildRunner(BuilderOptions options) => RunnerBuilder();