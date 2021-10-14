import 'package:analyzer/dart/constant/value.dart';

import '../table_builder.dart';
import 'custom_action_builder.dart';
import 'delete_action_builder.dart';
import 'insert_action_builder.dart';
import 'update_action_builder.dart';

abstract class ActionBuilder {
  TableBuilder table;

  ActionBuilder(this.table);

  factory ActionBuilder.get(TableBuilder table, DartObject annotation) {
    var className = annotation.type!.element!.name!;
    if (className == 'SingleInsertAction') {
      return SingleInsertActionBuilder(table);
    } else if (className == 'MultiInsertAction') {
      return MultiInsertActionBuilder(table);
    } else if (className == 'SingleUpdateAction') {
      return SingleUpdateActionBuilder(table);
    } else if (className == 'MultiUpdateAction') {
      return MultiUpdateActionBuilder(table);
    } else if (className == 'SingleDeleteAction') {
      return SingleDeleteActionBuilder(table);
    } else if (className == 'MultiDeleteAction') {
      return MultiDeleteActionBuilder(table);
    } else {
      return CustomActionBuilder(annotation, table);
    }
  }

  String generateActionMethod();
  String? generateActionClass();
}
