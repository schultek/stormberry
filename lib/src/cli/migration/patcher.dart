import '../../../stormberry.dart';

import 'differentiator.dart';
import 'schema.dart';

Future<void> patchSchema(Database db, DatabaseSchemaDiff diff) async {
  for (var table in diff.tables.added) {
    await db.query("""
        CREATE TABLE IF NOT EXISTS "${table.name}" ( 
          ${table.columns.values.map((c) => '"${c.name}" ${c.type} ${c.isNullable ? 'NULL' : 'NOT NULL'}').join(",")}
        )
      """);
  }

  for (var table in diff.tables.modified) {
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
        ...table.columns.modified.expand((c) sync* {
          if (c.prev.type != 'serial' && c.newly.type == 'serial') {
            yield 'ALTER COLUMN "${c.prev.name}" SET DATA TYPE int8 USING ${c.newly.name}::int8';
            yield "ALTER COLUMN \"${c.prev.name}\" SET DEFAULT nextval('${table.name}_${c.newly.name}_seq')";
          } else {
            var update = c.prev.type != c.newly.type
                ? 'SET DATA TYPE ${c.newly.type} USING ${c.newly.name}::${c.newly.type}'
                : '${c.newly.isNullable ? 'DROP' : 'SET'} NOT NULL';
            yield 'ALTER COLUMN "${c.prev.name}" $update';
          }
        }),
      ];

      for (var c in table.columns.modified.where((c) => c.prev.type != 'serial' && c.newly.type == 'serial')) {
        await db.query('''
          CREATE SEQUENCE IF NOT EXISTS ${table.name}_${c.newly.name}_seq OWNED BY "public"."${table.name}"."${c.newly.name}";
        ''');
      }

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

  for (var table in diff.tables.modified) {
    for (var index in table.indexes.added) {
      await db.query('CREATE ${index.statement(table.name)}');
    }
  }

  for (var table in diff.tables.added) {
    for (var index in table.indexes) {
      await db.query('CREATE ${index.statement(table.name)}');
    }
  }

  removeUnused(db, diff);
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
    await db.query('DROP TABLE "${table.name}" CASCADE');
  }
}