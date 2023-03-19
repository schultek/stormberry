import 'package:build/build.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:build_test/build_test.dart';

Future<Map<AssetId, List<int>>> testBuilder2(
  Builder builder,
  Map<String, /*String|List<int>*/ Object> sourceAssets, {
  Set<String>? generateFor,
  bool Function(String assetId)? isInput,
  String? rootPackage,
  MultiPackageAssetReader? reader,
  RecordingAssetWriter? writer,
  ResourceManager? resourceManager,
  Map<String, /*String|List<int>|Matcher<List<int>>*/ Object>? outputs,
}) async {
  writer ??= InMemoryAssetWriter();

  var inputIds = {for (var descriptor in sourceAssets.keys) makeAssetId(descriptor)};
  var allPackages = {for (var id in inputIds) id.package};
  if (allPackages.length == 1) rootPackage ??= allPackages.first;

  inputIds.addAll([
    for (var package in allPackages) AssetId(package, r'lib/$lib$'),
    if (rootPackage != null) ...[
      AssetId(rootPackage, r'$package$'),
      AssetId(rootPackage, r'test/$test$'),
      AssetId(rootPackage, r'web/$web$'),
    ]
  ]);

  final inMemoryReader = InMemoryAssetReader(rootPackage: rootPackage);

  sourceAssets.forEach((serializedId, contents) {
    var id = makeAssetId(serializedId);
    if (contents is String) {
      inMemoryReader.cacheStringAsset(id, contents);
    } else if (contents is List<int>) {
      inMemoryReader.cacheBytesAsset(id, contents);
    }
  });

  final inputFilter = isInput ?? generateFor?.contains ?? (_) => true;
  inputIds.retainWhere((id) => inputFilter('$id'));

  var writerSpy = AssetWriterSpy(writer);
  var resolvers = AnalyzerResolvers();

  for (var input in inputIds) {
    // create another writer spy and reader for each input. This prevents writes
    // from a previous input being readable when processing the current input.
    final spyForStep = AssetWriterSpy(writerSpy);
    final readerForStep = MultiAssetReader([
      inMemoryReader,
      if (reader != null) reader,
      WrittenAssetReader(writer, spyForStep),
    ]);

    await runBuilder(builder, {input}, readerForStep, spyForStep, resolvers,
        resourceManager: resourceManager);
  }

  var actualOutputs = writerSpy.assetsWritten;
  checkOutputs(outputs, actualOutputs, writer);
  return {...writer.assets};
}
