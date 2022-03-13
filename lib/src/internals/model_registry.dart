import 'package:postgres/postgres.dart';
// ignore: implementation_imports
import 'package:postgres/src/text_codec.dart';

import '../core/annotations.dart';

Type typeOf<T>() => T;

final _baseConverters = <Type, TypeConverter>{
  typeOf<dynamic>(): _PrimitiveTypeConverter((dynamic v) => v),
  typeOf<String>(): _PrimitiveTypeConverter<String>((dynamic v) => v.toString()),
  typeOf<int>(): _PrimitiveTypeConverter<int>((dynamic v) => num.parse(v.toString()).round()),
  typeOf<double>(): _PrimitiveTypeConverter<double>((dynamic v) => double.parse(v.toString())),
  typeOf<num>(): _PrimitiveTypeConverter<num>((dynamic v) => num.parse(v.toString())),
  typeOf<bool>(): _PrimitiveTypeConverter<bool>((dynamic v) => v is num ? v != 0 : v.toString() == 'true'),
  typeOf<DateTime>(): _DateTimeConverter(),
};

class _PrimitiveTypeConverter<T> implements TypeConverter<T> {
  const _PrimitiveTypeConverter(this.decoder);
  final T Function(dynamic value) decoder;

  @override
  dynamic encode(T value) => value;
  @override
  T decode(dynamic value) => decoder(value);
  @override
  String? get type => throw UnimplementedError();
}

class _DateTimeConverter implements TypeConverter<DateTime> {
  @override
  DateTime decode(dynamic d) {
    if (d is String) {
      return DateTime.parse(d);
    } else if (d is num) {
      return DateTime.fromMillisecondsSinceEpoch(d.round());
    } else {
      throw ConverterException(
          'Cannot decode value of type ${d.runtimeType} to type DateTime, because a value of type String or num is expected.');
    }
  }

  @override
  String encode(DateTime self) => self.toUtc().toIso8601String();

  @override
  String? get type => throw UnimplementedError();
}

class ModelRegistry {
  final Map<Type, TypeConverter> converters;

  ModelRegistry(Map<Type, TypeConverter> converters) : converters = {..._baseConverters, ...converters};

  T decode<T>(dynamic value) {
    if (value.runtimeType == T) {
      return value as T;
    } else {
      if (converters[T] != null) {
        return converters[T]!.decode(value) as T;
      } else {
        throw ConverterException(
          'Cannot decode value $value of type ${value.runtimeType} to type $T. Unknown type. Did you forgot to include the class or register a custom type converter?',
        );
      }
    }
  }

  String encode(dynamic value, {bool escape = true}) {
    if (value == null) return 'null';
    try {
      var encoded = PostgresTextEncoder().convert(value);
      if (!escape) return encoded;
      if (value is Map) return "'${encoded.replaceAll("'", "''")}'";
      return value is List || value is PgPoint ? "'$encoded'" : encoded;
    } catch (_) {
      try {
        if (converters[value.runtimeType] != null) {
          return encode(converters[value.runtimeType]!.encode(value), escape: escape);
        } else if (value is List) {
          return encode(value.map((v) => encode(v, escape: false)).toList(), escape: escape);
        } else {
          throw const ConverterException('');
        }
      } catch (_) {
        throw ConverterException(
          'Cannot encode value $value of type ${value.runtimeType}. Unknown type. Did you forgot to include the class or register a custom type converter?',
        );
      }
    }
  }
}

class ConverterException implements Exception {
  final String message;
  const ConverterException(this.message);

  @override
  String toString() => 'ConverterException: $message';
}

typedef Decoder<T> = T Function(dynamic v);

class TypedMap {
  Map<String, dynamic> map;

  TypedMap(this.map);

  T get<T>(String key, Decoder<T> decode) {
    if (map[key] == null) {
      throw ConverterException('Parameter $key is required.');
    }
    return decode(map[key]);
  }

  T? getOpt<T>(String key, Decoder<T> decode) {
    if (map[key] == null) {
      return null;
    }
    return get<T>(key, decode);
  }

  List<T> getList<T>(String key, Decoder<T> decode) {
    if (map[key] == null) {
      throw ConverterException('Parameter $key is required.');
    } else if (map[key] is! List) {
      throw ConverterException('Parameter $key is not a List');
    }
    List value = map[key] as List<dynamic>;
    return value.map((dynamic item) => decode(item)).toList();
  }

  List<T>? getListOpt<T>(String key, Decoder<T> decode) {
    if (map[key] == null) {
      return null;
    }
    return getList<T>(key, decode);
  }

  Map<K, V> getMap<K, V>(String key, Decoder<Map<K, V>> decode) {
    if (map[key] == null) {
      throw ConverterException('Parameter $key is required.');
    } else if (map[key] is! Map) {
      throw ConverterException('Parameter ${map[key]} with key $key is not a Map');
    }
    Map value = map[key] as Map<dynamic, dynamic>;
    return decode(value);
  }

  Map<K, V>? getMapOpt<K, V>(String key, Decoder<Map<K, V>> decode) {
    if (map[key] == null) {
      return null;
    }
    return getMap<K, V>(key, decode);
  }
}
