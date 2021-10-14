import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';

import '../table_builder.dart';
import 'action_builder.dart';

class CustomActionBuilder extends ActionBuilder {
  DartObject annotation;
  CustomActionBuilder(this.annotation, TableBuilder table) : super(table);

  @override
  String generateActionMethod() {
    var requestClassName =
        (annotation.type!.element! as ClassElement).supertype!.typeArguments[0].getDisplayString(withNullability: true);
    var className = annotation.type!.element!.name!;
    return 'Future<void> execute$className($requestClassName request) {\n'
        '  return run($className(), request);\n'
        '}';
  }

  @override
  String? generateActionClass() {
    return null;
  }
}
