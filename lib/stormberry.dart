import 'package:stormberry/src/core/table.dart';

import 'src/core/case_style.dart';
import 'src/core/column.dart';
import 'src/core/definition.dart';
import 'src/core/schema.dart';
import 'package:collection/collection.dart';

export 'package:postgres/postgres.dart';
export 'package:postgres/src/text_codec.dart';

export 'src/core/column.dart';
export 'src/core/database.dart';
export 'src/core/definition.dart';
export 'src/core/table.dart';
export 'src/core/transformer.dart';

void migrate(DatabaseDefinition definition) {
  var schema = definition.build();
}

extension on DatabaseDefinition {
  DatabaseSchema build() {
    Getter.scope = this;
    var schema = const DatabaseSchema({}, {});
    for (var table in tables.entries) {
      table.value.build(table.key,this, schema);
    }
    return schema;
  }
}

extension on TableDefinition {
  void build(String key, DatabaseDefinition definition, DatabaseSchema dbSchema) {
    for (var columnKey in columns.keys) {
      var column = columns[columnKey]!;

      if (column.get(Is<FieldColumn>())) {
        var name = column.get(GetName(columnKey));
        dbSchema.table(key).columns[name] = ColumnSchema(name, type: column.get(GetType()), isNullable: column.get(IsNullable()));
      } else if (column.get(IsForeignColumn())) {

        var name = column.get(GetName(columnKey));
        dbSchema.table(key).columns[name] = ColumnSchema(name, type: column.type, isNullable: column.isNullable);

      } else if (column.isReferenceColumn) {

        if (column.get(LinkColumn()) != null) {

          dbSchema.table(column.get(LinkTable())).columns[] = ColumnSchema(name, type: )

        }

      }
    }
  }
}

class IsForeignColumn implements Getter<bool> {

  @override
  bool get(Column c, bool Function() next) {
    if (c is ManyColumn) {
      return false;
    } else if (c is ReferenceColumn) {
      var linkTable = c.get(GetLinkTable());
      if (linkTable != null) {
        return linkTable.columns.values.any((c) => c.get(Is<PrimaryKeyColumn>()));
      } else {
        throw Exception('No link table found for type ${c.linkTableType}');
      }

    } else {
      return next();
    }
  }

  @override
  bool orElse() => false;

}

class GetLinkTable implements Getter<TableDefinition?> {

  @override
  TableDefinition<Table<Entity>>? get(Column c, TableDefinition? Function() next) {
    if (c is ReferenceColumn) {
      return Getter.scope.tables.values
          .where((table) => table.table.runtimeType == c.linkTableType)
          .firstOrNull;
    } else {
      return next();
    }
  }

  @override
  TableDefinition? orElse() => null;

}

class Is<T> implements Getter<bool> {
  @override
  bool get(Column c, bool Function() next) {
    return c is T || next();
  }

  @override
  bool orElse() => false;
}

class GetName implements Getter<String> {
  final String key;
  GetName(this.key);

  @override
  String get(Column c, String Function() next) {
    if (c is FieldColumn) {
      return CaseStyle.snakeCase.transform(key);
    } else if (c.get(IsForeignColumn())) {
      return c.get(GetLinkTable())!.
    } else {
      return next();
    }
  }

  @override
  String orElse() {
    throw UnimplementedError();
  }

}

class IsNullable implements Getter<bool> {
  @override
  bool get(Column c, bool Function() next) {
    return c is NullableColumn || (c is! NonNullableColumn && next());
  }
  @override
  bool orElse() => false;
}

class GetType implements Getter<String> {
  @override
  String get(Column c, String Function() next) {
    return c is FieldColumn ? c.type : next();
  }

  @override
  String orElse() {
    throw UnimplementedError();
  }
}



abstract class Getter<R> {

  static DatabaseDefinition? _scope;
  static set scope(DatabaseDefinition d) => _scope = d;
  static DatabaseDefinition get scope => _scope!;

  static final _cachedResults = <Getter, Map<Column, dynamic>>{};

  factory Getter(R Function(Column, R Function()) get, R Function() orElse) => _GetterImpl(get, orElse);

  R get(Column c, R Function() next);

  R orElse();
}

class _GetterImpl<R> implements Getter<R> {
  final R Function(Column, R Function()) _get;
  final R Function() _orElse;

  _GetterImpl(this._get, this._orElse);

  @override
  R get(Column c, R Function() next) => _get(c, next);

  @override
  R orElse() => _orElse();

}

extension on Column {
  R get<R>(Getter<R> getter) {
    if (Getter._cachedResults[getter]?.containsKey(this) ?? false) {
      return Getter._cachedResults[getter]![this] as R;
    }
    var result = getter.get(this, () {
      if (this is WrappedColumn) {
        return (this as WrappedColumn).column.get(getter);
      } else {
        return getter.orElse();
      }
    });

    return  (Getter._cachedResults[getter] ??= {})[this] = result;
  }
}