import 'dart:async';

import 'package:build/build.dart';

import 'src/builder/stormberry_builder.dart';

export 'src/core/case_style.dart' show CaseStyle, TextTransform;

Builder analyzeSchema(BuilderOptions options) => StormberryBuilder(options);

Builder buildSchema(BuilderOptions options) => SchemaBuilder();

Builder buildRunner(BuilderOptions options) => RunnerBuilder();

Builder buildOutput(BuilderOptions options) => OutputBuilder(options);

class OutputBuilder implements Builder {
  final BuilderOptions options;

  OutputBuilder(this.options);

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    var inputId = buildStep.inputId;

    var outputId = AssetId(inputId.package, inputId.path.replaceFirst('.output.dart', '.schema.dart'));
    await buildStep.writeAsString(outputId, buildStep.readAsString(inputId));
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.output.dart': ['.schema.dart']
      };
}
