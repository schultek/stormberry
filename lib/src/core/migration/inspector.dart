import '../../../stormberry.dart';

Future<DatabaseSchema> inspectDatabaseSchema(Database db) async {
  //ignore: prefer_const_constructors
  var schema = DatabaseSchema({});

  var tables = await db.execute(
      "SELECT * FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE'");
  for (var row in tables) {
    var tableMap = row.toColumnMap();
    var tableName = tableMap['table_name'] as String;

    var tableScheme =
        TableSchema(tableName, columns: {}, constraints: [], indexes: []);
    schema.tables[tableName] = tableScheme;

    var columns = await db.execute(
        "SELECT * FROM information_schema.columns WHERE table_name = '$tableName'");
    for (var row in columns) {
      var columnMap = row.toColumnMap();
      var columnName = columnMap['column_name'] as String;
      var columnType = columnMap['udt_name'] as String;
      var columnIsNullable = columnMap['is_nullable'];
      var columnDefault = columnMap['column_default'] as String?;
      var columnIsAutoIncrement = columnDefault?.startsWith('nextval') ?? false;

      if (columnIsAutoIncrement &&
          (columnType == 'int4' || columnType == 'int8')) {
        columnType = 'serial';
      }

      if (columnType == 'bool') {
        columnType = 'boolean';
      }

      tableScheme.columns[columnName] = ColumnSchema(
        columnName,
        type: columnType,
        isNullable: columnIsNullable == 'YES',
        isAutoIncrement: columnIsAutoIncrement,
      );
    }
  }

  var constraints = await db.execute("""
      SELECT tc.constraint_name, tc.constraint_type, 
        (array_agg(kcu.table_name))[1] as src_table,
        array_to_json(array_agg(DISTINCT kcu.column_name)) as src_columns,
        (array_agg(ccu.table_name))[1] as target_table,
        array_to_json(array_agg(DISTINCT ccu.column_name)) as target_columns,
        (array_agg(rf.update_rule))[1] as update_rule,
        (array_agg(rf.delete_rule))[1] as delete_rule
      FROM information_schema.table_constraints AS tc 
      JOIN information_schema.key_column_usage AS kcu 
        ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
      LEFT JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name AND ccu.table_schema = tc.table_schema
      LEFT JOIN information_schema.referential_constraints rf 
        ON ccu.constraint_name = rf.constraint_name
      WHERE tc.constraint_schema = 'public'
      GROUP BY tc.constraint_name, tc.constraint_type
    """);
  for (var row in constraints) {
    var constraintMap = row.toColumnMap();

    TableConstraint? constraint;
    var constraintType = constraintMap['constraint_type'];
    var srcColumns = (constraintMap['src_columns'] as List)..sort();

    var name = constraintMap['constraint_name'] as String?;
    if (constraintType == 'PRIMARY KEY') {
      constraint = PrimaryKeyConstraint(name, srcColumns.join('", "'));
    } else if (constraintType == 'UNIQUE') {
      constraint = UniqueConstraint(name, srcColumns.join('", "'));
    } else if (constraintType == 'FOREIGN KEY') {
      var targetColumns = constraintMap['target_columns'] as List;
      constraint = ForeignKeyConstraint(
        name,
        srcColumns[0] as String,
        constraintMap['target_table'] as String,
        targetColumns[0] as String,
        constraintMap['delete_rule'] == 'CASCADE'
            ? ForeignKeyAction.cascade
            : ForeignKeyAction.setNull,
        constraintMap['update_rule'] == 'CASCADE'
            ? ForeignKeyAction.cascade
            : ForeignKeyAction.setNull,
      );
    }
    if (constraint != null) {
      var tableName = constraintMap['src_table'];
      schema.tables[tableName]?.constraints.add(constraint);
    }
  }

  var indexes = await db.execute(r"""
      SELECT * FROM pg_catalog.pg_indexes WHERE schemaname = 'public' AND indexname LIKE '\_\_%'
    """);
  for (var row in indexes) {
    var indexMap = row.toColumnMap();
    var indexName = (indexMap['indexname'] as String).substring(2);
    var tableName = indexMap['tablename'];
    var defRegex = RegExp(
        r'^CREATE( UNIQUE)? INDEX \w+ ON public.\w+ USING (\w+) \((\w+)\)(?: WHERE (.+))?$');
    var defMatch = defRegex.firstMatch(indexMap['indexdef'] as String);
    if (defMatch == null || defMatch.groupCount != 4) continue;
    var unique = defMatch.group(1) != null;
    var algo = defMatch.group(2)!.toUpperCase();
    var columns = defMatch.group(3)!.split(','); // TODO trim quotes (")
    var condition = defMatch.group(4);
    if (condition != null && RegExp(r'^\(.*\)$').hasMatch(condition)) {
      condition = condition.substring(1, condition.length - 1);
    }
    var algorithm = IndexAlgorithm.values
        .firstWhere((a) => a.toString().split('.')[1] == algo);
    schema.tables[tableName]?.indexes.add(TableIndex(
      columns: columns,
      name: indexName,
      algorithm: algorithm,
      unique: unique,
      condition: condition,
    ));
  }

  return schema;
}

extension SkipEnd<T> on Iterable<T> {
  Iterable<T> skipEnd(int n) {
    return take(length - n);
  }
}
