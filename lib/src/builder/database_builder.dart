import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import '../../annotations.dart';
import '../utils.dart';
import 'builder_snippets.dart';
import 'case_style.dart';
import 'join_table_builder.dart';
import 'table_builder.dart';

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
class DatabaseBuilder implements Builder {
  /// The global options defined in the 'build.yaml' file
  late GlobalOptions options;

  DatabaseBuilder(BuilderOptions options)
      : options = GlobalOptions.parse(options.config);

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    var resolver = buildStep.resolver;
    var inputId = buildStep.inputId;
    var outputId = inputId.changeExtension('.schema.g.dart');
    var visibleLibraries = await resolver.libraries.toList();
    try {
      var generatedSource = generate(visibleLibraries, buildStep);
      await buildStep.writeAsString(outputId, generatedSource);
    } catch (e, st) {
      print(e);
      print(st);
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.dart': ['.schema.g.dart']
      };

  /// Main generation handler
  /// Searches for mappable classes and enums recursively
  String generate(List<LibraryElement> libraries, BuildStep buildStep) {
    BuilderState state = BuilderState(options);

    var checker = const TypeChecker.fromRuntime(Table);
    var typeConverterChecker = const TypeChecker.fromRuntime(TypeConverter);

    for (var library in libraries) {
      if (library.isInSdk) {
        continue;
      }

      var reader = LibraryReader(library);

      var typeConverters = reader.annotatedWith(typeConverterChecker);
      var elements = reader.annotatedWith(checker);

      if (elements.isNotEmpty || typeConverters.isNotEmpty) {
        state.imports.add(library.source.uri);
      }

      for (var element in typeConverters) {
        var typeClassName = (element.element as ClassElement)
            .thisType
            .superclass!
            .typeArguments[0]
            .element!
            .name!;
        var converterClassName = element.element.name!;
        var sqlType =
            element.annotation.objectValue.getField('type')?.toStringValue();
        state.typeConverters[typeClassName] =
            MapEntry(converterClassName, sqlType);
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

    return <String>[
      '// ignore_for_file: unnecessary_cast, prefer_relative_imports, unused_element, prefer_single_quotes',
      "import 'dart:convert';",
      "import 'package:dartabase/dartabase.dart';",
      state.imports.map((i) => "import '$i';").join('\n'),
      'const databaseSchema = DatabaseSchema({',
      state.builders.values.map((b) => b.generateSchema()).join().indent(),
      state.joinBuilders.values.map((b) => b.generateSchema()).join().indent(),
      '});',
      '',
      generateDatabaseExtension(state),
      '',
      state.builders.values.map((b) => b.generateTableClass()).join('\n\n'),
      '',
      state.builders.values.map((b) => b.generateViews()).join('\n'),
      '',
      if (state.builders.values.any((b) => b.hasDefaultQuery))
        generateQueryParams(),
      state.builders.values.map((b) => b.generateQueries()).join('\n'),
      '',
      state.builders.values.map((b) => b.generateActions()).join('\n'),
      '',
      'var _typeConverters = <Type, TypeConverter>{',
      defaultConverters,
      state.typeConverters.entries
          .map((e) => '  _typeOf<${e.key}>(): ${e.value.key}(),')
          .join('\n'),
      '};',
      'var _decoders = <Type, Function>{',
      state.decoders.entries
          .map((e) =>
              '  _typeOf<${e.key}>(): (Map<String, dynamic> v) => ${e.value}.fromMap(v),')
          .join('\n'),
      '};',
      '',
      staticCode,
    ].join('\n');
  }

  String generateDatabaseExtension(BuilderState state) {
    return ''
        'extension DatabaseTables on Database {\n'
        '  ${state.builders.values.map((b) => '${b.element.name}Table get ${toCaseStyle(b.tableName, CaseStyle.fromString(CaseStyle.camelCase))} => ${b.element.name}Table._instanceFor(this);').join('\n  ')}\n'
        '}';
  }

  String generateQueryParams() {
    return ''
        'class QueryParams {\n'
        '  String? where;\n'
        '  String? orderBy;\n'
        '  int? limit;\n'
        '  int? offset;\n'
        '  QueryParams({this.where, this.orderBy, this.limit, this.offset});\n'
        '}\n';
  }
}
