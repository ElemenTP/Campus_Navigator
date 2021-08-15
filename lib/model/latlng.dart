import 'package:amap_flutter_base/amap_flutter_base.dart';

///自定义LatLng类的fromJson构建函数
LatLng latLngfromJson(Map<String, dynamic> json) {
  return LatLng(json['latitude'] as double, json['longitude'] as double);
}

///自定义LatLng类的toJson构建函数
Map<String, dynamic> latLngtoJson(LatLng latLng) {
  return <String, dynamic>{
    'latitude': latLng.latitude,
    'longitude': latLng.longitude,
  };
}
