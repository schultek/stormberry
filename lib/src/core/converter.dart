/// Specify a converter to be used for the annotated field.
///
/// {@category Models}
class UseConverter {
  final TypeConverter converter;

  const UseConverter(this.converter);
}

/// Extend this to define a custom type converter.
///
/// {@category Models}
abstract class TypeConverter<T> {
  /// The sql type to be converted
  final String type;
  const TypeConverter(this.type);

  dynamic encode(T value);
  T decode(dynamic value);

  bool canEncodeValue(dynamic value) => value is T;

  dynamic tryEncode(dynamic value) {
    if (value is T) {
      return encode(value);
    } else if (value is List) {
      return value.map(tryEncode).cast<Object>().toList();
    } else if (value is Map) {
      return value.map((k, v) => MapEntry(k, tryEncode(v)));
    } else {
      return value;
    }
  }
}
