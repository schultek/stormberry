import 'column.dart';
import 'table.dart';

abstract class Transformer<In, Out> {}

extension GetTransformerColumn<T> on Column<T> {
  Column<U> transform<U>(Transformer<T, U> transformer) => TransformerColumn(this, transformer);
}

extension ViewFilterColumn<T extends View> on Column<List<T>> {
  Column<List<T>> filter() => transform(FilterTransformer());
}

class FilterTransformer<T> extends Transformer<List<T>, List<T>> {}

class TransformerColumn<T, U> extends WrappedColumn<T, U> {
  final Transformer<T, U> transformer;

  TransformerColumn(Column<T> column, this.transformer) : super(column);
}
