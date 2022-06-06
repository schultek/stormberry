import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

import '../../internals.dart';
import '../core/case_style.dart';

const tableChecker = TypeChecker.fromRuntime(Model);
const typeConverterChecker = TypeChecker.fromRuntime(TypeConverter);
const primaryKeyChecker = TypeChecker.fromRuntime(PrimaryKey);
const autoIncrementChecker = TypeChecker.fromRuntime(AutoIncrement);

/// The global builder options from the build.yaml file
class GlobalOptions {
  CaseStyle? tableCaseStyle;
  CaseStyle? columnCaseStyle;

  GlobalOptions.parse(Map<String, dynamic> options)
      : tableCaseStyle = CaseStyle.fromString(options['tableCaseStyle'] as String? ?? 'snakeCase'),
        columnCaseStyle = CaseStyle.fromString(options['columnCaseStyle'] as String? ?? 'snakeCase');
}

extension GetNode on Element {
  AstNode? getNode() {
    var result = session?.getParsedLibraryByElement(library!);
    if (result is ParsedLibraryResult) {
      return result.getElementDeclaration(this)?.node;
    } else {
      return null;
    }
  }
}

String? getAnnotationCode(Element annotatedElement, Type annotationType, String property) {
  var node = annotatedElement.getNode();

  NodeList<Annotation> annotations;

  if (node is VariableDeclaration) {
    var parent = node.parent?.parent;
    if (parent is FieldDeclaration) {
      annotations = parent.metadata;
    } else {
      return null;
    }
  } else if (node is Declaration) {
    annotations = node.metadata;
  } else {
    return null;
  }

  for (var annotation in annotations) {
    if (annotation.name.name == annotationType.toString()) {
      var props =
          annotation.arguments!.arguments.whereType<NamedExpression>().where((e) => e.name.label.name == property);

      if (props.isNotEmpty) {
        return props.first.expression.toSource();
      }
    }
  }

  return null;
}
