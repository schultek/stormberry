import 'package:analyzer/dart/constant/value.dart';

import 'table_element.dart';

class IndexElement {
  final TableElement table;
  final DartObject annotation;

  IndexElement(this.table, this.annotation);

  Map<String, dynamic> toMap() {
    return {
      'name': annotation.getField('name')?.toStringValue(),
      'columns': annotation
          .getField('columns')
          ?.toListValue()
          ?.map((o) => o.toStringValue())
          .toList(),
      'unique': annotation.getField('unique')?.toBoolValue(),
      'algorithm':
          annotation.getField('algorithm')?.getField('index')?.toIntValue(),
      'condition': annotation.getField('condition')?.toStringValue(),
    };
  }
}
