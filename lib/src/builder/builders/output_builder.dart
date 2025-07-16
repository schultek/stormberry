import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';

import '../schema.dart';
import '../utils.dart';

abstract class OutputBuilder implements Builder {
  OutputBuilder(this.ext, BuilderOptions options)
      : options = GlobalOptions.parse(options.config);

  final String ext;
  final GlobalOptions options;

  String buildTarget(BuildStep buildStep, AssetState asset);

  @override
  Future<void> build(BuildStep buildStep) async {
    if (!await buildStep.resolver.isLibrary(buildStep.inputId)) {
      return;
    }

    await buildStep.inputLibrary;

    try {
      var state = await buildStep.fetchResource(schemaResource);
      var asset = state.getForAsset(buildStep.inputId);

      if (asset != null && asset.tables.isNotEmpty) {
        var output = buildTarget(buildStep, asset);
        if (ext == 'dart') {
          var formatter = DartFormatter(
            pageWidth: options.lineLength,
            languageVersion: DartFormatter.latestLanguageVersion,
          );
          output = formatter.format(output);
        }

        await buildStep.writeAsString(
            buildStep.inputId.changeExtension('.schema.$ext'), output);
      }
    } catch (e, st) {
      print('\x1B[31mFailed to build database schema:\n\n$e\x1B[0m\n');
      print(st);
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': ['.schema.$ext']
      };
}
