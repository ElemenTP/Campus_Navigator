import 'package:amap_flutter_base/amap_flutter_base.dart'; //LatLng 类型在这里面
import 'dart:math';
import 'dart:io';

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
  toRandomCrowding() {
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
  //校区与编号的对应表
  Map<int, String> mapcampus;
  //建筑列表
  List<Building> mapbuilding;
  //点与编号对应表
  List<Map<int, LatLng>> mapvertex;
  //边与地图结构数据，按校区分成多个
  List<List<List<Edge>>> mapedge;
  //校车时间表
  List<BusTimeTable> mapbustimetable;
}

MapData dataInput(String path) {
  final inputfile = File(path);
  List<String> lines = inputfile.readAsLinesSync();
  MapData inputData = new MapData();
  inputData.mapcampus = campusInput(lines[0]);
  inputData.mapvertex = pointsInput(lines[1]);
  inputData.mapbustimetable = bustableInput(lines[3]);
  inputData.mapedge = edgesInput(lines[2], inputData.mapvertex);
  List<String> tmp_lines = [lines[4], lines[5], lines[6]];
  inputData.mapbuilding = buildingInput(tmp_lines);
  return inputData;
}

//校区数据导入
Map<int, String> campusInput(String line) {
  List<String> name = line.split(',');
  List<int> number = List.generate(name.length, (index) => index);
  Map<int, String> campus_map = Map.fromIterables(number, name);
  return campus_map;
}

//点集导入
List<Map<int, LatLng>> pointsInput(String line) {
  List<String> tmp_str = line.split(';');
  List<Map<int, LatLng>> points_list = [];
  for (int i = 0; i < tmp_str.length; i++) {
    List<String> points = tmp_str[i].split(',');
    List<LatLng> latlngs_list = [];
    for (int j = 0; j < points.length / 2; j++) {
      LatLng tmp = new LatLng(
          double.parse((points[j * 2])), double.parse((points[j * 2 + 1])));
      latlngs_list.add(tmp);
    }
    List<int> number = List.generate(latlngs_list.length, (index) => index);
    Map<int, LatLng> latlngs_map = Map.fromIterables(number, latlngs_list);
    points_list.add(latlngs_map);
  }
  return points_list;
}

//边集导入
List<List<List<Edge>>> edgesInput(
    String line, List<Map<int, LatLng>> latlngs_map) {
  List<String> tmp_str = line.split(';');
  List<List<List<Edge>>> edge_matrix = [];
  LatLng testpoint = new LatLng(-1, -1);
  for (int i = 0; i < tmp_str.length; i++) {
    List<List<Edge>> tmp_list = [];
    List<String> tmp_str2 = tmp_str[i].split(',');
    for (int j = 0; j < tmp_str2.length; j++) {
      List<Edge> tmp = [];
      for (int k = 0; k < tmp_str2.length; k++) {
        tmp.add(Edge(testpoint, testpoint));
      }
      tmp_list.add(tmp);
    }
    edge_matrix.add(tmp_list);
  }
  print(edge_matrix[0].length);
  print(edge_matrix[1].length);

  for (int i = 0; i < tmp_str.length; i++) {
    List<String> edges_str = tmp_str[i].split(',');
    LatLng xpoint = new LatLng(-1, -1);
    for (int j = 0; j < edges_str.length ~/ 2; j++) {
      LatLng point1 = latlngs_map[i][int.parse(edges_str[j * 2])] ?? xpoint;
      LatLng point2 = latlngs_map[i][int.parse(edges_str[j * 2 + 1])] ?? xpoint;

      if (point1 == xpoint || point2 == xpoint) {
        //throw an exception
      }
      Edge tmp = new Edge(point1, point2);
      //print(int.parse(edges_str[j * 2]));
      //print(int.parse(edges_str[j * 2 + 1]));
      edge_matrix[i][int.parse(edges_str[j * 2])]
          [int.parse(edges_str[j * 2 + 1])] = tmp;
    }
  }

  return edge_matrix;
}
//校车数据导入

List<BusTimeTable> bustableInput(String line) {
  List<String> bustable_str = line.split(',');
  List<BusTimeTable> bustable_list = [];
  for (int i = 0; i < bustable_str.length ~/ 3; i++) {
    BusTimeTable tmp = new BusTimeTable();
    tmp.campusfrom = int.parse(bustable_str[i * 3]);
    //*TODO exception
    tmp.campusto = int.parse(bustable_str[i * 3 + 1]);
    int timeinfo = int.parse(bustable_str[i * 3 + 2]);
    tmp.dayofweek = timeinfo ~/ 10000;
    //*TODO exception
    tmp.setoutminute = timeinfo % 100;
    tmp.setouthour = timeinfo ~/ 100 % 100;
    bustable_list.add(tmp);
  }
  return bustable_list;
}

//建筑集导入
List<Building> buildingInput(List<String> line) {
  List<String> descrip_str = line[0].split(';');
  List<List<String>> descrip_list = [];
  for (int i = 0; i < descrip_str.length; i++) {
    List<String> tmp_str = descrip_str[i].split(',');
    List<String> tmp_list = [];
    for (int j = 0; j < tmp_str.length; j++) {
      tmp_list.add(tmp_str[j]);
    }
    descrip_list.add(tmp_list);
  }
  //print(descrip_list);
  List<String> entry_str = line[1].split(';');
  List<List<int>> entry_list = [];
  for (int i = 0; i < entry_str.length; i++) {
    List<String> tmp_str = entry_str[i].split(',');
    List<int> tmp_list = [];
    for (int j = 0; j < tmp_str[j].length; j++) {
      tmp_list.add(int.parse(tmp_str[j]));
    }
    entry_list.add(tmp_list);
  }

  //print(entry_list);

  List<String> number_str = line[2].split(',');
  List<int> number_list = [];
  for (int i = 0; i < number_str.length; i++) {
    number_list.add(int.parse(number_str[i]));
  }

  //print(number_list);
  List<Building> build_list = [];
  for (int i = 0; i < descrip_str.length; i++) {
    Building tmp = new Building();
    tmp.doors = entry_list[i];
    tmp.description = descrip_list[i];
    tmp.incampus = number_list[i];

    build_list.add(tmp);
  }

  return build_list;
}
