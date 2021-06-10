import 'dart:io';
import 'dart:math';

import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shortpath.dart';

///自行车速度
const double BIKESPEED = 0.5;

///默认地图缩放比例
const double DEFAULT_ZOOM = 18;

///食堂名称
const String CANTEEN_NAME = '食堂';

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

///点集类
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
}

///建筑类
class Building {
  ///建筑入口
  List<LatLng> doors = [];

  ///建筑入口连接点
  List<int> juncpoint = [];

  ///描述集
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
    List doorsJson = [];
    doors.forEach((element) {
      doorsJson.add(latLngtoJson(element));
    });
    return <String, dynamic>{
      'doors': doorsJson,
      'juncpoint': juncpoint,
      'description': description,
    };
  }
}

///建筑集类
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

///校区类
class MapCampus {
  List<LatLng> campusShape = [];
  int gate = 0;
  int busstop = 0;
  String name = '校区';

  MapCampus();

  MapCampus.fromJson(Map<String, dynamic> json) {
    List campusShapeJson = json['campusShape'] as List;
    campusShapeJson.forEach((element) {
      campusShape.add(latLngfromJson(element));
    });
    gate = json['gate'] as int? ?? 0;
    busstop = json['busstop'] as int? ?? 0;
    name = json['name'] as String? ?? '校区';
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

///边类
class Edge {
  int pointa = -1;
  int pointb = -1;

  ///边长度，建造函数自动生成
  double length = double.infinity;

  ///边适应性，默认不通（<0），仅可步行(0)，可使用自行车(1)
  int availmthod = -1;

  ///边拥挤度，需要时调用随机方法生成。
  double crowding = 1;

  ///默认构造函数，将生成不通的边
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
    pointa = json['pointa'] as int? ?? -1;
    pointb = json['pointb'] as int? ?? -1;
    length = json['length'] as double? ?? double.infinity;
    availmthod = json['availmthod'] as int? ?? -1;
  }
}

///边集类
class MapEdge {
  List<Edge> listEdge = [];

  bool crowded = false;

  MapEdge();

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

  ///随机拥挤度函数
  void randomCrowding() {
    if (!crowded) {
      listEdge.forEach((element) {
        element.crowding = 1.0 - Random().nextDouble();
      });
      crowded = true;
    }
  }

  void disableCrowding() {
    if (crowded) {
      listEdge.forEach((element) {
        element.crowding = 1;
      });
      crowded = false;
    }
  }
}

///校车时间表类
class BusTimeTable {
  ///是否是校车
  bool isSchoolBus = false;

  ///始发校区编号
  int campusFrom = 0;

  ///目的校区编号
  int campusTo = 0;

  ///出发时间的时，0-23，违例视为任何时间
  int setOutHour = -1;

  ///出发时间的分，0-59，违例视为任何时间
  int setOutMinute = -1;

  ///星期几？1-7，7是周日，违例视为任何时间
  int dayOfWeek = 0;

  ///时间表描述
  String description = '公共交通';

  ///预计乘坐时间，单位分钟
  int takeTime = 3600;

  BusTimeTable();

  BusTimeTable.fromJson(Map<String, dynamic> json) {
    isSchoolBus = json['isSchoolBus'] as bool? ?? false;
    campusFrom = json['campusFrom'] as int? ?? 0;
    campusTo = json['campusTo'] as int? ?? 0;
    setOutHour = json['setOutHour'] as int? ?? -1;
    setOutMinute = json['setOutMinute'] as int? ?? -1;
    dayOfWeek = json['dayOfWeek'] as int? ?? 0;
    description = json['description'] as String? ?? '公共交通';
    takeTime = json['takeTime'] as int? ?? 3600;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'isSchoolBus': isSchoolBus,
      'campusFrom': campusFrom,
      'campusTo': campusTo,
      'setOutHour': setOutHour,
      'setOutMinute': setOutMinute,
      'dayOfWeek': dayOfWeek,
      'description': description,
      'takeTime': takeTime,
    };
  }
}

///地图数据类
class MapData {
  ///校区与编号的对应表
  List<MapCampus> mapCampus = [];

  ///建筑列表
  List<MapBuilding> mapBuilding = [];

  ///点与编号对应表
  List<MapVertex> mapVertex = [];

  ///边与地图结构数据，按校区分成多个
  List<MapEdge> mapEdge = [];

  ///校车时间表
  List<BusTimeTable> busTimeTable = [];

  MapData();

  ///从json对象中读取
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
    for (int i = 0; i < mapEdge.length; ++i) {
      List<Edge> curListEdge = mapEdge[i].listEdge;
      for (int j = 0; j < curListEdge.length; ++j) {
        Edge curEdge = curListEdge[j];
        if (curEdge.availmthod >= 0 && curEdge.length == double.infinity) {
          curEdge.length = AMapTools.distanceBetween(
              mapVertex[i].listVertex[curEdge.pointa],
              mapVertex[i].listVertex[curEdge.pointb]);
        }
      }
    }
  }

  ///生成json对象
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mapCampus': mapCampus,
      'mapBuilding': mapBuilding,
      'mapVertex': mapVertex,
      'mapEdge': mapEdge,
      'busTimeTable': busTimeTable,
    };
  }

  ///判断某点location所属校区
  int locationInCampus(LatLng location) {
    for (int i = 0; i < mapCampus.length; ++i) {
      if (AMapTools.latLngIsInPolygon(location, mapCampus[i].campusShape))
        return i;
    }
    return -1;
  }

  ///判断某建筑building
  int buildingInCampus(Building building) {
    for (int i = 0; i < mapCampus.length; ++i) {
      if (mapBuilding[i].listBuilding.contains(building)) return i;
    }
    return -1;
  }

  List<List<Edge>> getAdjacentMatrix(int campusNum) {
    List<Edge> listEdge = mapEdge[campusNum].listEdge;
    int squareSize = mapVertex[campusNum].listVertex.length;
    List<List<Edge>> tmp = List.generate(
        squareSize, (_) => List.generate(squareSize, (_) => Edge()));
    listEdge.forEach((element) {
      tmp[element.pointa][element.pointb] = element;
      tmp[element.pointb][element.pointa] = element;
    });
    return tmp;
  }

  int nearestVertex(int campusNum, LatLng location) {
    List<LatLng> listVertex = mapVertex[campusNum].listVertex;
    late int shortestVtx;
    double shortestLength = double.infinity;
    for (int i = 0; i < listVertex.length; ++i) {
      double tmp = AMapTools.distanceBetween(location, listVertex[i]);
      if (tmp < shortestLength) {
        shortestVtx = i;
        shortestLength = tmp;
      }
    }
    return shortestVtx;
  }

  LatLng getVertexLatLng(int campusNum, int vertexNum) {
    return mapVertex[campusNum].listVertex[vertexNum];
  }

  ///随机拥挤度函数
  void randomCrowding() {
    mapEdge.forEach((element) {
      if (!element.crowded) {
        element.listEdge.forEach((element1) {
          element1.crowding = 1.0 - Random().nextDouble();
        });
        element.crowded = true;
      }
    });
  }

  void disableCrowding() {
    mapEdge.forEach((element) {
      if (element.crowded) {
        element.listEdge.forEach((element2) {
          element2.crowding = 1;
        });
        element.crowded = false;
      }
    });
  }

  List getBestTimeTable(int campusFrom, int campusTo, DateTime timeAtGetOn,
      {bool? onlySchoolBus}) {
    BusTimeTable? target;
    int takenTime = 114514;
    busTimeTable.forEach((element) {
      if (onlySchoolBus != null) if (onlySchoolBus ^ element.isSchoolBus)
        return;
      if (element.campusFrom != campusFrom || element.campusTo != campusTo)
        return;
      if (element.dayOfWeek > 0 &&
          element.dayOfWeek < 8 &&
          element.dayOfWeek != timeAtGetOn.weekday) return;
      int thisTakenTime = 0;
      if (element.setOutHour >= 0 &&
          element.setOutHour < 24 &&
          element.setOutHour < timeAtGetOn.hour)
        return;
      else if (element.setOutHour >= 0 && element.setOutHour < 24)
        thisTakenTime += (element.setOutHour - timeAtGetOn.hour) * 60;
      if (element.setOutMinute >= 0 &&
          element.setOutMinute < 60 &&
          element.setOutMinute < timeAtGetOn.minute)
        return;
      else if (element.setOutMinute >= 0 && element.setOutMinute < 60)
        thisTakenTime += element.setOutMinute - timeAtGetOn.minute;
      thisTakenTime += element.takeTime;
      if (thisTakenTime < takenTime) {
        target = element;
        takenTime = thisTakenTime;
      }
    });
    if (target == null)
      return [];
    else
      return [target, takenTime];
  }
}

///导航状态类
class NaviState {
  bool naviStatus = false;
  bool crowding = false;
  bool onbike = false;
  bool startOnUserLoc = false;
  bool realTime = false;
  bool minTime = false;
  dynamic start;
  List end = [];
  double routeLength = 0;

  NaviState();

  ///管理导航状态界面
  Future<bool> manageNaviState(BuildContext context) async {
    return await showDialog(
            context: context,
            builder: (context) => StatefulBuilder(
                  builder: (context, _setState) => AlertDialog(
                    title: Text('导航'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
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
                                      if (!state) realTime = state;
                                    });
                                    start = null;
                                    mapMarkers.remove('start');
                                  })
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('实时导航：'),
                              Switch(
                                value: realTime,
                                onChanged: startOnUserLoc
                                    ? (state) =>
                                        _setState(() => realTime = state)
                                    : null,
                              )
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
                                start = null;
                                end.clear();
                              });
                              mapMarkers.removeWhere(
                                  (key, value) => !key.contains('onTap'));
                            },
                            icon: Icon(Icons.delete),
                            label: Text('清除全部点'),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('骑车：'),
                              Switch(
                                value: onbike,
                                onChanged: (state) =>
                                    _setState(() => onbike = state),
                              )
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('最短时间：'),
                              Switch(
                                value: minTime,
                                onChanged: (state) => _setState(() {
                                  minTime = state;
                                  if (!state) crowding = state;
                                }),
                              )
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('拥挤：'),
                              Switch(
                                value: crowding,
                                onChanged: minTime
                                    ? (state) =>
                                        _setState(() => crowding = state)
                                    : null,
                              )
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
                        onPressed: () => Navigator.of(context).pop(false),

                        ///关闭对话框
                      ),
                      TextButton(
                        child: Text('停止'),
                        onPressed: naviStatus
                            ? () {
                                naviStatus = false;
                                if (logEnabled)
                                  logSink.write(
                                      DateTime.now().toString() + ': 停止导航。\n');
                                Navigator.of(context).pop(true);
                              }
                            : null,

                        ///关闭对话框
                      ),
                      TextButton(
                        child: Text('开始'),
                        onPressed: (startOnUserLoc || start != null) &&
                                end.isNotEmpty
                            ? () {
                                naviStatus = true;
                                if (logEnabled)
                                  logSink.write(
                                      DateTime.now().toString() + ': 开始导航。\n');
                                Navigator.of(context).pop(true);
                              }
                            : null,

                        ///关闭对话框
                      ),
                    ],
                  ),
                )) ??
        false;
  }

  ///获取起点对应的widget
  Widget _getStartWidget(void Function(void Function()) setState) {
    if (startOnUserLoc) {
      return Card(
        child: ListTile(
          title: Text('当前位置。'),
        ),
      );
    } else if (start.runtimeType == LatLng) {
      return Card(
        child: ListTile(
          title: Text('坐标：${start!.longitude}，${start!.latitude}。'),
          onTap: () {
            setState(() => start = null);
            mapMarkers.remove('start');
          },
        ),
      );
    } else if (start.runtimeType == Building) {
      return Card(
        child: ListTile(
          title: Text('建筑：${start!.description.first}。'),
          onTap: () {
            setState(() => start = null);
            mapMarkers.remove('start');
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

  ///获取终点对应的widget
  Widget _getEndWidget(void Function(void Function()) setState) {
    List<Widget> inColumn = [];
    end.forEach((element) {
      inColumn.add(element.runtimeType == LatLng
          ? Card(
              child: ListTile(
                title: Text('坐标：${element.longitude}，${element.latitude}。'),
                onTap: () {
                  setState(() => end.remove(element));
                  mapMarkers.remove('end' + element.hashCode.toString());
                },
              ),
            )
          : Card(
              child: ListTile(
                title: Text('建筑：${element.description.first}。'),
                onTap: () {
                  setState(() => end.remove(element));
                  mapMarkers.remove('end' + element.hashCode.toString());
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

  ///按不同导航策略获取路程长度对应的字符串
  String getlengthString() {
    if (minTime) {
      return '约' + (routeLength / 60).toStringAsFixed(0) + '分钟';
    } else {
      return '约' +
          (routeLength / (onbike ? BIKESPEED : 1)).toStringAsFixed(0) +
          '米';
    }
  }
}

///导航工具类
class NaviTools {
  ///用于展示拥挤度的颜色字典
  static const Map<int, dynamic> _colortype = {
    3: Colors.white,
    2: Colors.green,
    1: Colors.amber,
    0: Colors.red,
  };

  ///导航道路，传入dijstra得到的route和某校区点集，返回直线
  static void displayRoute(List<int> path, int campusNum) {
    List<List<Edge>> edgevertex = mapData.getAdjacentMatrix(campusNum);
    List<LatLng> listvertex = mapData.mapVertex[campusNum].listVertex;
    for (int i = 0; i < path.length - 1; ++i) {
      int a = edgevertex[path[i]][path[i + 1]].crowding * 3 ~/ 1;
      Polyline polyline = Polyline(
        points: <LatLng>[listvertex[path[i]], listvertex[path[i + 1]]],
        color: _colortype[a],
        capType: CapType.arrow,
        joinType: JoinType.round,
      );
      mapPolylines.add(polyline);
    }
  }

  ///传入两点（建筑点和路径点），返回虚线
  static void entryRoute(LatLng from, LatLng to) {
    Polyline polyline = Polyline(
      points: <LatLng>[from, to],
      dashLineType: DashLineType.square,
      capType: CapType.arrow,
      joinType: JoinType.round,
    );
    mapPolylines.add(polyline);
  }

  ///生成一个以某点为中心的近似圆
  static List<LatLng> circleAround(LatLng center,int rad) {
    const int times = 8;  

    ///多边形的点数
    Offset res = Offset(center.latitude, center.longitude);
    List<LatLng> circlelist = [];
    for (int i = 0; i < times; ++i) {
      Offset c = Offset.fromDirection(i * 2 * pi / times, 180 * rad / pi / 6371 / 1000);
      Offset c1 = Offset(
          res.dx + c.dx, res.dy + c.dy / cos((res.dx + c.dx) / 180 * pi));

      circlelist.add(LatLng(c1.dx, c1.dy));
    }
    return circlelist;
  }

  ///检查定位是否正常
  static bool stateLocationReqiurement(BuildContext context) {
    ///没有定位权限，提示用户授予权限
    if (!locatePermissionStatus.isGranted) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('提示'),
                content: Text('欲使用此功能，请授予定位权限。'),
                actions: <Widget>[
                  TextButton(
                    child: Text('取消'),
                    onPressed: () => Navigator.of(context).pop(),

                    ///关闭对话框
                  ),
                  TextButton(
                    child: Text('确定'),
                    onPressed: () async {
                      locatePermissionStatus =
                          await Permission.location.request();
                      Navigator.of(context).pop();
                    },

                    ///关闭对话框
                  ),
                ],
              ));
      return false;
    }

    ///定位不正常（时间time为0），提示用户打开定位开关
    else if (userLocation.time == 0) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('提示'),
                content: Text('未开启系统定位开关，或者系统定位出错。'),
                actions: <Widget>[
                  TextButton(
                    child: Text('确定'),
                    onPressed: () => Navigator.of(context).pop(),

                    ///关闭对话框
                  ),
                ],
              ));
      return false;
    } else {
      return true;
    }
  }

  ///展示导航路线函数，对终点列表进行排序，逐个使用狄杰斯特拉算法，智能选择校区间导航方法
  static Future<void> showRoute(BuildContext context) async {
    ///清空线列表和路线长度
    mapPolylines.clear();
    naviState.routeLength = 0;

    ///检查导航状态，为开始时绘制路线
    if (naviState.naviStatus) {
      //导航开始时的日期时间，用于智能选择校区间导航方法
      DateTime routeBeginTime = DateTime.now();
      if (logEnabled)
        logSink.write(routeBeginTime.toString() + ': 路线计算函数开始。\n');
      //如果是选择以用户当前位置为起点，则判断是否有定位权限，定位是否正常，在不在校区内
      if (naviState.startOnUserLoc) {
        if (stateLocationReqiurement(context)) {
          int startCampus = mapData.locationInCampus(userLocation.latLng);
          if (startCampus >= 0) {
            naviState.start = userLocation.latLng;
            if (logEnabled)
              logSink.write(DateTime.now().toString() + ': 以用户坐标为起点。\n');
          } else {
            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                      title: Text('提示'),
                      content: Text('您不在任何校区内。'),
                      actions: <Widget>[
                        TextButton(
                          child: Text('取消'),
                          onPressed: () => Navigator.of(context).pop(), //关闭对话框
                        ),
                      ],
                    ));
            if (logEnabled)
              logSink.write(DateTime.now().toString() + ': 您不在任何校区内，停止实时导航。\n');
            naviState.naviStatus = false;
            return;
          }
        } else {
          if (logEnabled)
            logSink
                .write(DateTime.now().toString() + ': 没有定位权限或定位不正常，停止实时导航。\n');
          naviState.naviStatus = false;
          return;
        }
      }
      if (logEnabled) {
        logSink.write(DateTime.now().toString() +
            ': ' +
            '骑车' +
            (naviState.onbike ? '开启' : '关闭') +
            '，拥挤度' +
            (naviState.crowding ? '开启' : '关闭') +
            '。\n');
        logSink.write(DateTime.now().toString() + ': 开始目的地排序。\n');
      }
      try {
        //排序所用新列表
        List naviOrder = [naviState.start];
        naviOrder.addAll(naviState.end);

        ///终点集合中，坐标以其本身，建筑以特征坐标，按直线距离顺序排序
        for (int i = 0; i < naviOrder.length - 2; ++i) {
          int nextEnd = i + 1;
          double minDistance = double.infinity;
          for (int j = i + 1; j < naviOrder.length; ++j) {
            double curDistance = AMapTools.distanceBetween(
                getLocation(naviOrder[i]), getLocation(naviOrder[j]));
            if (curDistance < minDistance) {
              minDistance = curDistance;
              nextEnd = j;
            }
          }
          if (nextEnd != i + 1) {
            var tmp = naviOrder[i + 1];
            naviOrder[i + 1] = naviOrder[nextEnd];
            naviOrder[nextEnd] = tmp;
          }
        }
        int transmethod = naviState.onbike ? 1 : 0;
        naviState.crowding
            ? mapData.randomCrowding()
            : mapData.disableCrowding();
        if (logEnabled) {
          logSink.write(DateTime.now().toString() + ': 完成目的地排序。\n');
          naviOrder.forEach((element) {
            logSink.write(DateTime.now().toString() +
                ': ' +
                (element.runtimeType == LatLng
                    ? '坐标: ' + element.toJson().toString()
                    : '建筑: ' + (element as Building).description.first) +
                '\n');
          });
          logSink.write(DateTime.now().toString() + ': 开始类型转换与狄杰斯特拉算法。\n');
        }

        ///将排好序的列表中的元素
        for (int i = 0; i < naviOrder.length; ++i) {
          int campusNum = 0;
          LatLng realLatLng = LatLng(0, 0);
          LatLng juncLatLng = LatLng(0, 0);
          double juncLength = 114514;
          NaviLoc curNaviLoc = NaviLoc(campusNum, 0, realLatLng);
          if (naviOrder[i].runtimeType == LatLng) {
            realLatLng = naviOrder[i];
            campusNum = mapData.locationInCampus(realLatLng);
            int nearVertex = mapData.nearestVertex(campusNum, realLatLng);
            juncLatLng = mapData.getVertexLatLng(campusNum, nearVertex);
            juncLength = (AMapTools.distanceBetween(juncLatLng, realLatLng) *
                    (naviState.onbike ? BIKESPEED : 1)) /
                (naviState.crowding ? 1 - Random().nextDouble() : 1);
            curNaviLoc = NaviLoc(campusNum, nearVertex, naviOrder[i]);
          } else if (naviOrder[i].runtimeType == Building) {
            Building curBuilding = naviOrder[i] as Building;
            campusNum = mapData.buildingInCampus(curBuilding);
            LatLng disReference = i == 0
                ? getLocation(naviOrder[1])
                : (naviOrder[i - 1] as NaviLoc).location;
            int choosedDoor = 0;
            if (curBuilding.doors.length > 1) {
              double minDistance = double.infinity;
              for (int j = 0; j < curBuilding.doors.length; ++j) {
                double curDistance = AMapTools.distanceBetween(
                    disReference, curBuilding.doors[j]);
                if (curDistance < minDistance) {
                  minDistance = curDistance;
                  choosedDoor = j;
                }
              }
            }
            realLatLng = curBuilding.doors[choosedDoor];
            int juncVertex = curBuilding.juncpoint[choosedDoor];
            juncLatLng = mapData.getVertexLatLng(campusNum, juncVertex);
            juncLength = (AMapTools.distanceBetween(juncLatLng, realLatLng) *
                    (naviState.onbike ? BIKESPEED : 1)) /
                (naviState.crowding ? 1 - Random().nextDouble() : 1);
            curNaviLoc = NaviLoc(campusNum, juncVertex, realLatLng);
          }
          naviOrder[i] = curNaviLoc;
          if (i != 0) {
            NaviLoc startVertex = naviOrder[i - 1] as NaviLoc;
            NaviLoc endVertex = curNaviLoc;
            if (startVertex.campusNum == endVertex.campusNum) {
              if (startVertex.vertexNum != endVertex.vertexNum) {
                ShortPath path = ShortPath(
                    mapData.getAdjacentMatrix(startVertex.campusNum),
                    startVertex.vertexNum,
                    endVertex.vertexNum,
                    transmethod);
                naviState.routeLength += path.getrelativelen();
                displayRoute(path.getroute(), startVertex.campusNum);
              }
            } else {
              double lengthPublicTransStart = 0;
              double lengthPublicTransEnd = 0;
              double lengthSchoolBusStart = 0;
              double lengthSchoolBusEnd = 0;
              List<int> routePublicTransStart = [];
              List<int> routePublicTransEnd = [];
              List<int> routeSchoolBusStart = [];
              List<int> routeSchoolBusEnd = [];
              int startBusStop =
                  mapData.mapCampus[startVertex.campusNum].busstop;
              int endBusStop = mapData.mapCampus[endVertex.campusNum].busstop;
              int startGate = mapData.mapCampus[startVertex.campusNum].gate;
              int endGate = mapData.mapCampus[endVertex.campusNum].gate;
              if (startVertex.vertexNum != startBusStop) {
                ShortPath startBusStopPath = ShortPath(
                    mapData.getAdjacentMatrix(startVertex.campusNum),
                    startVertex.vertexNum,
                    startBusStop,
                    transmethod);
                lengthSchoolBusStart = startBusStopPath.getrelativelen();
                routeSchoolBusStart = startBusStopPath.getroute();
              }
              if (startVertex.vertexNum != startGate) {
                ShortPath startGatePath = ShortPath(
                    mapData.getAdjacentMatrix(startVertex.campusNum),
                    startVertex.vertexNum,
                    startGate,
                    transmethod);
                lengthPublicTransStart = startGatePath.getrelativelen();
                routePublicTransStart = startGatePath.getroute();
              }
              if (endVertex.vertexNum != endBusStop) {
                ShortPath endBusStopPath = ShortPath(
                    mapData.getAdjacentMatrix(endVertex.campusNum),
                    endBusStop,
                    endVertex.vertexNum,
                    transmethod);
                lengthSchoolBusEnd = endBusStopPath.getrelativelen();
                routeSchoolBusEnd = endBusStopPath.getroute();
              }
              if (endVertex.vertexNum != endGate) {
                ShortPath endGatePath = ShortPath(
                    mapData.getAdjacentMatrix(endVertex.campusNum),
                    endGate,
                    endVertex.vertexNum,
                    transmethod);
                lengthPublicTransEnd = endGatePath.getrelativelen();
                routePublicTransEnd = endGatePath.getroute();
              }
              DateTime timeAtGetOnPubTrans = routeBeginTime.add(Duration(
                seconds:
                    (naviState.routeLength + lengthPublicTransStart).toInt(),
              ));
              DateTime timeAtGetOnSchoolBus = routeBeginTime.add(Duration(
                  seconds:
                      (naviState.routeLength + lengthSchoolBusStart).toInt()));
              List bestPubTrans = mapData.getBestTimeTable(
                  startVertex.campusNum,
                  endVertex.campusNum,
                  timeAtGetOnPubTrans,
                  onlySchoolBus: false);
              List bestSchoolBus = mapData.getBestTimeTable(
                  startVertex.campusNum,
                  endVertex.campusNum,
                  timeAtGetOnSchoolBus,
                  onlySchoolBus: true);
              if (bestPubTrans.isEmpty && bestSchoolBus.isEmpty) throw '!';
              late String toPrint;
              String startCampusName =
                  mapData.mapCampus[startVertex.campusNum].name;
              String endCampusName =
                  mapData.mapCampus[endVertex.campusNum].name;
              if (bestPubTrans.isEmpty && bestSchoolBus.isNotEmpty) {
                naviState.routeLength += (lengthSchoolBusStart +
                    lengthSchoolBusEnd +
                    (naviState.minTime ? (bestSchoolBus.last as int) * 60 : 0));
                if (routeSchoolBusStart.isNotEmpty)
                  displayRoute(routeSchoolBusStart, startVertex.campusNum);
                if (routeSchoolBusEnd.isNotEmpty)
                  displayRoute(routeSchoolBusEnd, endVertex.campusNum);
                toPrint = (bestSchoolBus.first as BusTimeTable).description;
              } else if (bestPubTrans.isNotEmpty && bestSchoolBus.isEmpty) {
                naviState.routeLength += (lengthPublicTransStart +
                    lengthPublicTransEnd +
                    (naviState.minTime ? (bestPubTrans.last as int) * 60 : 0));
                if (routePublicTransStart.isNotEmpty)
                  displayRoute(routePublicTransStart, startVertex.campusNum);
                if (routePublicTransEnd.isNotEmpty)
                  displayRoute(routePublicTransEnd, endVertex.campusNum);
                toPrint = (bestPubTrans.first as BusTimeTable).description;
              } else {
                if ((lengthSchoolBusStart +
                        lengthSchoolBusEnd +
                        (naviState.minTime
                            ? (bestSchoolBus.last as int) * 60
                            : 0)) >
                    (lengthPublicTransStart +
                        lengthPublicTransEnd +
                        (naviState.minTime
                            ? (bestPubTrans.last as int) * 60
                            : 0))) {
                  naviState.routeLength += (lengthPublicTransStart +
                      lengthPublicTransEnd +
                      (naviState.minTime
                          ? (bestPubTrans.last as int) * 60
                          : 0));
                  if (routePublicTransStart.isNotEmpty)
                    displayRoute(routePublicTransStart, startVertex.campusNum);
                  if (routePublicTransEnd.isNotEmpty)
                    displayRoute(routePublicTransEnd, endVertex.campusNum);
                  toPrint = (bestPubTrans.first as BusTimeTable).description;
                } else {
                  naviState.routeLength += (lengthSchoolBusStart +
                      lengthSchoolBusEnd +
                      (naviState.minTime
                          ? (bestSchoolBus.last as int) * 60
                          : 0));
                  if (routeSchoolBusStart.isNotEmpty)
                    displayRoute(routeSchoolBusStart, startVertex.campusNum);
                  if (routeSchoolBusEnd.isNotEmpty)
                    displayRoute(routeSchoolBusEnd, endVertex.campusNum);
                  toPrint = (bestSchoolBus.first as BusTimeTable).description;
                }
              }
              await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: Text('提示'),
                        content: Text('从$startCampusName移动到$endCampusName，请乘坐' +
                            toPrint +
                            '。'),
                        actions: <Widget>[
                          TextButton(
                            child: Text('取消'),
                            onPressed: () => Navigator.of(context).pop(),

                            ///关闭对话框
                          ),
                        ],
                      ));
            }
          }
          if (i != naviOrder.length - 1) {
            entryRoute(realLatLng, juncLatLng);
            naviState.routeLength += juncLength;
          }
          if (i != 0) {
            entryRoute(juncLatLng, realLatLng);
            naviState.routeLength += juncLength;
          }
        }
        if (logEnabled)
          logSink.write(
              DateTime.now().toString() + ': 类型转换与狄杰斯特拉算法结束，路线计算函数正常结束。\n');
      } catch (_) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text('提示'),
                  content: Text('未找到路线。请检查地图数据。'),
                  actions: <Widget>[
                    TextButton(
                      child: Text('取消'),
                      onPressed: () => Navigator.of(context).pop(), //关闭对话框
                    ),
                  ],
                ));
        if (logEnabled)
          logSink.write(DateTime.now().toString() + ': 未找到路线。停止导航。\n');
        //路线绘制出现错误，将导航状态设为停止同时清空路线和长度
        naviState.naviStatus = false;
        mapPolylines.clear();
        naviState.routeLength = 0;
      }
    } else {
      if (logEnabled) logSink.write(DateTime.now().toString() + ': 停止导航。\n');
    }
  }

  ///从LatLng类型或者Building类型中获取标志位置
  static LatLng getLocation(dynamic element) {
    if (element.runtimeType == LatLng)
      return element;
    else
      return (element as Building).getApproxLocation();
  }
}

///用于进行多次狄杰斯特拉算法的单元
class NaviLoc {
  ///点所在校区编号
  late int campusNum;

  ///点在校区中点集的编号
  late int vertexNum;

  ///点的特征坐标
  late LatLng location;

  ///构造函数
  NaviLoc(this.campusNum, this.vertexNum, this.location);
}

///逻辑位置类
class LogicLoc {
  ///逻辑位置：建筑名与建筑别名列表的字典
  Map<String, List<String>> logicLoc = {};

  ///默认构建函数，构造空逻辑位置表
  LogicLoc();

  LogicLoc.fromJson(Map<String, dynamic> json) {
    Map logicLocJson = json['logicLoc'] as Map;
    logicLocJson.forEach((key, value) {
      logicLoc[key] = List<String>.from(value);
    });
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'logicLoc': logicLoc,
    };
  }
}

///食堂负载均衡类
class CanteenArrange {
  ///到食堂的时间
  late double pathtime;

  ///到食堂时的人数
  late int result;

  ///食堂最大人数
  static const int capacity = 150;

  ///食堂负载与每30秒进入人数的字典
  static const Map<int, int> ntovin = {1: 1, 2: 3, 3: 2};

  ///食堂负载与每30秒离开人数的字典
  static const Map<int, int> ntovout = {1: 0, 2: 1, 3: 2};

  ///负载均衡构建函数，将随机一个当前食堂人数，计算预计到达时的食堂人数
  CanteenArrange(this.pathtime) {
    int flowin, flowout;
    int number = Random().nextInt(150);
    for (double i = 0; i <= pathtime; i += 30) {
      int tmp = 0;

      if (number / capacity <= 0.25) {
        tmp = 1;
      } else if (number / capacity <= 0.75) {
        tmp = 2;
      } else
        tmp = 3;
      var fin = ntovin[tmp] ?? 0;
      flowin = fin;
      var fout = ntovout[tmp] ?? 0;
      flowout = fout;
      number = number + flowin - flowout;
    }
    result = number;
  }

  ///获取预计用餐时间
  double getTime() {
    if (result > capacity)
      return double.infinity;
    else
      return 12 * result + pathtime;
  }

  ///获取到达时食堂负载百分比
  double getPayload() {
    return (result / capacity) * 100;
  }
}

///用户设置
late SharedPreferences prefs;

///地图数据
late MapData mapData;

///逻辑位置
late LogicLoc mapLogicLoc;

///导航状态
NaviState naviState = NaviState();

///地图Marker
Map<String, Marker> mapMarkers = {};

///地图直线
List<Polyline> mapPolylines = [];

///地图控制器
AMapController? mapController;

///用户位置
AMapLocation userLocation = AMapLocation(latLng: LatLng(39.909187, 116.397451));

///定位权限状态
PermissionStatus locatePermissionStatus = PermissionStatus.denied;

///日志开关
late bool logEnabled;

///日志文件
late File logFile;

///日志写IOSink
late IOSink logSink;
