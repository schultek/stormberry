import 'table.dart';

abstract class Column<T> {}

abstract class WrappedColumn<In, Out> extends Column<Out> {
  final Column<In> column;
  WrappedColumn(this.column);
}

/*
 bool get isFieldColumn;

  String name(String key);
  String get type;
  bool get isNullable;

  @override
  bool get isFieldColumn => column.isFieldColumn;

  @override
  String name(String key) => column.name(key);
  @override
  String get type => column.type;
  @override
  bool get isNullable => column.isNullable;
 */

extension ColumnMethods<T> on Column<T> {
  Column<T> primaryKey() => PrimaryKeyColumn(this);
  Column<T?> opt() => NullableColumn(this);
  Column<List<T>> many() => ManyColumn(this);
  Column<Never> hidden() => HiddenColumn(this);
}

extension ColumnOptMethods<T> on Column<T?> {
  Column<T> unOpt() => NonNullableColumn(this);
}

class PrimaryKeyColumn<T> extends WrappedColumn<T, T> {
  PrimaryKeyColumn(Column<T> column) : super(column);
}

class NullableColumn<T> extends WrappedColumn<T, T?> {
  NullableColumn(Column<T> column) : super(column);
}

class NonNullableColumn<T> extends WrappedColumn<T?, T> {
  NonNullableColumn(Column<T?> column) : super(column);
}

class ManyColumn<T> extends WrappedColumn<T, List<T>> {
  ManyColumn(Column<T> column) : super(column);
}

class HiddenColumn<T> extends WrappedColumn<T, Never> {
  HiddenColumn(Column<T> column) : super(column);
}

Column<T> ref<T>(Column<T> link) => ReferenceColumn<T>(link);

class ReferenceColumn<T extends Table> extends Column<T> {
  final Column? link;

  ReferenceColumn(this.link);

  Type get linkTableType => T;
}

Column<String> text() => TextColumn();

abstract class FieldColumn<T> extends Column<T> {
  String get type;
}

class TextColumn extends FieldColumn<String> {
  @override
  String get type => 'text';
}
