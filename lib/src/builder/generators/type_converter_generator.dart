import 'package:analyzer/dart/element/element.dart';

import '../stormberry_builder.dart';

class TypeConverterGenerator {
  String generateTypeConverters(BuilderState state) {
    return '''
    ${state.enums.map(generateEnumTypeConverter).join('\n')}
  ''';
  }

  String generateEnumTypeConverter(EnumElement e) {
    var typeConverterName = '_Stormberry${e.name}TypeConverter';

    return '''
      class $typeConverterName extends TypeConverter<${e.name}> { 
        @override
        String encode(${e.name} value) => value.name;

        @override
        ${e.name} decode(dynamic value) => ${e.name}.values.byName(value as String);
      }
    ''';
  }
}
