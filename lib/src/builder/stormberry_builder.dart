import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';

import 'generators/join_json_generator.dart';
import 'generators/repository_generator.dart';
import 'generators/table_json_generator.dart';
import 'join_table_builder.dart';
import 'table_builder.dart';
import 'utils.dart';
import 'view_builder.dart';

class BuilderState {
  Set<Uri> imports = {};
  Map<Element, TableBuilder> builders = {};
  Map<String, JoinTableBuilder> joinBuilders = {};
  GlobalOptions options;

  Map<String, MapEntry<String, String?>> typeConverters = {};
  Map<String, String> decoders = {};

  BuilderState(this.options);
}

/// The main builder used for code generation
class StormberryBuilder implements Builder {
  /// The global options defined in the 'build.yaml' file
  late GlobalOptions options;

  StormberryBuilder(BuilderOptions options) : options = GlobalOptions.parse(options.config);

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    var resolver = buildStep.resolver;
    var inputId = buildStep.inputId;

    var visibleLibraries = await resolver.libraries.toList();
    try {
      var outputMap = generate(visibleLibraries, buildStep);

      for (var key in outputMap.keys) {
        var outputId = inputId.changeExtension(key);
        await buildStep.writeAsString(outputId, outputMap[key]!);
      }
    } catch (e) {
      print('\x1B[31mFailed to build database schema:\n\n$e\x1B[0m\n');
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.dart': ['.output.g.dart', '.runner.g.dart']
      };

  /// Main generation handler
  /// Searches for mappable classes and enums recursively
  Map<String, String> generate(List<LibraryElement> libraries, BuildStep buildStep) {
    BuilderState state = BuilderState(options);

    state.imports.add(Uri.parse('package:stormberry/internals.dart'));

    for (var library in libraries) {
      if (library.isInSdk) {
        continue;
      }

      var reader = LibraryReader(library);

      var typeConverters = reader.annotatedWith(typeConverterChecker);
      var elements = reader.annotatedWith(tableChecker);

      if (elements.isNotEmpty || typeConverters.isNotEmpty) {
        state.imports.add(library.source.uri);
      }

      for (var element in typeConverters) {
        var typeClassName = (element.element as ClassElement).thisType.superclass!.typeArguments[0].element!.name!;
        var converterClassName = element.element.name!;
        var sqlType = element.annotation.objectValue.getField('type')?.toStringValue();
        state.typeConverters[typeClassName] = MapEntry(converterClassName, sqlType);
      }

      for (var element in elements) {
        state.builders[element.element] = TableBuilder(
          element.element as ClassElement,
          element.annotation,
          state,
        );
      }
    }

    for (var builder in state.builders.values) {
      builder.prepareColumns();
    }

    var map = <String, String>{};

    map['.output.g.dart'] = DartFormatter(pageWidth: 120).format('''
      // ignore_for_file: prefer_relative_imports
      ${writeImports(state.imports, buildStep.inputId)}
      ${RepositoryGenerator().generateRepositories(state)}
    ''');

    map['.runner.g.dart'] = DartFormatter(pageWidth: 120).format('''
      import 'dart:isolate'; 
      import 'package:stormberry/src/helpers/json_schema.dart';
      import 'package:stormberry/stormberry.dart';
      
      import '${buildStep.inputId.uri}';
      
      void main(List<String> args, SendPort port) {
        port.send(buildJsonSchema(jsonSchema));
      }
    
      const jsonSchema = ${LiteralValue.fix(const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
          for (var def in state.builders.values) def.tableName: TableJsonGenerator().generateJsonSchema(def),
          for (var def in state.joinBuilders.values) def.tableName: JoinJsonGenerator().generateJsonSchema(def),
        }))};
    ''');

    return map;
  }
}
