import 'package:build/build.dart';

import 'src/builder/stormberry_builder.dart';

export 'src/core/case_style.dart' show CaseStyle, TextTransform;

/// Entry point for the builder
StormberryBuilder buildSchema(BuilderOptions options) =>
    StormberryBuilder(options);
