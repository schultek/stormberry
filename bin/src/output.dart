import 'dart:io';

import 'package:stormberry/stormberry.dart';
import 'package:path/path.dart' as path;
import 'differentiator.dart';
import 'schema.dart';

Future<void> writeFile(Directory dir, String name, String content) {
  var file = File(path.join(dir.path, '$name.sql'));
  print('Writing file ${file.path}');
  return file.writeAsString(content);
}

Future<void> outputSchema(Directory dir, DatabaseSchemaDiff diff) async {

  for (var table in diff.tables.added) {
    await writeFile(dir, 'create_${table.name}', """
        CREATE TABLE IF NOT EXISTS "${table.name}" ( 
          ${table.columns.values.map((c) => '"${c.name}" ${c.type} ${c.isNullable ? 'NULL' : 'NOT NULL'}').join(",")}
        )
      """);
  }

  await patchViews(dir, diff);
}

Future<void> patchViews(Directory dir, DatabaseSchemaDiff diff) async {
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

    await writeFile(dir, 'drop_${node.view.name}', 'DROP VIEW ${node.view.name}');

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

  await removeUnused(dir, diff);

  var toAddNodes = ViewSchema.buildGraph(toAdd);
  var toAddGraph = toAddNodes.where((n) => n.children.isEmpty).toSet();

  while (toAddGraph.isNotEmpty) {
    var node = toAddGraph.first;
    toAddGraph.remove(node);
    toAddNodes.remove(node);

    await writeFile(dir, 'create_${node.view.name}', 'CREATE VIEW ${node.view.name} AS \n${node.view.definition}');

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

Future<void> removeUnused(Directory dir, DatabaseSchemaDiff diff) async {
  for (var table in diff.tables.removed) {
    await writeFile(dir, 'drop_${table.name}', 'DROP TABLE "${table.name}" CASCADE');
  }
}
