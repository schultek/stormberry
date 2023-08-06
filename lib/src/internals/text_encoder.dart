import 'dart:convert';

import 'package:postgres/postgres.dart';

import '../core/converter.dart';

Type typeOf<T>() => T;

final _baseConverters = <Type, TypeConverter>{
  typeOf<dynamic>(): _PrimitiveTypeConverter((dynamic v) => v),
  typeOf<String>():
      _PrimitiveTypeConverter<String>((dynamic v) => v.toString()),
  typeOf<int>(): _PrimitiveTypeConverter<int>(
      (dynamic v) => num.parse(v.toString()).round()),
  typeOf<double>(): _PrimitiveTypeConverter<double>(
      (dynamic v) => double.parse(v.toString())),
  typeOf<num>():
      _PrimitiveTypeConverter<num>((dynamic v) => num.parse(v.toString())),
  typeOf<bool>(): _PrimitiveTypeConverter<bool>(
      (dynamic v) => v is num ? v != 0 : v.toString() == 'true'),
  typeOf<DateTime>(): _DateTimeConverter(),
};

class EnumTypeConverter<T extends Enum> extends TypeConverter<T> {
  const EnumTypeConverter(this.values) : super('text');
  final List<T> values;

  @override
  String encode(T value) => value.name;

  @override
  T decode(dynamic value) => values.byName(value as String);
}

class _PrimitiveTypeConverter<T> extends TypeConverter<T> {
  const _PrimitiveTypeConverter(this.decoder) : super('');
  final T Function(dynamic value) decoder;

  @override
  dynamic encode(T value) => value;
  @override
  T decode(dynamic value) => decoder(value);
}

class _DateTimeConverter extends TypeConverter<DateTime> {
  _DateTimeConverter() : super('');

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

  T _decode<T>(Object? value, Decoder<T>? decode) {
    if (decode != null) {
      return decode(value);
    } else {
      return _baseConverters[T]!.decode(value) as T;
    }
  }

  T get<T>(String key, [Decoder<T>? decode]) {
    if (map[key] == null) {
      throw ConverterException('Parameter $key is required.');
    }
    return _decode(map[key], decode);
  }

  T? getOpt<T>(String key, [Decoder<T>? decode]) {
    if (map[key] == null) {
      return null;
    }
    return get<T>(key, decode);
  }

  List<T> getList<T>(String key, [Decoder<T>? decode]) {
    if (map[key] == null) {
      throw ConverterException('Parameter $key is required.');
    } else if (map[key] is! List) {
      throw ConverterException('Parameter $key is not a List');
    }
    List value = map[key] as List<dynamic>;
    return value.map((dynamic item) => _decode(item, decode)).toList();
  }

  List<T>? getListOpt<T>(String key, [Decoder<T>? decode]) {
    if (map[key] == null) {
      return null;
    }
    return getList<T>(key, decode);
  }

  Map<K, V> getMap<K, V>(String key, [Decoder<Map<K, V>>? decode]) {
    if (map[key] == null) {
      throw ConverterException('Parameter $key is required.');
    } else if (map[key] is! Map) {
      throw ConverterException(
          'Parameter ${map[key]} with key $key is not a Map');
    }
    Map value = map[key] as Map<dynamic, dynamic>;
    return _decode(value, decode);
  }

  Map<K, V>? getMapOpt<K, V>(String key, [Decoder<Map<K, V>>? decode]) {
    if (map[key] == null) {
      return null;
    }
    return getMap<K, V>(key, decode);
  }
}
