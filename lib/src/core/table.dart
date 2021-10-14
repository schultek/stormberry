import 'column.dart';

class Entity {}

class Table<T extends Entity> {}

abstract class View<T extends Table, E extends Entity> {}

extension GetViewColumn<T extends Table> on Column<T> {
  Column<U> viewAs<U extends View<T, dynamic>>() => ViewColumn<T, U>(this);
}

extension GetViewColumnOpt<T extends Table> on Column<T?> {
  Column<U?> viewAs<U extends View<T, dynamic>>() {
    return ViewColumn<T, U>(unOpt()).opt();
  }
}

extension GetViewColumnMany<T extends Table> on Column<List<T>> {
  Column<List<U>> viewAs<U extends View<T, dynamic>>() => ListViewColumn(this);
}

class ViewColumn<T extends Table, V extends View<T, dynamic>> extends WrappedColumn<T, V> {
  ViewColumn(Column<T> column) : super(column);
}

class ListViewColumn<T extends Table, V extends View<T, dynamic>> extends WrappedColumn<List<T>, List<V>> {
  ListViewColumn(Column<List<T>> column) : super(column);
}
