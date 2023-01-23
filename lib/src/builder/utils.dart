import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import '../../stormberry.dart';
import '../core/case_style.dart';

const tableChecker = TypeChecker.fromRuntime(Model);
const typeConverterChecker = TypeChecker.fromRuntime(TypeConverter);
const primaryKeyChecker = TypeChecker.fromRuntime(PrimaryKey);
const autoIncrementChecker = TypeChecker.fromRuntime(AutoIncrement);
const changedInChecker = TypeChecker.fromRuntime(ChangedIn);
const useConverterChecker = TypeChecker.fromRuntime(UseConverter);

/// The global builder options from the build.yaml file
class GlobalOptions {
  CaseStyle? tableCaseStyle;
  CaseStyle? columnCaseStyle;
  int lineLength;

  GlobalOptions.parse(Map<String, dynamic> options)
      : tableCaseStyle = CaseStyle.fromString(options['tableCaseStyle'] as String? ??
            options['table_case_style'] as String? ??
            'snakeCase'),
        columnCaseStyle = CaseStyle.fromString(options['columnCaseStyle'] as String? ??
            options['column_case_style'] as String? ??
            'snakeCase'),
        lineLength = options['lineLength'] as int? ?? options['line_length'] as int? ?? 100;
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
      var props = annotation.arguments!.arguments
          .whereType<NamedExpression>()
          .where((e) => e.name.label.name == property);

      if (props.isNotEmpty) {
        return props.first.expression.toSource();
      }
    }
  }

  return null;
}

extension ObjectSource on DartObject {
  String toSource() {
    return ConstantReader(this).toSource();
  }
}

extension ReaderSource on ConstantReader {
  String toSource() {
    if (isLiteral) {
      if (isString) {
        return "'$literalValue'";
      }
      return literalValue!.toString();
    }

    if (isType) {
      return typeValue.getDisplayString(withNullability: true);
    }

    var rev = revive();

    var str = '';
    if (rev.source.fragment.isNotEmpty) {
      str = rev.source.fragment;

      if (rev.accessor.isNotEmpty) {
        str += '.${rev.accessor}';
      }
      str += '(';
      var isFirst = true;

      for (var p in rev.positionalArguments) {
        if (!isFirst) {
          str += ', ';
        }
        isFirst = false;
        str += p.toSource();
      }

      for (var p in rev.namedArguments.entries) {
        if (!isFirst) {
          str += ', ';
        }
        isFirst = false;
        str += '${p.key}: ${p.value.toSource()}';
      }

      str += ')';
    } else {
      str = rev.accessor;
    }
    return str;
  }
}

String defineClassWithMeta(String className, ConstantReader? meta, {String? mixin}) {
  if (meta == null || meta.isNull) {
    return 'class $className${mixin != null ? ' with $mixin' : ''} {\n';
  }

  String readClause(String field, String keyword, [String? additional]) {
    var items = [
      if (!meta.read(field).isNull) meta.read(field).stringValue.replaceAll('{name}', className),
      if (additional != null) additional,
    ];
    return items.isEmpty ? '' : ' $keyword ${items.join(', ')}';
  }

  var annotation = meta.read('annotation').isNull ? '' : '@${meta.read('annotation').toSource()}\n';
  var extendClause = readClause('extend', 'extends');
  var withClause = readClause('mixin', 'with', mixin);
  var implementClause = readClause('implement', 'implements');
  return '${annotation}class $className$extendClause$withClause$implementClause {\n';
}
