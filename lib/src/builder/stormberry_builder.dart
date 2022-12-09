import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';
import 'package:path/path.dart' as path;
import 'generators/join_json_generator.dart';
import 'generators/repository_generator.dart';
import 'generators/table_json_generator.dart';
import 'join_table_builder.dart';
import 'table_builder.dart';
import 'utils.dart';
import 'view_builder.dart';

final schemaResource = Resource<SchemaState>(() => SchemaState());

class SchemaState {
  late GlobalOptions options;
  bool didPrepareColumns = false;
  Map<AssetId, AssetState> assets = {};

  Map<Element, TableBuilder> get builders => assets.values.map((a) => a.builders).reduce((a, b) => {...a, ...b});
  Map<String, JoinTableBuilder> get joinBuilders => assets.values.map((a) => a.joinBuilders).reduce((a, b) => {...a, ...b});
}

class AssetState {
  Map<Element, TableBuilder> builders = {};
  Map<String, JoinTableBuilder> joinBuilders = {};
}

class BuilderState {
  SchemaState schema;
  AssetState asset;

  BuilderState(this.schema, this.asset);
}

/// The main builder used for code generation
class StormberryBuilder implements Builder {
  /// The global options defined in the 'build.yaml' file
  late GlobalOptions options;

  StormberryBuilder(BuilderOptions options) : options = GlobalOptions.parse(options.config);

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    try {
      if (!await buildStep.resolver.isLibrary(buildStep.inputId)) {
        return;
      }
      var library = await buildStep.inputLibrary;
      await analyze(library, buildStep);
    } catch (e, st) {
      print('\x1B[31mFailed to build database schema:\n\n$e\x1B[0m\n');
      print(st);
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => const {'.dart': ['___']};

  Future<void> analyze(LibraryElement library, BuildStep buildStep) async {
    SchemaState schema = await buildStep.fetchResource(schemaResource);
    schema.options = options;

    var asset = AssetState();
    schema.assets[buildStep.inputId] = asset;

    var builderState = BuilderState(schema, asset);

    var reader = LibraryReader(library);

    var tables = reader.annotatedWith(tableChecker);

    for (var table in tables) {
      asset.builders[table.element] = TableBuilder(
        table.element as ClassElement,
        table.annotation,
        builderState,
      );
    }
  }
}

class SchemaBuilder implements Builder {
  SchemaBuilder();

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    var state = await buildStep.fetchResource(schemaResource);

    if (!state.didPrepareColumns) {
      for (var builder in state.builders.values) {
        builder.prepareColumns();
      }
      state.didPrepareColumns = true;
    }

    var asset = state.assets[buildStep.inputId];
    if (asset != null && asset.builders.isNotEmpty) {
      var formatter = DartFormatter(pageWidth: state.options.lineLength);
      buildStep.writeAsString(buildStep.inputId.changeExtension('.schema.dart'), formatter.format('''
        part of '${path.basename(buildStep.inputId.path)}';
        
        ${RepositoryGenerator().generateRepositories(asset)}
      '''));
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.dart': ['.schema.dart']
      };
}


class RunnerBuilder implements Builder {
  RunnerBuilder();

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    var state = await buildStep.fetchResource(schemaResource);
    var asset = state.assets[buildStep.inputId];
    if (asset != null && asset.builders.isNotEmpty) {
      var formatter = DartFormatter(pageWidth: state.options.lineLength);
      buildStep.writeAsString(buildStep.inputId.changeExtension('.runner.dart'), formatter.format('''
        import 'dart:isolate';
        import 'package:stormberry/src/helpers/json_schema.dart';
        import 'package:stormberry/stormberry.dart';
  
        import '${buildStep.inputId.uri}';
  
        void main(List<String> args, SendPort port) {
          port.send(buildJsonSchema(jsonSchema));
        }
  
        const jsonSchema = ${LiteralValue.fix(const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
          for (var def in asset.builders.values) def.tableName: TableJsonGenerator().generateJsonSchema(def),
          for (var def in asset.joinBuilders.values) def.tableName: JoinJsonGenerator().generateJsonSchema(def),
        }))};
      '''));
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => const {
    '.dart': ['.runner.dart']
  };
}
