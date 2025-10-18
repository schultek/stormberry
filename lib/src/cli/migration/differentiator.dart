import 'package:collection/collection.dart';
import '../../../stormberry.dart';

import 'inspector.dart';
import 'schema.dart';

extension SchemaDiff on DatabaseSchema {
  /// Computes the difference between the live database schema from [db] and this schema.
  ///
  /// The returned [DatabaseSchemaDiff] contains all changes needed to migrate the database
  /// schema to match this schema.
  /// - Call [DatabaseSchemaDiff.printToConsole] to print the computed changes to the console.
  /// - Call [DatabaseSchemaDiff.patch] to apply the changes to the database.
  Future<DatabaseSchemaDiff> computeDiff(Session db) async {
    var existingSchema = await inspectDatabaseSchema(db);
    var newSchema = copy();

    var diff = DatabaseSchemaDiff(existingSchema, this);

    for (var extTable in existingSchema.tables.values) {
      if (newSchema.tables.containsKey(extTable.name)) {
        var newTable = newSchema.tables.remove(extTable.name)!;
        var tableDiff = TableSchemaDiff(newTable.name);

        for (var extColumn in extTable.columns.values) {
          var newColumn =
              newTable.columns.values.where((c) => c.name == extColumn.name).firstOrNull;
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

        if (tableDiff.hasChanges) {
          diff.tables.modified.add(tableDiff);
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
}

class DatabaseSchemaDiff {
  Diff<TableSchema, TableSchemaDiff> tables = Diff();

  DatabaseSchema existingSchema;
  DatabaseSchema newSchema;

  DatabaseSchemaDiff(this.existingSchema, this.newSchema);

  bool get hasChanges => tables.hasChanges((t) => t.hasChanges);

  /// Prints the computed schema differences to the console.
  ///
  /// The output format indicates additions with "++", removals with "--", and modifications
  /// with "-" for the previous state and "+" for the new state.
  void printToConsole() {
    for (var table in tables.added) {
      print('++ TABLE ${table.name}');
    }

    for (var table in tables.modified) {
      for (var column in table.columns.added) {
        print('++ COLUMN ${table.name}.${column.name}');
      }

      for (var column in table.columns.modified) {
        var prev = column.prev;
        var newly = column.newly;
        print(
            "-  COLUMN ${table.name}.${prev.name} ${prev.type} ${prev.isNullable ? 'NULL' : 'NOT NULL'}");
        print(
            "+  COLUMN ${table.name}.${newly.name} ${newly.type} ${newly.isNullable ? 'NULL' : 'NOT NULL'}");
      }

      for (var column in table.columns.removed) {
        print('-- COLUMN ${table.name}.${column.name}');
      }

      for (var constr in table.constraints.added) {
        print(
            "++ CONSTRAINT ON ${table.name} ${constr.toString().replaceAll(RegExp("[\n\\s]+"), " ")}");
      }

      for (var constr in table.constraints.removed) {
        print(
            "-- CONSTRAINT ON ${table.name} ${constr.toString().replaceAll(RegExp("[\n\\s]+"), " ")}");
      }

      for (var index in table.indexes.added) {
        print("++ ${index.statement(table.name).replaceAll(RegExp("[\n\\s]+"), " ")}");
      }

      for (var index in table.indexes.removed) {
        print("-- ${index.statement(table.name).replaceAll(RegExp("[\n\\s]+"), " ")}");
      }
    }

    for (var table in tables.removed) {
      print('-- TABLE ${table.name}');
    }
  }
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
    return added.isNotEmpty ||
        removed.isNotEmpty ||
        (fn != null ? modified.any(fn) : modified.isNotEmpty);
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
