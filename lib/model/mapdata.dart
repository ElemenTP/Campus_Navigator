import 'dart:math';

import 'package:amap_flutter_base/amap_flutter_base.dart';

import 'mapcampus.dart';
import 'building.dart';
import 'bustimetable.dart';
import 'edge.dart';

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
    for (var element in mapCampusJson) {
      mapCampus.add(MapCampus.fromJson(element));
    }
    List busTimeTableJson = json['busTimeTable'] as List;
    for (var element in busTimeTableJson) {
      busTimeTable.add(BusTimeTable.fromJson(element));
    }
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
      if (AMapTools.latLngIsInPolygon(location, mapCampus[i].campusShape)) {
        return i;
      }
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
    for (Edge element in listEdge) {
      tmp[element.pointa][element.pointb] = element;
      tmp[element.pointb][element.pointa] = element;
    }
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
    for (MapCampus element in mapCampus) {
      if (!element.crowded) {
        for (Edge element1 in element.listEdge) {
          element1.crowding = 1.0 - Random().nextDouble();
        }
        element.crowded = true;
      }
    }
  }

  ///关闭拥挤度
  void disableCrowding() {
    for (MapCampus element in mapCampus) {
      if (element.crowded) {
        for (Edge element2 in element.listEdge) {
          element2.crowding = 1;
        }
        element.crowded = false;
      }
    }
  }

  ///当跨校区导航时，获取距离当前时间最近的交通工具时间表
  List getBestTimeTable(int campusFrom, int campusTo, DateTime timeAtGetOn,
      {bool? onlySchoolBus}) {
    BusTimeTable? target;
    int takenTime = 114514;
    for (BusTimeTable element in busTimeTable) {
      if (onlySchoolBus != null && onlySchoolBus ^ element.isSchoolBus) {
        break;
      }
      if (element.campusFrom != campusFrom || element.campusTo != campusTo) {
        break;
      }
      if (element.dayOfWeek > 0 &&
          element.dayOfWeek < 8 &&
          element.dayOfWeek != timeAtGetOn.weekday) {
        break;
      }
      int thisTakenTime = 0;
      if (element.setOutHour >= 0 && element.setOutHour < 24) {
        if (element.setOutHour < timeAtGetOn.hour) {
          break;
        } else {
          thisTakenTime += (element.setOutHour - timeAtGetOn.hour) * 60;
        }
      }
      if (element.setOutMinute >= 0 && element.setOutMinute < 60) {
        if (element.setOutMinute < timeAtGetOn.minute) {
          break;
        } else {
          thisTakenTime += element.setOutMinute - timeAtGetOn.minute;
        }
      }
      thisTakenTime += element.takeTime;
      if (thisTakenTime < takenTime) {
        target = element;
        takenTime = thisTakenTime;
      }
    }
    if (target == null) {
      return [];
    } else {
      return [target, takenTime];
    }
  }
}
