import 'dart:io';
import 'dart:math';

import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    doors.forEach((element) {
      latall += element.latitude;
      lngall += element.longitude;
    });
    return LatLng(latall / doors.length, lngall / doors.length);
  }

  ///通过json创建对象
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

  ///通过对象创建json
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

///边类,道路上两点构成的边，存储两点在点集中的角标
class Edge {
  ///道路两点
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

  ///从json中创建对象
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'pointa': pointa,
      'pointb': pointb,
      'length': length,
      'availmthod': availmthod,
    };
  }

  ///由对象生成json
  Edge.fromJson(Map<String, dynamic> json) {
    pointa = json['pointa'] as int? ?? -1;
    pointb = json['pointb'] as int? ?? -1;
    length = json['length'] as double? ?? double.infinity;
    availmthod = json['availmthod'] as int? ?? -1;
  }
}

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
    campusShapeJson.forEach((element) {
      campusShape.add(latLngfromJson(element));
    });
    gate = json['gate'] as int? ?? 0;
    busstop = json['busstop'] as int? ?? 0;
    name = json['name'] as String? ?? '校区';
    List listBuildingJson = json['listBuilding'] as List;
    listBuildingJson.forEach((element) {
      listBuilding.add(Building.fromJson(element));
    });
    List listVertexJson = json['listVertex'] as List;
    listVertexJson.forEach((element) {
      listVertex.add(latLngfromJson(element));
    });
    List listEdgeJson = json['listEdge'] as List;
    listEdgeJson.forEach((element) {
      listEdge.add(Edge.fromJson(element));
    });
    listEdge.forEach((curEdge) {
      if (curEdge.availmthod >= 0 && curEdge.length == double.infinity) {
        curEdge.length = AMapTools.distanceBetween(
            listVertex[curEdge.pointa], listVertex[curEdge.pointb]);
      }
    });
  }

  ///通过对象创建json
  Map<String, dynamic> toJson() {
    List campusShapeJson = [];
    campusShape.forEach((element) {
      campusShapeJson.add(latLngtoJson(element));
    });
    List listVertexJson = [];
    listVertex.forEach((element) {
      listVertexJson.add(latLngtoJson(element));
    });
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
      listEdge.forEach((element) {
        element.crowding = 1.0 - Random().nextDouble();
      });
      crowded = true;
    }
  }

  ///关闭拥挤度
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

  ///通过json创建对象
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

  ///通过对象创建json
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

  ///校车时间表
  List<BusTimeTable> busTimeTable = [];

  MapData();

  MapCampus operator [](int index) {
    return mapCampus[index];
  }

  ///从json对象中读取
  MapData.fromJson(Map<String, dynamic> json) {
    List mapCampusJson = json['mapCampus'] as List;
    mapCampusJson.forEach((element) {
      mapCampus.add(MapCampus.fromJson(element));
    });
    List busTimeTableJson = json['busTimeTable'] as List;
    busTimeTableJson.forEach((element) {
      busTimeTable.add(BusTimeTable.fromJson(element));
    });
  }

  ///生成json对象
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mapCampus': mapCampus,
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

  ///判断某建筑building所属校区
  int buildingInCampus(Building building) {
    for (int i = 0; i < mapCampus.length; ++i) {
      if (mapCampus[i].listBuilding.contains(building)) return i;
    }
    return -1;
  }

  ///由校区campusNum的边集构造边二维邻接矩阵
  List<List<Edge>> getAdjacentMatrix(int campusNum) {
    List<Edge> listEdge = mapCampus[campusNum].listEdge;
    int squareSize = mapCampus[campusNum].listVertex.length;
    List<List<Edge>> tmp = List.generate(
        squareSize, (_) => List.generate(squareSize, (_) => Edge()));
    listEdge.forEach((element) {
      tmp[element.pointa][element.pointb] = element;
      tmp[element.pointb][element.pointa] = element;
    });
    return tmp;
  }

  ///获取距离点location最近的导航点编号
  int nearestVertex(int campusNum, LatLng location) {
    List<LatLng> listVertex = mapCampus[campusNum].listVertex;
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

  ///获取校区campusNum中编号为vertexNum的点的坐标
  LatLng getVertexLatLng(int campusNum, int vertexNum) {
    return mapCampus[campusNum].listVertex[vertexNum];
  }

  ///随机拥挤度函数
  void randomCrowding() {
    mapCampus.forEach((element) {
      if (!element.crowded) {
        element.listEdge.forEach((element1) {
          element1.crowding = 1.0 - Random().nextDouble();
        });
        element.crowded = true;
      }
    });
  }

  ///关闭拥挤度
  void disableCrowding() {
    mapCampus.forEach((element) {
      if (element.crowded) {
        element.listEdge.forEach((element2) {
          element2.crowding = 1;
        });
        element.crowded = false;
      }
    });
  }

  ///当跨校区导航时，获取距离当前时间最近的交通工具时间表
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
      if (element.setOutHour >= 0 && element.setOutHour < 24) {
        if (element.setOutHour < timeAtGetOn.hour)
          return;
        else
          thisTakenTime += (element.setOutHour - timeAtGetOn.hour) * 60;
      }
      if (element.setOutMinute >= 0 && element.setOutMinute < 60) {
        if (element.setOutMinute < timeAtGetOn.minute)
          return;
        else
          thisTakenTime += element.setOutMinute - timeAtGetOn.minute;
      }
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
  ///导航状态
  bool naviStatus = false;

  ///是否启用拥挤度
  bool crowding = false;

  ///是否骑车
  bool onbike = false;

  ///是否以用户位置为起点
  bool startOnUserLoc = false;

  ///是否实时导航
  bool realTime = false;

  ///是够使用最短时间策略
  bool minTime = false;

  ///起点
  dynamic start;

  ///终点集合
  List end = [];

  ///路径相对长度
  double routeLength = 0;

  ///默认构造函数
  NaviState();

  ///获取起点对应的widget
  Widget getStartWidget(void Function(void Function()) setState) {
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
  Widget getEndWidget(void Function(void Function()) setState) {
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
    List<LatLng> listvertex = mapData[campusNum].listVertex;
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
  static List<LatLng> circleAround(LatLng center, int rad) {
    ///近似圆的顶点数量
    const int times = 36;

    ///多边形的点数
    Offset res = Offset(center.latitude, center.longitude);
    List<LatLng> circlelist = [];
    for (int i = 0; i < times; ++i) {
      Offset c = Offset.fromDirection(
          i * 2 * pi / times, 180 * rad / pi / 6371 / 1000);
      Offset c1 = Offset(
          res.dx + c.dx, res.dy + c.dy / cos((res.dx + c.dx) / 180 * pi));

      circlelist.add(LatLng(c1.dx, c1.dy));
    }
    return circlelist;
  }

  ///检查定位是否正常，检查定位权限和用户坐标，如果没有定位权限或者用户位置时间戳为0则提示
  static bool stateLocationReqiurement(BuildContext context) {
    ///用户关闭了定位开关
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
                  ),
                  TextButton(
                    child: Text('确定'),
                    onPressed: () async {
                      locatePermissionStatus =
                          await Permission.location.request();
                      Navigator.of(context).pop();
                    },
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
                  ),
                ],
              ));
      return false;
    } else {
      return true;
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

  ///从json对象中读取
  LogicLoc.fromJson(Map<String, dynamic> json) {
    Map logicLocJson = json['logicLoc'] as Map;
    logicLocJson.forEach((key, value) {
      logicLoc[key] = List<String>.from(value);
    });
  }

  ///生成json对象
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

///软件信息
late PackageInfo packageInfo;
