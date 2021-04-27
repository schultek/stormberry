import '../database.dart';
import '../schema.dart';
import 'differentiator.dart';

Future<void> patchSchema(Database db, DatabaseSchemaDiff diff) async {
  for (var table in diff.tables.added) {
    await db.query("""
        CREATE TABLE IF NOT EXISTS "${table.name}" ( 
          ${table.columns.values.map((c) => '"${c.name}" ${c.type} ${c.isNullable ? 'NULL' : 'NOT NULL'}').join(",")}
        )
      """);
  }

  for (var table in diff.tables.modified) {
    for (var trigger in table.triggers.removed) {
      await db.query('''
          DROP TRIGGER "${trigger.name}" ON "${table.name}"
        ''');
    }

    for (var index in table.indexes.removed) {
      await db.query('DROP INDEX "__${index.name}"');
    }

    if (table.constraints.removed.isNotEmpty) {
      await db.query("""
          ALTER TABLE "${table.name}"
          ${table.constraints.removed.map((c) => 'DROP CONSTRAINT IF EXISTS "${c.name}" CASCADE').join(",\n")}
        """);
    }
  }

  for (var table in diff.tables.modified) {
    if (table.columns.added.isNotEmpty || table.columns.modified.isNotEmpty) {
      var updatedColumns = [
        ...table.columns.added.map((c) {
          return 'ADD COLUMN "${c.name}" ${c.type} ${c.isNullable ? 'NULL' : 'NOT NULL'}';
        }),
        ...table.columns.modified.map((c) {
          var update = c.prev.type != c.newly.type
              ? 'SET DATA TYPE ${c.newly.type} USING ${c.newly.name}::${c.newly.type}'
              : '${c.newly.isNullable ? 'DROP' : 'SET'} NOT NULL';
          return 'ALTER COLUMN "${c.prev.name}" $update';
        }),
      ];

      await db.query("""
          ALTER TABLE "${table.name}"
          ${updatedColumns.join(",\n")}
        """);
    }
  }

  for (var table in diff.tables.modified) {
    var uniqueConstraints =
        table.constraints.added.where((c) => c is PrimaryKeyConstraint || c is UniqueConstraint).toList();
    if (uniqueConstraints.isNotEmpty) {
      await db.query("""
          ALTER TABLE "${table.name}"
          ${uniqueConstraints.map((c) => 'ADD ${c.toString()}').join(",\n")}
        """);
    }
  }

  for (var table in diff.tables.added) {
    var uniqueConstraints = table.constraints.where((c) => c is PrimaryKeyConstraint || c is UniqueConstraint).toList();
    if (uniqueConstraints.isNotEmpty) {
      await db.query("""
          ALTER TABLE "${table.name}"
          ${uniqueConstraints.map((c) => 'ADD ${c.toString()}').join(",\n")}
        """);
    }
  }

  for (var table in diff.tables.modified) {
    var foreignKeyConstraints = table.constraints.added.whereType<ForeignKeyConstraint>().toList();
    if (foreignKeyConstraints.isNotEmpty) {
      await db.query("""
          ALTER TABLE "${table.name}"
          ${foreignKeyConstraints.map((c) => 'ADD ${c.toString()}').join(",\n")}
        """);
    }
  }

  for (var table in diff.tables.added) {
    var foreignKeyConstraints = table.constraints.whereType<ForeignKeyConstraint>().toList();
    if (foreignKeyConstraints.isNotEmpty) {
      await db.query("""
          ALTER TABLE "${table.name}"
          ${foreignKeyConstraints.map((c) => 'ADD ${c.toString()}').join(",\n")}
        """);
    }
  }

  await _createArrayKeysCheckFunction(db);

  for (var table in diff.tables.modified) {
    for (var trigger in table.triggers.added) {
      await db.query("""
          CREATE TRIGGER "${trigger.name}" 
          AFTER DELETE OR UPDATE OF "${trigger.column}" ON "${table.name}"
          FOR EACH ROW
          EXECUTE FUNCTION ${trigger.function}(${trigger.args.map((a) => "'$a'").join(", ")});
        """);
    }

    for (var index in table.indexes.added) {
      await db.query('CREATE ${index.statement(table.name)}');
    }
  }

  for (var table in diff.tables.added) {
    for (var trigger in table.triggers) {
      await db.query("""
          CREATE TRIGGER "${trigger.name}" 
          AFTER DELETE OR UPDATE OF "${trigger.column}" ON "${table.name}"
          FOR EACH ROW
          EXECUTE FUNCTION ${trigger.function}(${trigger.args.map((a) => "'$a'").join(", ")});
        """);
    }

    for (var index in table.indexes) {
      await db.query('CREATE ${index.statement(table.name)}');
    }
  }
}

Future<void> removeUnused(Database db, DatabaseSchemaDiff diff) async {
  for (var table in diff.tables.modified) {
    if (table.columns.removed.isNotEmpty) {
      await db.query("""
          ALTER TABLE "${table.name}"
          ${table.columns.removed.map((c) => 'DROP COLUMN "${c.name}"').join(",\n")}
        """);
    }
  }

  for (var table in diff.tables.removed) {
    for (var trigger in table.triggers) {
      await db.query('''
          DROP TRIGGER "${trigger.name}" ON "${table.name}"
        ''');
    }

    for (var index in table.indexes) {
      await db.query('DROP INDEX "__${index.name}"');
    }

    if (table.constraints.isNotEmpty) {
      await db.query("""
          ALTER TABLE "${table.name}"
          ${table.constraints.map((c) => 'DROP CONSTRAINT IF EXISTS "${c.name}" CASCADE').join(",\n")}
        """);
    }
  }

  for (var table in diff.tables.removed) {
    await db.query('''DROP TABLE "${table.name}" ''');
  }
}

Future<void> _createArrayKeysCheckFunction(Database db) async {
  var tempDebugPrint = db.debugPrint;
  db.debugPrint = false;
  await db.query("""
      CREATE OR REPLACE FUNCTION check_array_keys()
      RETURNS TRIGGER
      LANGUAGE plpgsql
      AS \$function\$
        DECLARE
          tableName TEXT;
          columnName TEXT;
          keyName TEXT;
        BEGIN
          tableName := TG_ARGV[0];
          columnName := TG_ARGV[1];
          keyName := TG_ARGV[2];

          IF NEW IS NULL THEN
            EXECUTE '
              UPDATE ' || quote_ident(tableName) || '
              SET ' || quote_ident(columnName) || ' = array_remove('
                || quote_ident(columnName) || ', \$1.' || quote_ident(keyName)
              || ')
              WHERE \$1.' || quote_ident(keyName) || ' = ANY (' || quote_ident(columnName) || ')
            ' USING OLD;
          ELSE
            EXECUTE '
              UPDATE ' || quote_ident(tableName) || '
              SET ' || quote_ident(columnName) || ' = array_replace('
                || quote_ident(columnName) || ', \$1.' || quote_ident(keyName) || ', \$2.' || quote_ident(keyName)
              || ')
              WHERE \$1.' || quote_ident(keyName) || ' = ANY (' || quote_ident(columnName) || ')
            ' USING OLD, NEW;
          END IF;

          RETURN NULL;
        END;
      \$function\$
    """);
  db.debugPrint = tempDebugPrint;
}
