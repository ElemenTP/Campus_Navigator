//import 'dart:convert';
import 'dart:math';
//import 'dart:io';

import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart'; //LatLng 类型在这里面，即为点类
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

LatLng latLngfromJson(Map<String, dynamic> json) {
  return LatLng(json['latitude'] as double, json['longitude'] as double);
}

Map<String, dynamic> latLngtoJson(LatLng latLng) {
  return <String, dynamic>{
    'latitude': latLng.latitude,
    'longitude': latLng.longitude,
  };
}

//点集类
class MapVertex {
  List<LatLng> listVertex = [];

  MapVertex();

  MapVertex.fromList(this.listVertex);

  MapVertex.fromJson(Map<String, dynamic> json) {
    List listVertexJson = json['listVertex'] as List;
    listVertexJson.forEach((element) {
      listVertex.add(latLngfromJson(element));
    });
  }

  Map<String, dynamic> toJson() {
    List listVertexJson = [];
    listVertex.forEach((element) {
      listVertexJson.add(latLngtoJson(element));
    });
    return <String, dynamic>{
      'listVertex': listVertexJson,
    };
  }

  SpecRoute nearestVertex(LatLng location) {
    late int shortestVtx;
    double shortestLength = double.infinity;
    for (int i = 0; i < listVertex.length; ++i) {
      double tmp = AMapTools.distanceBetween(location, listVertex[i]);
      if (tmp < shortestLength) {
        shortestVtx = i;
        shortestLength = tmp;
      }
    }
    return SpecRoute(
        location, listVertex[shortestVtx], shortestLength, shortestVtx);
  }
}

//建筑类
class Building {
  //建筑入口
  List<LatLng> doors = [];
  //建筑入口连接点
  List<int> juncpoint = [];
  //描述集
  List<String> description = [];

  Building();

  LatLng getApproxLocation() {
    double latall = 0;
    double lngall = 0;
    doors.forEach((element) {
      latall += element.latitude;
      lngall += element.longitude;
    });
    return LatLng(latall / doors.length, lngall / doors.length);
  }

  Building.fromJson(Map<String, dynamic> json) {
    List doorsJson = json['doors'] as List;
    doorsJson.forEach((element) {
      doors.add(latLngfromJson(element));
    });
    List juncpointJson = json['juncpoint'] as List;
    juncpointJson.forEach((element) {
      juncpoint.add(element as int);
    });
    List descriptionJson = json['description'] as List;
    descriptionJson.forEach((element) {
      description.add(element as String);
    });
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'doors': doors,
      'juncpoint': juncpoint,
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
      campusShape.add(latLngfromJson(element));
    });
    gate = json['gate'] as int;
    busstop = json['busstop'] as int;
    name = json['name'] as String;
  }

  Map<String, dynamic> toJson() {
    List campusShapeJson = [];
    campusShape.forEach((element) {
      campusShapeJson.add(latLngtoJson(element));
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
      length =
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

  MapEdge();

  List<List<Edge>> twoDimensionalize(int squareSize) {
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
  }

  Map<String, dynamic> toJson() {
    /*List listEdgeJson = [];
    listEdge.forEach((element) {
      listEdgeJson.add(element.toJson());
    });*/
    return <String, dynamic>{
      'listEdge': listEdge,
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

  int locationInCampus(LatLng location) {
    for (int i = 0; i < mapCampus.length; ++i) {
      if (AMapTools.latLngIsInPolygon(location, mapCampus[i].campusShape))
        return i;
    }
    return -1;
  }

  int buildingInCampus(Building building) {
    for (int i = 0; i < mapCampus.length; ++i) {
      if (mapBuilding[i].listBuilding.contains(building)) return i;
    }
    return -1;
  }
}

//导航状态类
class NaviState {
  bool naviStatus = false;
  bool crowding = false;
  bool onbike = false;
  bool startOnUserLoc = false;
  LatLng? startLocation;
  Building? startBuilding;
  List<LatLng> endLocation = [];
  List<Building> endBuilding = [];

  NaviState();

  Future<bool> manageNaviState(BuildContext context) async {
    return await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
              builder: (context, _setState) => AlertDialog(
                title: Text('导航'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _getStartWidget(_setState),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('以当前位置为起点：'),
                          Switch(
                              value: startOnUserLoc,
                              onChanged: (state) {
                                _setState(() {
                                  startOnUserLoc = state;
                                });
                                startBuilding = null;
                                startLocation = null;
                                mapMarkers.remove('startLocationMarker');
                              })
                        ],
                      ),
                      LimitedBox(
                        maxHeight: 270,
                        child: SingleChildScrollView(
                          child: _getEndWidget(_setState),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          _setState(() {
                            endLocation.clear();
                            endBuilding.clear();
                          });
                          mapMarkers.removeWhere((key, value) =>
                              key.contains('endLocationMarker'));
                        },
                        icon: Icon(Icons.delete),
                        label: Text('清除全部终点'),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('骑车：'),
                          Switch(
                              value: onbike,
                              onChanged: (state) {
                                _setState(() {
                                  onbike = state;
                                });
                              })
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('拥挤：'),
                          Switch(
                              value: crowding,
                              onChanged: (state) {
                                _setState(() {
                                  crowding = state;
                                });
                              })
                        ],
                      ),
                      Text(
                        '提示：点击可删除起点/终点',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('取消'),
                    onPressed: () => Navigator.of(context).pop(false), //关闭对话框
                  ),
                  TextButton(
                    child: Text('停止'),
                    onPressed: naviStatus
                        ? () {
                            naviStatus = false;
                            Navigator.of(context).pop(true);
                          }
                        : null, //关闭对话框
                  ),
                  TextButton(
                    child: Text('开始'),
                    onPressed: _canStartNavi()
                        ? () {
                            naviStatus = true;
                            Navigator.of(context).pop(true);
                          }
                        : null, //关闭对话框
                  ),
                ],
              ),
            ));
  }

  bool _canStartNavi() {
    return (startOnUserLoc || startLocation != null || startBuilding != null) &&
        (endLocation.isNotEmpty || endBuilding.isNotEmpty);
  }

  Widget _getStartWidget(void Function(void Function()) setState) {
    if (startOnUserLoc) {
      return Card(
        child: ListTile(
          title: Text('当前位置。'),
        ),
      );
    } else if (startLocation != null) {
      return Card(
        child: ListTile(
          title: Text(
              '坐标：${startLocation!.longitude}，${startLocation!.latitude}。'),
          onTap: () {
            setState(() {
              startLocation = null;
            });
            mapMarkers.remove('startLocationMarker');
          },
        ),
      );
    } else if (startBuilding != null) {
      return Card(
        child: ListTile(
          title: Text('建筑：${startBuilding!.description[0]}。'),
          onTap: () {
            setState(() {
              startBuilding = null;
            });
          },
        ),
      );
    } else {
      return Card(
        child: ListTile(
          title: Text('未设置出发点。'),
        ),
      );
    }
  }

  Widget _getEndWidget(void Function(void Function()) setState) {
    List<Widget> inColumn = [];
    endLocation.forEach((element) {
      inColumn.add(Card(
        child: ListTile(
          title: Text('坐标：${element.longitude}，${element.latitude}。'),
          onTap: () {
            setState(() {
              endLocation.remove(element);
            });
            mapMarkers
                .remove('endLocationMarker' + element.toJson().toString());
          },
        ),
      ));
    });
    endBuilding.forEach((element) {
      inColumn.add(Card(
        child: ListTile(
          title: Text('建筑：${element.description[0]}。'),
          onTap: () {
            setState(() {
              endBuilding.remove(element);
            });
          },
        ),
      ));
    });
    if (inColumn.isEmpty)
      inColumn.add(Card(
        child: ListTile(
          title: Text('未设置目的地。'),
        ),
      ));
    return Column(
      children: inColumn,
    );
  }
}

//用户设置
late SharedPreferences prefs;

//地图数据
late MapData mapData;

//导航状态
NaviState navistate = NaviState();

//地图Marker
Map<String, Marker> mapMarkers = {};

//地图直线
Map<String, Polyline> mapPolylines = {};

//地图控制器
AMapController? mapController;

//用户位置
AMapLocation userPosition = AMapLocation(latLng: LatLng(39.909187, 116.397451));

//定位权限状态
PermissionStatus locatePermissionStatus = PermissionStatus.denied;

bool stateLocationReqiurement(BuildContext context) {
  //没有定位权限，提示用户授予权限
  if (!locatePermissionStatus.isGranted) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('提示'),
              content: Text('欲使用此功能，请授予定位权限。'),
              actions: <Widget>[
                TextButton(
                  child: Text('取消'),
                  onPressed: () => Navigator.of(context).pop(), //关闭对话框
                ),
                TextButton(
                  child: Text('确定'),
                  onPressed: () async {
                    locatePermissionStatus =
                        await Permission.location.request();
                    Navigator.of(context).pop();
                  }, //关闭对话框
                ),
              ],
            ));
    return false;
  }
  //定位不正常（时间time为0），提示用户打开定位开关
  else if (userPosition.time == 0) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('提示'),
              content: Text('未开启系统定位开关，或者系统定位出错。'),
              actions: <Widget>[
                TextButton(
                  child: Text('确定'),
                  onPressed: () => Navigator.of(context).pop(), //关闭对话框
                ),
              ],
            ));
    return false;
  } else {
    return true;
  }
}

Future<bool> showRoute(BuildContext context) async {}

class SpecRoute {
  late LatLng startLocation;
  late LatLng endLocation;
  late double distance;
  late int endVertexNum;

  SpecRoute(
      this.startLocation, this.endLocation, this.distance, this.endVertexNum);
}

class Route {
  late NaviLoc a;
  late NaviLoc b;

  Route(this.a, this.b);
}

class NaviLoc {
  late int campusNum;
  late int vertexNum;
  late LatLng location;

  NaviLoc(this.campusNum, this.vertexNum, this.location);
}
