import 'dart:convert';

import 'package:build/build.dart';
import '../generators/join_json_generator.dart';
import '../generators/table_json_generator.dart';
import '../schema.dart';
import '../elements/view_element.dart';
import 'output_builder.dart';

class RunnerBuilder extends OutputBuilder {
  RunnerBuilder(BuilderOptions options) : super('stormberry', options);

  @override
  String buildTarget(BuildStep buildStep, AssetState asset) {
    return '''
      import 'dart:isolate';
      import 'package:stormberry/src/helpers/json_schema.dart';
      import 'package:stormberry/stormberry.dart';

      import '${buildStep.inputId.uri}';

      void main(List<String> args, SendPort port) {
        port.send(buildJsonSchema(jsonSchema));
      }

      const jsonSchema = ${LiteralValue.fix(const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
          for (var element in asset.tables.values) //
            element.tableName: TableJsonGenerator().generateJsonSchema(element),
          for (var element in asset.joinTables.values) //
            element.tableName: JoinJsonGenerator().generateJsonSchema(element),
        }))};
    ''';
  }
}
