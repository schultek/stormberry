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

    tableName = state.options.tableCaseStyle.transform('${first.tableName}-${second.tableName}');
  }

  Map<String, dynamic> generateJsonSchema() {
    return {
      'columns': {
        first.getForeignKeyName(): {'type': first.primaryKeyColumn!.sqlType},
        second.getForeignKeyName(): {'type': second.primaryKeyColumn!.sqlType},
      },
      'constraints': [
        {
          'type': 'primary_key',
          'column': '${first.getForeignKeyName()}", "${second.getForeignKeyName()}',
        },
        {
          'type': 'foreign_key',
          'column': first.getForeignKeyName(),
          'target': '${first.tableName}.${first.primaryKeyColumn!.columnName}',
          'on_delete': 'cascade',
          'on_update': 'cascade',
        },
        {
          'type': 'foreign_key',
          'column': second.getForeignKeyName(),
          'target': '${second.tableName}.${second.primaryKeyColumn!.columnName}',
          'on_delete': 'cascade',
          'on_update': 'cascade',
        },
      ],
    };
  }
}
