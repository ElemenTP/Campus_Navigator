//mport 'dart:convert';
import 'dart:math';
//import 'dart:io';

import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart'; //LatLng 类型在这里面

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

//建筑类定义
class Building {
  //入口集，坐标编号
  List<int> doors = [];
  //描述集
  List<String> description = [];
  //校区编号
  int incampus = 0;
  //*TODO
}

class MapCampus {
  List<LatLng> campusShape = [];
  int gate = 0;
  int busstop = 0;
  String name = 'My Campus';
  //*TODO
}

//边类及构造函数
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
  //随机拥挤度函数
  randomCrowding() {
    this.crowding = Random().nextDouble();
  }

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

//校车时间表类
class BusTimeTable {
  //始发校区编号
  int campusfrom = 0;
  //目的校区编号
  int campusto = 0;
  //出发时间的时
  int setouthour = 0;
  //出发时间的分
  int setoutminute = 0;
  //星期几？1-7，7是周日
  int dayofweek = 1;
  BusTimeTable();
  //Map<String, dynamic> toJson() {
  //return
  //}
  //*TODO
}

class MapData {
  //校区与编号的对应表
  List<MapCampus> listCampus = [];
  //建筑列表
  List<Building> listbuilding = [];
  //点与编号对应表
  List<Map<int, LatLng>> mapvertex = [];
  //边与地图结构数据，按校区分成多个
  List<List<List<Edge>>> mapedge = [];
  //校车时间表
  BusTimeTable busTimeTable = BusTimeTable();
  //*TODO
}

class NaviState {
  bool naviStatus = false;
  int? startVertex;
  List<int> endVertex = [];

  NaviState();

  reverseState() {
    naviStatus = !naviStatus;
  }
}

//地图数据
late MapData mapData;

//导航状态
NaviState navistate = NaviState();

//地图控制器
AMapController? mapController;

//用户位置
AMapLocation userPosition = AMapLocation(latLng: LatLng(39.909187, 116.397451));
