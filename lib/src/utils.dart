import 'package:analyzer/dart/element/type.dart';

import 'core/case_style.dart';

extension NullableWhere<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) {
      return null;
    } else {
      return first;
    }
  }
}

class Optional<T> {
  T value;
  Optional(this.value);

  T get() => value;
}

/// The global builder options from the build.yaml file
class GlobalOptions {
  CaseStyle? tableCaseStyle;
  CaseStyle? columnCaseStyle;

  GlobalOptions.parse(Map<String, dynamic> options)
      : tableCaseStyle = CaseStyle.fromString(
            options['tableCaseStyle'] as String? ?? 'snakeCase'),
        columnCaseStyle = CaseStyle.fromString(
            options['columnCaseStyle'] as String? ?? 'snakeCase');
}

extension PrimitiveType on DartType {
  bool get isPrimitive {
    if (isDartCoreList) {
      return (this as InterfaceType).typeArguments[0].isPrimitive;
    } else if (isDartCoreMap) {
      return (this as InterfaceType).typeArguments[0].isPrimitive &&
          (this as InterfaceType).typeArguments[1].isPrimitive;
    } else {
      return isDynamic ||
          isDartCoreBool ||
          isDartCoreInt ||
          isDartCoreDouble ||
          isDartCoreNum ||
          isDartCoreString ||
          isDartCoreNull ||
          isDartCoreObject;
    }
  }
}

extension StringIndent on String {
  String indent([String pad = '  ']) {
    return split('\n').map((l) => '$pad$l').join('\n');
  }
}
