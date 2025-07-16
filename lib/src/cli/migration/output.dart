import 'dart:io';

import 'package:path/path.dart' as path;
import 'differentiator.dart';
import 'schema.dart';

var fileIndex = 0;

Future<void> writeFile(Directory dir, String name, String content) {
  var file = File(path.join(dir.path, '${fileIndex++}_$name.sql'));
  print('Writing file ${file.path}');
  return file.writeAsString(content);
}

Future<void> outputSchema(Directory dir, DatabaseSchemaDiff diff) async {
  if (diff.tables.added.isNotEmpty) {
    var createTables = '';

    for (var table in diff.tables.added) {
      if (createTables.isNotEmpty) {
        createTables += '\n\n';
      }
      createTables += ''
          'CREATE TABLE IF NOT EXISTS "${table.name}" (\n'
          '${table.columns.values.map((c) => '  "${c.name}" ${c.type} ${c.isNullable ? 'NULL' : 'NOT NULL'}').join(",\n")}\n'
          ');';
    }

    await writeFile(dir, 'create_tables', createTables);
  }

  var alterTables = '';
  void appendStatement(String statement) {
    if (alterTables.isNotEmpty) {
      alterTables += '\n\n';
    }
    alterTables += statement;
  }

  for (var table in diff.tables.modified) {
    for (var index in table.indexes.removed) {
      appendStatement('DROP INDEX "__${index.name}";');
    }

    if (table.constraints.removed.isNotEmpty) {
      appendStatement(''
          'ALTER TABLE "${table.name}"\n'
          '  ${table.constraints.removed.map((c) => 'DROP CONSTRAINT IF EXISTS "${c.name}" CASCADE').join(",\n  ")};');
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

      for (var c in table.columns.modified
          .where((c) => c.prev.type != 'serial' && c.newly.type == 'serial')) {
        appendStatement(
            'CREATE SEQUENCE IF NOT EXISTS ${table.name}_${c.newly.name}_seq '
            'OWNED BY "public"."${table.name}"."${c.newly.name}";');
      }

      appendStatement('ALTER TABLE "${table.name}"\n'
          '  ${updatedColumns.join(",\n  ")};');
    }
  }

  for (var table in diff.tables.modified) {
    var uniqueConstraints = table.constraints.added
        .where((c) => c is PrimaryKeyConstraint || c is UniqueConstraint)
        .toList();
    if (uniqueConstraints.isNotEmpty) {
      appendStatement('ALTER TABLE "${table.name}"\n'
          '  ${uniqueConstraints.map((c) => 'ADD ${c.toString()}').join(",\n  ")};');
    }
  }

  for (var table in diff.tables.added) {
    var uniqueConstraints = table.constraints
        .where((c) => c is PrimaryKeyConstraint || c is UniqueConstraint)
        .toList();
    if (uniqueConstraints.isNotEmpty) {
      appendStatement('ALTER TABLE "${table.name}"\n'
          '  ${uniqueConstraints.map((c) => 'ADD ${c.toString()}').join(",\n  ")};');
    }
  }

  for (var table in diff.tables.modified) {
    var foreignKeyConstraints =
        table.constraints.added.whereType<ForeignKeyConstraint>().toList();
    if (foreignKeyConstraints.isNotEmpty) {
      appendStatement('ALTER TABLE "${table.name}"\n'
          '  ${foreignKeyConstraints.map((c) => 'ADD ${c.toString()}').join(",\n  ")};');
    }
  }

  for (var table in diff.tables.added) {
    var foreignKeyConstraints =
        table.constraints.whereType<ForeignKeyConstraint>().toList();
    if (foreignKeyConstraints.isNotEmpty) {
      appendStatement('ALTER TABLE "${table.name}"\n'
          '  ${foreignKeyConstraints.map((c) => 'ADD ${c.toString()}').join(",\n  ")};');
    }
  }

  for (var table in diff.tables.modified) {
    for (var index in table.indexes.added) {
      appendStatement('CREATE ${index.statement(table.name)};');
    }
  }

  for (var table in diff.tables.added) {
    for (var index in table.indexes) {
      appendStatement('CREATE ${index.statement(table.name)};');
    }
  }

  if (alterTables.isNotEmpty) {
    await writeFile(dir, 'alter_tables', alterTables);
  }
}

Future<void> removeUnused(Directory dir, DatabaseSchemaDiff diff) async {
  if (diff.tables.removed.isNotEmpty) {
    var dropTables = '';

    for (var table in diff.tables.removed) {
      if (dropTables.isNotEmpty) {
        dropTables += '\n\n';
      }
      dropTables += 'DROP TABLE "${table.name}" CASCADE;';
    }

    await writeFile(dir, 'drop_tables', dropTables);
  }
}
