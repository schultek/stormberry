import 'package:collection/collection.dart';
import '../../../stormberry.dart';

import 'inspector.dart';
import 'schema.dart';

Future<DatabaseSchemaDiff> getSchemaDiff(Database db, DatabaseSchema dbSchema) async {
  var existingSchema = await inspectDatabaseSchema(db);
  var newSchema = dbSchema.copy();

  var diff = DatabaseSchemaDiff(existingSchema, dbSchema);

  for (var extTable in existingSchema.tables.values) {
    if (newSchema.tables.containsKey(extTable.name)) {
      var newTable = newSchema.tables.remove(extTable.name)!;
      var tableDiff = TableSchemaDiff(newTable.name);
      diff.tables.modified.add(tableDiff);

      for (var extColumn in extTable.columns.values) {
        var newColumn = newTable.columns.values.where((c) => c.name == extColumn.name).firstOrNull;
        if (newColumn != null) {
          newTable.columns.removeWhere((_, c) => c == newColumn);
          if (newColumn.type != extColumn.type || newColumn.isNullable != extColumn.isNullable) {
            tableDiff.columns.modified.add(Change(extColumn, newColumn));
          }
        } else {
          tableDiff.columns.removed.add(extColumn);
        }
      }

      for (var newColumn in newTable.columns.values) {
        tableDiff.columns.added.add(newColumn);
      }

      for (var extConstraint in extTable.constraints) {
        var newConstraint = newTable.constraints.where((c) => c == extConstraint).firstOrNull;

        if (newConstraint != null) {
          newTable.constraints.remove(newConstraint);
        } else {
          tableDiff.constraints.removed.add(extConstraint);
        }
      }

      for (var newConstraint in newTable.constraints) {
        tableDiff.constraints.added.add(newConstraint);
      }

      for (var extIndex in extTable.indexes) {
        var newIndex = newTable.indexes.where((t) => t == extIndex).firstOrNull;

        if (newIndex != null) {
          newTable.indexes.remove(newIndex);
        } else {
          tableDiff.indexes.removed.add(extIndex);
        }
      }

      for (var newIndex in newTable.indexes) {
        tableDiff.indexes.added.add(newIndex);
      }
    } else {
      diff.tables.removed.add(extTable);
    }
  }

  for (var newTable in newSchema.tables.values) {
    diff.tables.added.add(newTable);
  }

  return diff;
}

void printDiff(DatabaseSchemaDiff diff) {
  for (var table in diff.tables.added) {
    print('++ TABLE ${table.name}');
  }

  for (var table in diff.tables.modified) {
    for (var column in table.columns.added) {
      print('++ COLUMN ${table.name}.${column.name}');
    }

    for (var column in table.columns.modified) {
      var prev = column.prev;
      var newly = column.newly;
      print("-  COLUMN ${table.name}.${prev.name} ${prev.type} ${prev.isNullable ? 'NULL' : 'NOT NULL'}");
      print("+  COLUMN ${table.name}.${newly.name} ${newly.type} ${newly.isNullable ? 'NULL' : 'NOT NULL'}");
    }

    for (var column in table.columns.removed) {
      print('-- COLUMN ${table.name}.${column.name}');
    }

    for (var constr in table.constraints.added) {
      print("++ CONSTRAINT ON ${table.name} ${constr.toString().replaceAll(RegExp("[\n\\s]+"), " ")}");
    }

    for (var constr in table.constraints.removed) {
      print("-- CONSTRAINT ON ${table.name} ${constr.toString().replaceAll(RegExp("[\n\\s]+"), " ")}");
    }

    for (var index in table.indexes.added) {
      print("++ ${index.statement(table.name).replaceAll(RegExp("[\n\\s]+"), " ")}");
    }

    for (var index in table.indexes.removed) {
      print("-- ${index.statement(table.name).replaceAll(RegExp("[\n\\s]+"), " ")}");
    }
  }

  for (var table in diff.tables.removed) {
    print('-- TABLE ${table.name}');
  }
}

class DatabaseSchemaDiff {
  Diff<TableSchema, TableSchemaDiff> tables = Diff();

  DatabaseSchema existingSchema;
  DatabaseSchema newSchema;

  DatabaseSchemaDiff(this.existingSchema, this.newSchema);

  bool get hasChanges => tables.hasChanges((t) => t.hasChanges);
}

class TableSchemaDiff {
  String name;
  Diff<ColumnSchema, Change<ColumnSchema>> columns = Diff();
  Diff<TableConstraint, void> constraints = Diff();
  Diff<TableIndex, void> indexes = Diff();

  TableSchemaDiff(this.name);

  bool get hasChanges => columns.hasChanges() || constraints.hasChanges() || indexes.hasChanges();
}

class Diff<T, U> {
  List<T> added = [];
  List<U> modified = [];
  List<T> removed = [];

  bool hasChanges([bool Function(U modified)? fn]) {
    return added.isNotEmpty || removed.isNotEmpty || (fn != null ? modified.any(fn) : modified.isNotEmpty);
  }
}

class Change<T> {
  T prev;
  T newly;
  Change(this.prev, this.newly);
}

extension ChangeMap<T> on Iterable<Change<T>> {
  Iterable<T> get prev => map((c) => c.prev);
  Iterable<T> get newly => map((c) => c.newly);
}
