class UseConverter {
  final TypeConverter converter;

  const UseConverter(this.converter);
}

/// Extend this to define a custom type converter
abstract class TypeConverter<T> {
  /// The sql type to be converted
  final String type;
  const TypeConverter(this.type);

  dynamic encode(T value);
  T decode(dynamic value);

  bool canEncodeValue(dynamic value) => value is T;
}