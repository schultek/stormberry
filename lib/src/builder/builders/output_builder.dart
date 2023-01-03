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

    try {
      var state = await buildStep.fetchResource(schemaResource);
      var asset = state.getForAsset(buildStep.inputId);

      if (asset != null && asset.tables.isNotEmpty) {
        var formatter = DartFormatter(pageWidth: options.lineLength);

        await buildStep.writeAsString(
          buildStep.inputId.changeExtension('.$target.dart'),
          formatter.format(buildTarget(buildStep, asset)),
        );
      }
    } catch (e, st) {
      print('\x1B[31mFailed to build database schema:\n\n$e\x1B[0m\n');
      print(st);
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': ['.$target.dart']
      };
}
