const staticCode = r'''

Type _typeOf<T>() => T;

T _decode<T>(dynamic value) {
  if (value.runtimeType == T) {
    return value as T;
  } else {
    if (_decoders[T] != null && value is String) {
      return _decoders[T]!(jsonDecode(value)) as T;
    } else if (_decoders[T] != null && value is Map<String, dynamic>) {
      return _decoders[T]!(value) as T;
    } else if (_typeConverters[T] != null) {
      return _typeConverters[T]!.decode(value) as T;
    } else {
      throw ConverterException('Cannot decode value $value of type ${value.runtimeType} to type $T. Unknown type. Did you forgot to include the class or register a custom type converter?');
    }
  }
}

dynamic _encode(dynamic value) {
  if (value == null) return null;
  try {
    return PostgresTextEncoder().convert(value);
  } catch (_) {
    if (_typeConverters[value.runtimeType] != null) {
      var encoded = _typeConverters[value.runtimeType]!.encode(value);
      return PostgresTextEncoder().convert(encoded);
    } else {
      throw ConverterException('Cannot encode value $value of type ${value.runtimeType}. Unknown type. Did you forgot to include the class or register a custom type converter?');
    }
  }
}

extension on Map<String, dynamic> {
  T get<T>(String key) {
    if (this[key] == null) {
      throw ConverterException('Parameter $key is required.');
    }
    return _decode<T>(this[key]!);
  }

  T? getOpt<T>(String key) {
    if (this[key] == null) {
      return null;
    }
    return get<T>(key);
  }

  List<T> getList<T>(String key) {
    if (this[key] == null) {
      throw ConverterException('Parameter $key is required.');
    } else if (this[key] is! List) {
      throw ConverterException(
          'Parameter ${this[key]} with key $key is not a List');
    }
    List value = this[key] as List<dynamic>;
    return value.map((dynamic item) => _decode<T>(item)).toList();
  }

  List<T>? getListOpt<T>(String key) {
    if (this[key] == null) {
      return null;
    }
    return getList<T>(key);
  }

  Map<K, V> getMap<K, V>(String key) {
    if (this[key] == null) {
      throw ConverterException('Parameter $key is required.');
    } else if (this[key] is! Map) {
      throw ConverterException(
          'Parameter ${this[key]} with key $key is not a Map');
    }
    Map value = this[key] as Map<dynamic, dynamic>;
    return value.map((dynamic key, dynamic value) =>
        MapEntry(_decode<K>(key), _decode<V>(value)));
  }

  Map<K, V>? getMapOpt<K, V>(String key) {
    if (this[key] == null) {
      return null;
    }
    return getMap<K, V>(key);
  }
}

class ConverterException implements Exception {
  final String message;
  const ConverterException(this.message);

  @override
  String toString() => 'ConverterException: $message';
}
''';
