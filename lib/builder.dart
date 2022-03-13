import 'dart:async';

import 'package:build/build.dart';

import 'src/builder/stormberry_builder.dart';

export 'src/core/case_style.dart' show CaseStyle, TextTransform;

/// Entry point for the builder
StormberryBuilder buildSchema(BuilderOptions options) => StormberryBuilder(options);

Builder buildOutput(BuilderOptions options) => OutputBuilder(options);

class OutputBuilder implements Builder {
  final BuilderOptions options;

  OutputBuilder(this.options);

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    var inputId = buildStep.inputId;

    var outputId = AssetId(inputId.package, inputId.path.replaceFirst('.output.g.dart', '.schema.g.dart'));
    await buildStep.writeAsString(outputId, buildStep.readAsString(inputId));
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.output.g.dart': ['.schema.g.dart']
      };
}

PostProcessBuilder outputCleanup(BuilderOptions options) => const FileDeletingBuilder(['.output.g.dart']);
