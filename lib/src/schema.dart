class DatabaseSchema {
  final Map<String, TableSchema> tables;
  const DatabaseSchema([this.tables = const {}]);

  DatabaseSchema copy() => DatabaseSchema(tables.map(
        (key, value) => MapEntry(key, value.copy()),
      ));
}

class TableSchema {
  final String name;
  final Map<String, ColumnSchema> columns;
  final List<TableConstraint> constraints;
  final List<TableTrigger> triggers;
  final List<TableIndex> indexes;

  const TableSchema(this.name,
      {this.columns = const {},
      this.constraints = const [],
      this.triggers = const [],
      this.indexes = const []});

  TableSchema copy() => TableSchema(name,
      columns: {...columns},
      constraints: [...constraints],
      triggers: [...triggers],
      indexes: [...indexes]);
}

class ColumnSchema {
  final String name;
  final String type;
  final bool isNullable;

  const ColumnSchema(this.name, {required this.type, this.isNullable = false});
}

abstract class TableConstraint {
  final String? name;
  const TableConstraint(this.name);
}

class PrimaryKeyConstraint extends TableConstraint {
  final String column;
  const PrimaryKeyConstraint(String? name, this.column) : super(name);

  @override
  String toString() {
    return '''
      PRIMARY KEY ( "$column" )
    ''';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrimaryKeyConstraint &&
          runtimeType == other.runtimeType &&
          column == other.column;

  @override
  int get hashCode => name.hashCode;
}

enum ForeignKeyAction { setNull, cascade }

class ForeignKeyConstraint extends TableConstraint {
  final String srcColumn, table, column;
  final ForeignKeyAction onDelete, onUpdate;

  const ForeignKeyConstraint(String? name, this.srcColumn, this.table,
      this.column, this.onDelete, this.onUpdate)
      : super(name);

  @override
  String toString() {
    return '''
      FOREIGN KEY ( "$srcColumn" ) 
      REFERENCES $table ( "$column" ) 
      ON DELETE ${_ac(onDelete)} ON UPDATE ${_ac(onUpdate)}
    ''';
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
      name.hashCode ^
      table.hashCode ^
      column.hashCode ^
      onDelete.hashCode ^
      onUpdate.hashCode;
}

class UniqueConstraint extends TableConstraint {
  final String column;
  const UniqueConstraint(String? name, this.column) : super(name);

  @override
  String toString() {
    return '''
      UNIQUE ( "$column" )
    ''';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UniqueConstraint &&
          runtimeType == other.runtimeType &&
          column == other.column;

  @override
  int get hashCode => name.hashCode;
}

class TableTrigger {
  final String name;
  final String column;
  final String function;
  final List<String> args;

  const TableTrigger(this.name, this.column, this.function, this.args);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableTrigger &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          column == other.column &&
          function == other.function &&
          args.join(',') == other.args.join(',');

  @override
  int get hashCode =>
      name.hashCode ^ column.hashCode ^ function.hashCode ^ args.hashCode;
}

class TableIndex {
  final List<String> columns;
  final String name;
  final bool unique;
  final IndexAlgorithm algorithm;
  final String? condition;

  const TableIndex({
    this.columns = const [],
    required this.name,
    this.unique = false,
    this.algorithm = IndexAlgorithm.BTREE,
    this.condition,
  });

  String get joinedColumns => columns.map((c) => '"$c"').join(', ');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableIndex &&
          runtimeType == other.runtimeType &&
          joinedColumns == other.joinedColumns &&
          name == other.name &&
          unique == other.unique &&
          algorithm == other.algorithm &&
          condition == other.condition;

  @override
  int get hashCode =>
      joinedColumns.hashCode ^
      name.hashCode ^
      unique.hashCode ^
      algorithm.hashCode ^
      condition.hashCode;

  String statement(String tableName) {
    return """
      ${unique ? 'UNIQUE' : ''} INDEX "__$name" 
      ON "$tableName" USING ${algorithm.toString().split(".")[1]} ( $joinedColumns ) 
      ${condition != null ? 'WHERE $condition' : ''}
    """;
  }
}

// ignore: constant_identifier_names
enum IndexAlgorithm { BTREE, GIST, HASH, GIN, BRIN, SPGIST }

class Join {
  String table, statement;
  Join(this.table, this.statement);
}
