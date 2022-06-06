import 'package:stormberry/stormberry.dart';

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
        ...table.columns.modified.expand((c) sync* {
          if (c.prev.type != 'serial' && c.newly.type == 'serial') {
            yield 'ALTER COLUMN \"${c.prev.name}\" SET DATA TYPE int8 USING ${c.newly.name}::int8';
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

  await patchViews(db, diff);
}

Future<void> patchViews(Database db, DatabaseSchemaDiff diff) async {
  var toDrop = {...diff.views.removed, ...diff.views.modified.prev};
  var toAdd = {...diff.views.added, ...diff.views.modified.newly};

  String? nodePath(ViewNode node, [Set<ViewNode> visited = const {}]) {
    if (visited.contains(node)) return node.view.name;
    for (var child in node.children) {
      var s = nodePath(child, {...visited, node});
      if (s != null) {
        return '${node.view.name} -> $s';
      }
    }
    return null;
  }

  var currViewNodes = ViewSchema.buildGraph(diff.existingSchema.views.values.toSet());

  Iterable<ViewNode> getParents(ViewNode n) => [n, ...n.parents.expand(getParents)];
  var toDropNodes = currViewNodes.where((n) => toDrop.contains(n.view)).expand(getParents).toSet();
  var toDropGraph = toDropNodes.where((n) => n.parents.isEmpty).toSet();

  while (toDropGraph.isNotEmpty) {
    var node = toDropGraph.first;
    toDropGraph.remove(node);
    toDropNodes.remove(node);

    if (!toDrop.contains(node.view)) {
      toAdd.add(node.view);
    }

    await db.query('DROP VIEW ${node.view.name}');

    for (var child in node.children) {
      child.parents.remove(node);
      if (child.parents.isEmpty) {
        toDropGraph.add(child);
      }
    }
  }

  if (toDropNodes.isNotEmpty) {
    print('Error: Cyclic dependencies in dropped table views found: ${nodePath(toDropNodes.first)}');
    throw Exception();
  }

  await removeUnused(db, diff);

  var toAddNodes = ViewSchema.buildGraph(toAdd);
  var toAddGraph = toAddNodes.where((n) => n.children.isEmpty).toSet();

  while (toAddGraph.isNotEmpty) {
    var node = toAddGraph.first;
    toAddGraph.remove(node);
    toAddNodes.remove(node);

    await db.query('CREATE VIEW ${node.view.name} AS ${node.view.definition}');

    for (var parent in node.parents) {
      parent.children.remove(node);
      if (parent.children.isEmpty) {
        toAddGraph.add(parent);
      }
    }
  }

  if (toAddNodes.isNotEmpty) {
    print('Error: Cyclic dependencies in added table views found: ${nodePath(toAddNodes.first)}');
    throw Exception();
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
    await db.query('DROP TABLE "${table.name}" CASCADE');
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
