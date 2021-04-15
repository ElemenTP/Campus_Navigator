import 'package:amap_flutter_base/amap_flutter_base.dart'; //LatLng 类型在这里面
import 'dart:math';

//建筑类定义
class Building {
  //入口集，坐标编号
  List<int> doors = [];
  //描述集
  List<String> description = [];
  //校区编号
  int incampus = 0;
}

//边类及构造函数
class Edge {
  //边长度，建造函数自动生成
  double length = double.infinity;
  //边适应性，默认可骑车
  int availmthod = 1;
  //边拥挤度，需要时调用随机方法生成。
  double crowding = 1;
//构造函数
  Edge(LatLng pointa, LatLng pointb, {int availmthod = 1}) {
    var p = 0.017453292519943295;
    var c = cos;
    this.length = 0.5 -
        c((pointb.latitude - pointa.latitude) * p) / 2 +
        c(pointa.latitude * p) *
            c(pointb.latitude * p) *
            (1 - c((pointb.longitude - pointa.longitude) * p)) /
            2;
    this.availmthod = availmthod;
  }
//随机函数
  RandomCrowding() {
    crowding = Random().nextDouble();
  }
}

//校车时间表类
class BusTimeTable {
  //始发校区编号
  int campusfrom;
  //目的校区编号
  int campusto;
  //出发时间的时
  int setouthour;
  //出发时间的分
  int setoutminute;
  //星期几？0-6，0是周日
  int dayofweek;
}

class MapData {
  Map<int, String> mapcampus;
  List<Building> mapbuilding;
  Map<int, LatLng> mapvertex;
  List<List<List<Edge>>> mapedge;
  List<BusTimeTable> mapbustimetable;
}
