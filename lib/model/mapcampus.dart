import 'dart:math';

import 'package:amap_flutter_base/amap_flutter_base.dart';

import 'latlng.dart';
import 'building.dart';
import 'edge.dart';

///校区类,描述校区的范围，入口，校车点等信息
class MapCampus {
  ///校区范围，校区多边形的点集构成
  List<LatLng> campusShape = [];

  ///校区大门
  int gate = 0;

  ///校车点
  int busstop = 0;

  ///校区名
  String name = '校区';

  ///拥挤度开关
  bool crowded = false;

  ///校区内建筑列表
  List<Building> listBuilding = [];

  ///校区内点与编号对应表
  List<LatLng> listVertex = [];

  ///校区内边与地图结构数据，按校区分成多个
  List<Edge> listEdge = [];

  MapCampus();

  ///通过json构建对象
  MapCampus.fromJson(Map<String, dynamic> json) {
    List campusShapeJson = json['campusShape'] as List;
    for (var element in campusShapeJson) {
      campusShape.add(latLngfromJson(element));
    }
    gate = json['gate'] as int? ?? 0;
    busstop = json['busstop'] as int? ?? 0;
    name = json['name'] as String? ?? '校区';
    List listBuildingJson = json['listBuilding'] as List;
    for (var element in listBuildingJson) {
      listBuilding.add(Building.fromJson(element));
    }
    List listVertexJson = json['listVertex'] as List;
    for (var element in listVertexJson) {
      listVertex.add(latLngfromJson(element));
    }
    List listEdgeJson = json['listEdge'] as List;
    for (var element in listEdgeJson) {
      listEdge.add(Edge.fromJson(element));
    }
    for (Edge curEdge in listEdge) {
      if (curEdge.availmthod >= 0 && curEdge.length == double.infinity) {
        curEdge.length = AMapTools.distanceBetween(
            listVertex[curEdge.pointa], listVertex[curEdge.pointb]);
      }
    }
  }

  ///通过对象创建json
  Map<String, dynamic> toJson() {
    List campusShapeJson = [];
    for (LatLng element in campusShape) {
      campusShapeJson.add(latLngtoJson(element));
    }
    List listVertexJson = [];
    for (LatLng element in listVertex) {
      listVertexJson.add(latLngtoJson(element));
    }
    return <String, dynamic>{
      'campusShape': campusShapeJson,
      'gate': gate,
      'busstop': busstop,
      'name': name,
      'listBuilding': listBuilding,
      'listVertex': listVertexJson,
      'listEdge': listEdge,
    };
  }

  ///随机拥挤度函数
  void randomCrowding() {
    if (!crowded) {
      for (Edge element in listEdge) {
        element.crowding = 1.0 - Random().nextDouble();
      }
      crowded = true;
    }
  }

  ///关闭拥挤度
  void disableCrowding() {
    if (crowded) {
      for (Edge element in listEdge) {
        element.crowding = 1;
      }
      crowded = false;
    }
  }
}
