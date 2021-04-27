import 'package:build/build.dart';

import 'src/builder/database_builder.dart';

export 'src/builder/case_style.dart' show CaseStyle, TextTransform;

/// Entry point for the builder
DatabaseBuilder buildDatabase(BuilderOptions options) =>
    DatabaseBuilder(options);
