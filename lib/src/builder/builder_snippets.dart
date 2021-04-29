/// A set of TypeConverters for primitive types
const defaultConverters = '''
  // primitive converters
  _typeOf<dynamic>():  _PrimitiveTypeConverter((dynamic v) => v),
  _typeOf<String>():   _PrimitiveTypeConverter<String>((dynamic v) => v.toString()),
  _typeOf<int>():      _PrimitiveTypeConverter<int>((dynamic v) => num.parse(v.toString()).round()),
  _typeOf<double>():   _PrimitiveTypeConverter<double>((dynamic v) => double.parse(v.toString())),
  _typeOf<num>():      _PrimitiveTypeConverter<num>((dynamic v) => num.parse(v.toString())),
  _typeOf<bool>():     _PrimitiveTypeConverter<bool>((dynamic v) => v is num ? v != 0 : v.toString() == 'true'),
  _typeOf<DateTime>(): _DateTimeConverter(),
  // generated converters''';

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

class _PrimitiveTypeConverter<T> implements TypeConverter<T> {
  const _PrimitiveTypeConverter(this.decoder);
  final T Function(dynamic value) decoder;
  
  @override dynamic encode(T value) => value;
  @override T decode(dynamic value) => decoder(value);
  @override String? get type => throw UnimplementedError();
}

class _DateTimeConverter implements TypeConverter<DateTime> {
 
  @override
  DateTime decode(dynamic d) {
    if (d is String) {
      return DateTime.parse(d);
    } else if (d is num) {
      return DateTime.fromMillisecondsSinceEpoch(d.round());
    } else {
      throw ConverterException('Cannot decode value of type ${d.runtimeType} to type DateTime, because a value of type String or num is expected.');
    }
  }

  @override String encode(DateTime self) => self.toUtc().toIso8601String();

  @override
  String? get type => throw UnimplementedError();
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
      var v = this[key];
      if (v is Map<String, dynamic> && v['data'] is List) {
        return v.getList<T>('data');
      } else {
        throw ConverterException(
            'Parameter $v with key $key is not a List');
      }
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
