import 'package:collection/collection.dart';

import '../../core/case_style.dart';
import '../schema.dart';
import 'table_element.dart';

class JoinTableElement {
  late final TableElement first;
  late final TableElement second;
  final BuilderState state;

  late final String tableName;

  JoinTableElement(TableElement a, TableElement b, this.state) {
    var sorted = [a, b]..sortBy((e) => e.tableName);
    first = sorted.first;
    second = sorted.last;

    tableName = state.options.tableCaseStyle.transform('${first.tableName}-${second.tableName}');
  }

  bool get isSelf => first == second;

  String get firstName => first.getForeignKeyName()! + (isSelf ? '_a' : '');
  String get secondName => second.getForeignKeyName()! + (isSelf ? '_b' : '');
}
