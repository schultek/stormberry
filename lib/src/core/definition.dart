import 'column.dart';
import 'table.dart';

abstract class TableDefinition<T extends Table> {
  T get table;
  Map<String, Column> get columns;
  Set<ViewDefinition<T, View<T, Entity>>> get views;
}

abstract class ViewDefinition<T extends Table, V extends View<T, Entity>> {
  V get view;
  Map<String, Column> get columns;
}

abstract class DatabaseDefinition {
  Map<String, TableDefinition> get tables;
}

class DefinitionScope {
  DefinitionScope._();

  static DatabaseDefinition? _def;

  static void push(DatabaseDefinition def) {
    _def = def;
  }

  static DatabaseDefinition get() {
    return _def!;
  }
}
