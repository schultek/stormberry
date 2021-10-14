import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import '../core/annotations.dart';
import '../core/case_style.dart';
import '../helpers/builder_snippets.dart';
import '../helpers/utils.dart';
import 'join_table_builder.dart';
import 'json_builder.dart';
import 'table_builder.dart';

const tableChecker = TypeChecker.fromRuntime(Table);
const typeConverterChecker = TypeChecker.fromRuntime(TypeConverter);
const primaryKeyChecker = TypeChecker.fromRuntime(PrimaryKey);

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
    } catch (e, st) {
      print(e);
      print(st);
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.dart': ['.schema.g.dart', '.schema.g.json']
      };

  /// Main generation handler
  /// Searches for mappable classes and enums recursively
  Map<String, String> generate(List<LibraryElement> libraries, BuildStep buildStep) {
    BuilderState state = BuilderState(options);

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

    map['.schema.g.dart'] = <String>[
      '// ignore_for_file: unnecessary_cast, prefer_relative_imports, unused_element, prefer_single_quotes',
      "import 'dart:convert';",
      "import 'package:stormberry/stormberry.dart';",
      state.imports.map((i) => "import '$i';").join('\n'),
      '',
      generateDatabaseExtension(state),
      '',
      state.builders.values.map((b) => b.generateTableClass()).join('\n\n'),
      '',
      state.builders.values.map((b) => b.generateViews()).join('\n'),
      '',
      state.builders.values.map((b) => b.generateActions()).join('\n'),
      '',
      'var _typeConverters = <Type, TypeConverter>{',
      defaultConverters,
      state.typeConverters.entries.map((e) => '  _typeOf<${e.key}>(): ${e.value.key}(),').join('\n'),
      '};',
      'var _decoders = <Type, Function>{',
      state.decoders.entries
          .map((e) => '  _typeOf<${e.key}>(): (Map<String, dynamic> v) => ${e.value}.fromMap(v),')
          .join('\n'),
      '};',
      '',
      staticCode,
    ].join('\n');

    map['.schema.g.json'] = const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      for (var builder in state.builders.values) builder.tableName: builder.generateJsonSchema(),
      for (var builder in state.joinBuilders.values) builder.tableName: builder.generateJsonSchema(),
    });

    return map;
  }

  String generateDatabaseExtension(BuilderState state) {
    return 'extension DatabaseTables on Database {\n'
        '  ${state.builders.values.map((b) => '${b.element.name}Table get ${CaseStyle.camelCase.transform(b.tableName)} => BaseTable.get(this, () => ${b.element.name}Table._(this));').join('\n  ')}\n'
        '}';
  }
}
