import 'package:analyzer/dart/constant/value.dart';

import 'table_builder.dart';

class IndexBuilder {
  TableBuilder table;
  DartObject annotation;

  IndexBuilder(this.table, this.annotation);

  Map<String, dynamic> toMap() {
    return {
      'name': annotation.getField('name')?.toStringValue(),
      'columns': annotation.getField('columns')?.toListValue()?.map((o) => o.toStringValue()).toList(),
      'unique': annotation.getField('unique')?.toBoolValue(),
      'algorithm': annotation.getField('algorithm')?.getField('index')?.toIntValue(),
      'condition': annotation.getField('condition')?.toStringValue(),
    };
  }
}
