import '../core/case_style.dart';
import 'stormberry_builder.dart';
import 'table_builder.dart';

class JoinTableBuilder {
  late TableBuilder first;
  late TableBuilder second;
  BuilderState state;

  late String tableName;

  JoinTableBuilder(TableBuilder first, TableBuilder second, this.state) {
    var sorted = [first, second]..sort((a, b) => a.tableName.compareTo(b.tableName));
    this.first = sorted.first;
    this.second = sorted.last;

    tableName = state.schema.options.tableCaseStyle.transform('${first.tableName}-${second.tableName}');
  }
}
