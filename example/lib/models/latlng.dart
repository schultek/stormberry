import 'package:stormberry/stormberry.dart';

class LatLng {
  double latitude, longitude;
  LatLng(this.latitude, this.longitude);
}

class LatLngConverter extends TypeConverter<LatLng> {
  const LatLngConverter() : super('point');

  @override
  dynamic encode(LatLng value) => PgPoint(value.latitude, value.longitude);

  @override
  LatLng decode(dynamic value) {
    if (value is PgPoint) {
      return LatLng(value.latitude, value.longitude);
    } else {
      var m = RegExp(r'\((.+),(.+)\)').firstMatch(value.toString());
      var lat = double.parse(m!.group(1)!.trim());
      var lng = double.parse(m.group(2)!.trim());
      return LatLng(lat, lng);
    }
  }
}
