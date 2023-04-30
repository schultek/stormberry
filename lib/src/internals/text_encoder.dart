import 'dart:convert';

import 'package:postgres/postgres.dart';

import '../core/converter.dart';

Type typeOf<T>() => T;

final _baseConverters = <Type, TypeConverter>{
  typeOf<dynamic>(): _PrimitiveTypeConverter((dynamic v) => v),
  typeOf<String>(): _PrimitiveTypeConverter<String>((dynamic v) => v.toString()),
  typeOf<int>(): _PrimitiveTypeConverter<int>((dynamic v) => num.parse(v.toString()).round()),
  typeOf<double>(): _PrimitiveTypeConverter<double>((dynamic v) => double.parse(v.toString())),
  typeOf<num>(): _PrimitiveTypeConverter<num>((dynamic v) => num.parse(v.toString())),
  typeOf<bool>():
      _PrimitiveTypeConverter<bool>((dynamic v) => v is num ? v != 0 : v.toString() == 'true'),
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

class TextEncoder {
  TextEncoder();

  static TextEncoder i = TextEncoder();

  T decode<T>(dynamic value) {
    if (value is T) {
      return value;
    } else if (_baseConverters[T] != null) {
      return _baseConverters[T]!.decode(value) as T;
    } else {
      throw ConverterException(
        'Cannot decode value $value of type ${value.runtimeType} to type $T: Unknown type.\n'
        'Did you forgot to include the class or specify a custom type converter?',
      );
    }
  }

  String encode(dynamic value, [TypeConverter? converter]) {
    try {
      return _TextEncoder().convert(convert(value, converter));
    } catch (e) {
      throw ConverterException(
        'Cannot encode value $value of type ${value.runtimeType}: $e.\n'
        'Did you forgot to include the class or register a custom type converter?',
      );
    }
  }

  dynamic convert(dynamic value, [TypeConverter? converter]) {
    if (converter != null && converter.canEncodeValue(value)) {
      return converter.encode(value);
    } else if (_baseConverters[value.runtimeType] != null) {
      return _baseConverters[value.runtimeType]!.encode(value);
    } else if (value is List) {
      return value.map(convert).cast<Object>().toList();
    } else if (value is Map) {
      return value.map((k, v) => MapEntry(k, convert(v)));
    } else {
      return value;
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

  T get<T>(String key, [Decoder<T>? decode]) {
    if (map[key] == null) {
      throw ConverterException('Parameter $key is required.');
    }
    return (decode ?? TextEncoder.i.decode<T>)(map[key]);
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
    return value.map((dynamic item) => (decode ?? TextEncoder.i.decode<T>)(item)).toList();
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
      throw ConverterException('Parameter ${map[key]} with key $key is not a Map');
    }
    Map value = map[key] as Map<dynamic, dynamic>;
    return (decode ?? TextEncoder.i.decode)(value);
  }

  Map<K, V>? getMapOpt<K, V>(String key, [Decoder<Map<K, V>>? decode]) {
    if (map[key] == null) {
      return null;
    }
    return getMap<K, V>(key, decode);
  }
}

enum QuoteStyle { single, double, none }

class _TextEncoder {
  String convert(dynamic value, {QuoteStyle quotes = QuoteStyle.single}) {
    if (value == null) {
      return 'null';
    } else if (value is bool) {
      return _encodeBoolean(value);
    } else if (value is num) {
      return _encodeNumber(value);
    } else if (value is String) {
      return _encodeString(value, quotes);
    } else if (value is DateTime) {
      return _encodeDateTime(value, quotes, isDateOnly: false);
    } else if (value is PgPoint) {
      return _encodePoint(value, quotes);
    } else if (value is Map) {
      return _encodeJSON(value, quotes);
    } else if (value is List) {
      return _encodeList(value, quotes);
    }

    throw PostgreSQLException("Could not infer type of value '$value'.");
  }

  String _encodeString(String text, QuoteStyle quotes) {
    if (quotes == QuoteStyle.single) {
      text = text.replaceAll("'", "''").replaceAll(r'\', r'\\');
      text = "'$text'";
      if (text.contains(r'\')) {
        text = ' E$text';
      }
    } else if (quotes == QuoteStyle.double) {
      text = text.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
      text = '"$text"';
    }

    return text;
  }

  String _encodeNumber(num value, {bool asInt = false}) {
    if (value.isNaN) {
      return "'nan'";
    }

    if (value.isInfinite) {
      return value.isNegative ? "'-infinity'" : "'infinity'";
    }

    if (asInt) {
      return value.toInt().toString();
    } else {
      return value.toString();
    }
  }

  String _encodeBoolean(bool value) {
    return value ? 'TRUE' : 'FALSE';
  }

  String _encodeDateTime(DateTime value, QuoteStyle quotes, {bool isDateOnly = false}) {
    var string = value.toIso8601String();

    if (isDateOnly) {
      string = string.split('T').first;
    } else {
      if (!value.isUtc) {
        final timezoneHourOffset = value.timeZoneOffset.inHours;
        final timezoneMinuteOffset = value.timeZoneOffset.inMinutes % 60;

        var hourComponent = timezoneHourOffset.abs().toString().padLeft(2, '0');
        final minuteComponent = timezoneMinuteOffset.abs().toString().padLeft(2, '0');

        if (timezoneHourOffset >= 0) {
          hourComponent = '+$hourComponent';
        } else {
          hourComponent = '-$hourComponent';
        }

        final timezoneString = [hourComponent, minuteComponent].join(':');
        string = [string, timezoneString].join('');
      }
    }

    if (string.substring(0, 1) == '-') {
      string = '${string.substring(1)} BC';
    } else if (string.substring(0, 1) == '+') {
      string = string.substring(1);
    }

    return _encodeString(string, quotes);
  }

  String _encodeJSON(dynamic value, QuoteStyle quotes) {
    return _encodeString(json.encode(value), quotes);
  }

  String _encodePoint(PgPoint value, QuoteStyle quotes) {
    return _encodeString(
        '(${_encodeNumber(value.latitude)},${_encodeNumber(value.longitude)})', quotes);
  }

  String _sharedType(List values) {
    List<String> types(dynamic value) => [
          if (value is String) 'string',
          if (value is int) 'int',
          if (value is double) 'double',
          if (value is num) 'num',
          'json',
        ];

    return values.fold<Iterable<String>>(types(values.first), (t, value) {
      var vt = types(value);
      return t.where((s) => vt.contains(s));
    }).first;
  }

  String _encodeList(List value, QuoteStyle quotes) {
    if (value.isEmpty) {
      return _encodeString('{}', quotes);
    }

    final type = _sharedType(value);
    late Iterable<String> encoded;

    if (type == 'string') {
      encoded = value.map((s) => _encodeString(s.toString(), QuoteStyle.double));
    } else if (type == 'int' || type == 'double' || type == 'num') {
      encoded = value.map((s) => _encodeNumber(s as num, asInt: type == 'int'));
    } else {
      encoded = value.map((s) => _encodeJSON(s, QuoteStyle.double));
    }

    return _encodeString('{${encoded.join(',')}}', quotes);
  }
}
