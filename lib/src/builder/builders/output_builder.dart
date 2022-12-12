import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';

import '../schema.dart';
import '../utils.dart';

abstract class OutputBuilder implements Builder {
  OutputBuilder(this.target, BuilderOptions options) : options = GlobalOptions.parse(options.config);

  final String target;
  final GlobalOptions options;

  String buildTarget(BuildStep buildStep, AssetState asset);

  @override
  Future<void> build(BuildStep buildStep) async {
    await buildStep.inputLibrary;
    var state = await buildStep.fetchResource(schemaResource);
    var asset = state.getForAsset(buildStep.inputId);

    if (asset != null && asset.tables.isNotEmpty) {
      var formatter = DartFormatter(pageWidth: options.lineLength);

      buildStep.writeAsString(buildStep.inputId.changeExtension('.$target.dart'), formatter.format(buildTarget(buildStep, asset)));
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': ['.$target.dart']
  };
}