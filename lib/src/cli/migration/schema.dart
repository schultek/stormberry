// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';

import 'package:glob/glob.dart';
import 'package:file/local.dart';

import '../../../stormberry.dart';

class DatabaseSchema {
  final Map<String, TableSchema> tables;

  const DatabaseSchema(this.tables);

  DatabaseSchema copy() => DatabaseSchema(
        {for (var t in tables.entries) t.key: t.value.copy()},
      );

  factory DatabaseSchema.fromMap(Map<String, dynamic> map) {
    var tables = <String, TableSchema>{};
    for (var key in map.keys) {
      var table = map[key];
      tables[key] = TableSchema(
        key,
        columns: (table['columns'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, ColumnSchema.fromMap(k, v as Map<String, dynamic>))),
        constraints: (table['constraints'] as List?)
                ?.map((c) => TableConstraint.fromMap(c as Map<String, dynamic>))
                .toList() ??
            [],
        indexes: (table['indexes'] as List?)
                ?.map((i) => TableIndexParser.fromMap(i as Map<String, dynamic>))
                .toList() ??
            [],
      );
    }
    return DatabaseSchema(tables);
  }

  factory DatabaseSchema.empty() {
    return DatabaseSchema({});
  }

  static Future<DatabaseSchema> load(String glob) async {
    var runners = Glob(glob);
    var files = runners.listFileSystem(LocalFileSystem()).handleError((_) {});

    var schema = DatabaseSchema.empty();

    await for (var file in files) {
      var schemaMap = jsonDecode(await File.fromUri(file.absolute.uri).readAsString());
      var targetSchema = DatabaseSchema.fromMap(schemaMap as Map<String, dynamic>);

      schema = schema.mergeWith(targetSchema);
    }

    return schema;
  }

  DatabaseSchema mergeWith(DatabaseSchema targetSchema) {
    var tables = {...this.tables};

    for (var key in targetSchema.tables.keys) {
      if (tables.containsKey(key)) {
        print('Database contains duplicate table $key. Make sure each table has a unique name.');
        exit(1);
      }
      tables[key] = targetSchema.tables[key]!;
    }

    return DatabaseSchema(tables);
  }
}

class TableSchema {
  final String name;
  final Map<String, ColumnSchema> columns;
  final List<TableConstraint> constraints;
  final List<TableIndex> indexes;

  const TableSchema(
    this.name, {
    this.columns = const {},
    this.constraints = const [],
    this.indexes = const [],
  });

  TableSchema copy() => TableSchema(
        name,
        columns: {...columns},
        constraints: [...constraints],
        indexes: [...indexes],
      );
}

class ColumnSchema {
  final String name;
  final String type;
  final bool isNullable;
  final bool isAutoIncrement;

  const ColumnSchema(this.name,
      {required this.type, this.isNullable = false, bool? isAutoIncrement})
      : isAutoIncrement = isAutoIncrement ?? (type == 'serial');

  factory ColumnSchema.fromMap(String name, Map<String, dynamic> map) {
    return ColumnSchema(
      name,
      type: map['type']! as String,
      isNullable: (map['isNullable'] as bool?) ?? false,
    );
  }
}

abstract class TableConstraint {
  final String? name;
  const TableConstraint(this.name);

  factory TableConstraint.fromMap(Map<String, dynamic> map) {
    switch (map['type']) {
      case 'primary_key':
        return PrimaryKeyConstraint(null, map['column']! as String);
      case 'foreign_key':
        return ForeignKeyConstraint(
          null,
          map['column']! as String,
          (map['target']! as String).split('.')[0],
          (map['target']! as String).split('.')[1],
          map['on_delete'] == 'cascade' ? ForeignKeyAction.cascade : ForeignKeyAction.setNull,
          map['on_update'] == 'cascade' ? ForeignKeyAction.cascade : ForeignKeyAction.setNull,
        );
      case 'unique':
        return UniqueConstraint(null, map['column']! as String);
      default:
        throw Exception("No table constraint for type ${map["type"]}");
    }
  }
}

class PrimaryKeyConstraint extends TableConstraint {
  final String column;
  const PrimaryKeyConstraint(String? name, this.column) : super(name);

  @override
  String toString() {
    return 'PRIMARY KEY ( "$column" )';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrimaryKeyConstraint && runtimeType == other.runtimeType && column == other.column;

  @override
  int get hashCode => name.hashCode;
}

enum ForeignKeyAction { setNull, cascade }

class ForeignKeyConstraint extends TableConstraint {
  final String srcColumn;
  final String table;
  final String column;
  final ForeignKeyAction onDelete;
  final ForeignKeyAction onUpdate;

  const ForeignKeyConstraint(
      String? name, this.srcColumn, this.table, this.column, this.onDelete, this.onUpdate)
      : super(name);

  @override
  String toString() {
    return 'FOREIGN KEY ( "$srcColumn" ) '
        'REFERENCES "$table" ( "$column" ) '
        'ON DELETE ${_ac(onDelete)} ON UPDATE ${_ac(onUpdate)}';
  }

  String _ac(ForeignKeyAction action) {
    if (action == ForeignKeyAction.setNull) {
      return 'SET NULL';
    } else {
      return 'CASCADE';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForeignKeyConstraint &&
          runtimeType == other.runtimeType &&
          srcColumn == other.srcColumn &&
          table == other.table &&
          column == other.column &&
          onDelete == other.onDelete &&
          onUpdate == other.onUpdate;

  @override
  int get hashCode =>
      name.hashCode ^ table.hashCode ^ column.hashCode ^ onDelete.hashCode ^ onUpdate.hashCode;
}

class UniqueConstraint extends TableConstraint {
  final String column;
  const UniqueConstraint(String? name, this.column) : super(name);

  @override
  String toString() {
    return 'UNIQUE ( "$column" )';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UniqueConstraint && runtimeType == other.runtimeType && column == other.column;

  @override
  int get hashCode => name.hashCode;
}

extension TableIndexParser on TableIndex {
  static TableIndex fromMap(Map<String, dynamic> map) {
    return TableIndex(
      name: map['name']! as String,
      columns: (map['columns'] as List?)?.cast<String>() ?? [],
      unique: (map['unique'] as bool?) ?? false,
      algorithm: IndexAlgorithm.values[map['algorithm'] as int? ?? 0],
      condition: map['condition'] as String?,
    );
  }

  String statement(String tableName) {
    return '${unique ? 'UNIQUE' : ''} INDEX "__$name" '
        'ON "$tableName" USING ${algorithm.toString().split(".")[1]} ( $joinedColumns ) '
        '${condition != null ? 'WHERE $condition' : ''}';
  }
}
