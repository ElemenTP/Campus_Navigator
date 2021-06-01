//import 'dart:convert';
import 'dart:math';
//import 'dart:io';

import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart'; //LatLng 类型在这里面，即为点类
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

//点集类
class MapVertex {
  List<LatLng> listVertex = [];

  MapVertex();

  MapVertex.fromList(this.listVertex);

  MapVertex.fromJson(Map<String, dynamic> json) {
    List listVertexJson = json['listVertex'] as List;
    listVertexJson.forEach((element) {
      listVertex.add(LatLng(
          element['latitude'] as double, element['longitude'] as double));
    });
  }

  Map<String, dynamic> toJson() {
    List listVertexJson = [];
    listVertex.forEach((element) {
      listVertexJson.add(<String, dynamic>{
        'latitude': element.latitude,
        'longitude': element.longitude,
      });
    });
    return <String, dynamic>{
      'listVertex': listVertexJson,
    };
  }
}

//建筑类
class Building {
  //入口集，坐标编号
  List<int> doors = [];
  //描述集
  List<String> description = [];

  Building();

  Building.fromJson(Map<String, dynamic> json) {
    List doorsJson = json['doors'] as List;
    doorsJson.forEach((element) {
      doors.add(element as int);
    });

    List descriptionJson = json['description'] as List;
    descriptionJson.forEach((element) {
      description.add(element as String);
    });
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'doors': doors,
      'description': description,
    };
  }
}

//建筑集类
class MapBuilding {
  List<Building> listBuilding = [];

  MapBuilding();

  MapBuilding.fromJson(Map<String, dynamic> json) {
    List listBuildingJson = json['listBuilding'] as List;
    listBuildingJson.forEach((element) {
      listBuilding.add(Building.fromJson(element));
    });
  }

  Map<String, dynamic> toJson() {
    /*List listBuildingJson = [];
    listBuilding.forEach((element) {
      listBuildingJson.add(element.toJson());
    });*/
    return <String, dynamic>{
      'listBuilding': listBuilding,
    };
  }
}

//校区类
class MapCampus {
  List<LatLng> campusShape = [];
  int gate = 0;
  int busstop = 0;
  String name = 'My Campus';

  MapCampus();

  MapCampus.fromJson(Map<String, dynamic> json) {
    List campusShapeJson = json['campusShape'] as List;
    campusShapeJson.forEach((element) {
      campusShape.add(LatLng(
          element['latitude'] as double, element['longitude'] as double));
    });
    gate = json['gate'] as int;
    busstop = json['busstop'] as int;
    name = json['name'] as String;
  }

  Map<String, dynamic> toJson() {
    List campusShapeJson = [];
    campusShape.forEach((element) {
      campusShapeJson.add(<String, dynamic>{
        'latitude': element.latitude,
        'longitude': element.longitude,
      });
    });
    return <String, dynamic>{
      'campusShape': campusShapeJson,
      'gate': gate,
      'busstop': busstop,
      'name': name,
    };
  }
}

//边类
class Edge {
  int pointa = -1;
  int pointb = -1;
  //边长度，建造函数自动生成
  double length = double.infinity;
  //边适应性，默认不通（<0），仅可步行(0)，可使用自行车(1)
  int availmthod = -1;
  //边拥挤度，需要时调用随机方法生成。
  double crowding = 1;
  //构造可用的边函数，默认可通行自行车
  Edge.avail(int iptpointa, int iptpointb, List<LatLng> listVertex,
      {int iptavailmthod = 1})
      : pointa = (iptpointa < 0
            ? 0
            : (iptpointa > listVertex.length ? listVertex.length : iptpointa)),
        pointb = (iptpointb < 0
            ? 0
            : (iptpointb > listVertex.length ? listVertex.length : iptpointb)),
        availmthod =
            (iptavailmthod < 0 ? 0 : (iptavailmthod > 1 ? 1 : iptavailmthod)) {
    if (pointa == pointb)
      availmthod = pointa = pointb = -1;
    else {
      this.length =
          AMapTools.distanceBetween(listVertex[pointa], listVertex[pointb]);
    }
  }
  //默认构造函数，将生成不通的边
  Edge();

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'pointa': pointa,
      'pointb': pointb,
      'length': length,
      'availmthod': availmthod,
    };
  }

  Edge.fromJson(Map<String, dynamic> json) {
    pointa = json['pointa'] ?? -1;
    pointb = json['pointb'] ?? -1;
    length = json['length'] ?? double.infinity;
    if (pointa == -1 || pointb == -1 || length == double.infinity)
      availmthod = -1;
    else
      availmthod = json['availmthod'] ?? -1;
  }
}

//边集类
class MapEdge {
  List<Edge> listEdge = [];
  int squareSize = 0;

  MapEdge();

  List<List<Edge>> twoDimensionalize() {
    List<List<Edge>> tmp = List.generate(
        squareSize, (_) => List.generate(squareSize, (_) => Edge()));
    listEdge.forEach((element) {
      tmp[element.pointa][element.pointb] = element;
      tmp[element.pointb][element.pointa] = element;
    });
    return tmp;
  }

  MapEdge.fromJson(Map<String, dynamic> json) {
    List listEdgeJson = json['listEdge'] as List;
    listEdgeJson.forEach((element) {
      listEdge.add(Edge.fromJson(element));
    });
    squareSize = json['squareSize'] as int;
  }

  Map<String, dynamic> toJson() {
    /*List listEdgeJson = [];
    listEdge.forEach((element) {
      listEdgeJson.add(element.toJson());
    });*/
    return <String, dynamic>{
      'listEdge': listEdge,
      'squareSize': squareSize,
    };
  }

  //随机拥挤度函数
  randomCrowding() {
    int randomSeed = DateTime.now().millisecondsSinceEpoch;
    listEdge.forEach((element) {
      element.crowding = Random(randomSeed).nextDouble();
    });
  }

  disableCrowding() {
    listEdge.forEach((element) {
      element.crowding = 1;
    });
  }
}

//校车时间表类
class BusTimeTable {
  //始发校区编号
  int campusFrom = 0;
  //目的校区编号
  int campusTo = 0;
  //出发时间的时
  int setOutHour = 0;
  //出发时间的分
  int setOutMinute = 0;
  //星期几？1-7，7是周日
  int dayOfWeek = 1;

  BusTimeTable();

  BusTimeTable.fromJson(Map<String, dynamic> json) {
    campusFrom = json['campusFrom'] as int;
    campusTo = json['campusTo'] as int;
    setOutHour = json['setOutHour'] as int;
    setOutMinute = json['setOutMinute'] as int;
    dayOfWeek = json['dayOfWeek'] as int;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'campusFrom': campusFrom,
      'campusTo': campusTo,
      'setOutHour': setOutHour,
      'setOutMinute': setOutMinute,
      'dayOfWeek': dayOfWeek,
    };
  }
}

//地图数据类
class MapData {
  //校区与编号的对应表
  List<MapCampus> mapCampus = [];
  //建筑列表
  List<MapBuilding> mapBuilding = [];
  //点与编号对应表
  List<MapVertex> mapVertex = [];
  //边与地图结构数据，按校区分成多个
  List<MapEdge> mapEdge = [];
  //校车时间表
  List<BusTimeTable> busTimeTable = [];

  MapData();

  MapData.fromJson(Map<String, dynamic> json) {
    List mapCampusJson = json['mapCampus'] as List;
    mapCampusJson.forEach((element) {
      mapCampus.add(MapCampus.fromJson(element));
    });
    List mapBuildingJson = json['mapBuilding'] as List;
    mapBuildingJson.forEach((element) {
      mapBuilding.add(MapBuilding.fromJson(element));
    });
    List mapVertexJson = json['mapVertex'] as List;
    mapVertexJson.forEach((element) {
      mapVertex.add(MapVertex.fromJson(element));
    });
    List mapEdgeJson = json['mapEdge'] as List;
    mapEdgeJson.forEach((element) {
      mapEdge.add(MapEdge.fromJson(element));
    });
    List busTimeTableJson = json['busTimeTable'] as List;
    busTimeTableJson.forEach((element) {
      busTimeTable.add(BusTimeTable.fromJson(element));
    });
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mapCampus': mapCampus,
      'mapBuilding': mapBuilding,
      'mapVertex': mapVertex,
      'mapEdge': mapEdge,
      'busTimeTable': busTimeTable,
    };
  }
}

//导航状态类
class NaviState {
  bool naviStatus = false;
  bool crowding = false;
  bool onbike = false;
  LatLng? startlocation;
  int? startVertex;
  Building? startBuilding;
  List<LatLng> endlocation = [];
  List<int> endVertex = [];
  List<Building> endBuilding = [];

  NaviState();

  reverseState() {
    naviStatus = !naviStatus;
  }

  Widget getstartwidget() {
    if (startlocation != null) {
      return Card();
    } else if (startVertex != null) {
      return Card();
    } else if (startBuilding != null) {
      return Card();
    } else {
      return Card();
    }
  }
}

//用户设置
late SharedPreferences prefs;

//地图数据
late MapData mapData;

//导航状态
NaviState navistate = NaviState();

//地图控制器
AMapController? mapController;

//用户位置
AMapLocation userPosition = AMapLocation(latLng: LatLng(39.909187, 116.397451));

//定位权限状态
PermissionStatus locatePermissionStatus = PermissionStatus.denied;
