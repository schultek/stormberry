import '../../core/case_style.dart';
import '../schema.dart';
import 'table_element.dart';

class JoinTableElement {
  late final TableElement first;
  late final TableElement second;
  final BuilderState state;

  late final String tableName;

  JoinTableElement(TableElement first, TableElement second, this.state) {
    var sorted = [first, second]..sort((a, b) => a.tableName.compareTo(b.tableName));
    this.first = sorted.first;
    this.second = sorted.last;

    tableName = state.options.tableCaseStyle.transform('${first.tableName}-${second.tableName}');
  }
}
