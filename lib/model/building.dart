import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'latlng.dart';

///建筑类
class Building {
  ///建筑入口集
  List<LatLng> doors = [];

  ///入口邻近点集
  List<int> juncpoint = [];

  ///建筑描述字段集
  List<String> description = [];

  Building();

  ///获取建筑的特征坐标
  LatLng getApproxLocation() {
    double latall = 0;
    double lngall = 0;
    for (LatLng element in doors) {
      latall += element.latitude;
      lngall += element.longitude;
    }
    return LatLng(latall / doors.length, lngall / doors.length);
  }

  ///通过json创建对象
  Building.fromJson(Map<String, dynamic> json) {
    List doorsJson = json['doors'] as List;
    for (var element in doorsJson) {
      doors.add(latLngfromJson(element));
    }
    List juncpointJson = json['juncpoint'] as List;
    for (var element in juncpointJson) {
      juncpoint.add(element as int);
    }
    List descriptionJson = json['description'] as List;
    for (var element in descriptionJson) {
      description.add(element as String);
    }
  }

  ///通过对象创建json
  Map<String, dynamic> toJson() {
    List doorsJson = [];
    for (LatLng element in doors) {
      doorsJson.add(latLngtoJson(element));
    }
    return <String, dynamic>{
      'doors': doorsJson,
      'juncpoint': juncpoint,
      'description': description,
    };
  }
}
