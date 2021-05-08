import 'dart:math';
import 'dart:io';

LatLng zeropoint = new LatLng(0, 0);
LatLng limitpoint = new LatLng(0, 90);
Edge invalidEdge = Edge(zeropoint, limitpoint);

class LatLng {
  double latitude = 0;
  double longitude = 0;
  LatLng(double la, double lo) {
    this.latitude = la;
    this.longitude = lo;
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
  int campusfrom = 0;
  //目的校区编号
  int campusto = 0;
  //出发时间的时
  int setouthour = 0;
  //出发时间的分
  int setoutminute = 0;
  //星期几？0-6，0是周日
  int dayofweek = 0;
}

class MapData {
  //校区与编号的对应表
  Map<int, String> mapcampus = {};
  //建筑列表
  List<Building> mapbuilding = [];
  //点与编号对应表
  List<Map<int, LatLng>> mapvertex = [];
  //边与地图结构数据，按校区分成多个
  List<List<List<Edge>>> mapedge = [];
  //校车时间表
  List<BusTimeTable> mapbustimetable = [];
}

MapData dataInput(String path) {
  final inputfile = File(path);
  List<String> lines = inputfile.readAsLinesSync();
  MapData inputData = new MapData();
  inputData.mapcampus = campusInput(lines[0]);
  inputData.mapvertex = pointsInput(lines[1]);
  inputData.mapbustimetable = bustableInput(lines[3]);
  inputData.mapedge = edgesInput(lines[2], inputData.mapvertex);
  List<String> tmpLines = [lines[4], lines[5], lines[6]];
  inputData.mapbuilding = buildingInput(tmpLines);
  return inputData;
}

//校区数据导入
Map<int, String> campusInput(String line) {
  List<String> name = line.split(',');
  List<int> number = List.generate(name.length, (index) => index);
  Map<int, String> campusMap = Map.fromIterables(number, name);
  return campusMap;
}

//点集导入
List<Map<int, LatLng>> pointsInput(String line) {
  List<String> tmpStr = line.split(';');
  List<Map<int, LatLng>> pointsList = [];
  for (int i = 0; i < tmpStr.length; i++) {
    List<String> points = tmpStr[i].split(',');
    List<LatLng> latlngsList = [];
    for (int j = 0; j < points.length / 2; j++) {
      LatLng tmp = new LatLng(
          double.parse((points[j * 2])), double.parse((points[j * 2 + 1])));
      latlngsList.add(tmp);
    }
    List<int> number = List.generate(latlngsList.length, (index) => index);
    Map<int, LatLng> latlngsMap = Map.fromIterables(number, latlngsList);
    pointsList.add(latlngsMap);
  }
  return pointsList;
}

//边集导入
List<List<List<Edge>>> edgesInput(
    String line, List<Map<int, LatLng>> latlngsMap) {
  List<String> tmpStr = line.split(';');
  List<List<List<Edge>>> edgeMatrix = [];
  for (int i = 0; i < tmpStr.length; i++) {
    List<List<Edge>> tmpList = [];
    List<String> tmpStr2 = tmpStr[i].split(',');
    for (int j = 0; j < latlngsMap[i].length; j++) {
      List<Edge> tmp = [];
      for (int k = 0; k < latlngsMap[i].length; k++) {
        tmp.add(invalidEdge);
      }
      tmpList.add(tmp);
    }
    edgeMatrix.add(tmpList);
  }
  //print(edgeMatrix[0].length);
  //print(edgeMatrix[1].length);

  for (int i = 0; i < tmpStr.length; i++) {
    List<String> edgesStr = tmpStr[i].split(',');
    //print(edgesStr.length);
    LatLng xpoint = new LatLng(-1, -1);
    for (int j = 0; j < edgesStr.length ~/ 2; j++) {
      LatLng point1 = latlngsMap[i][int.parse(edgesStr[j * 2])] ?? xpoint;
      LatLng point2 = latlngsMap[i][int.parse(edgesStr[j * 2 + 1])] ?? xpoint;

      //if (i == 0) {
      //print(edgesStr.length);
      //print('${point1.latitude}, ${point1.longitude}');
      //print('${point2.latitude}, ${point2.longitude}');
      //}

      if (point1 == xpoint || point2 == xpoint) {
        //throw an exception
      }
      Edge tmp = new Edge(point1, point2);

      //print(int.parse(edgesStr[j * 2]));
      //print(int.parse(edgesStr[j * 2 + 1]));

      edgeMatrix[i][int.parse(edgesStr[j * 2])]
          [int.parse(edgesStr[j * 2 + 1])] = tmp;
    }
  }

  return edgeMatrix;
}
//校车数据导入

List<BusTimeTable> bustableInput(String line) {
  List<String> bustableStr = line.split(',');
  List<BusTimeTable> bustableList = [];
  for (int i = 0; i < bustableStr.length ~/ 3; i++) {
    BusTimeTable tmp = new BusTimeTable();
    tmp.campusfrom = int.parse(bustableStr[i * 3]);
    //*TODO exception
    tmp.campusto = int.parse(bustableStr[i * 3 + 1]);
    int timeinfo = int.parse(bustableStr[i * 3 + 2]);
    tmp.dayofweek = timeinfo ~/ 10000;
    //*TODO exception
    tmp.setoutminute = timeinfo % 100;
    tmp.setouthour = timeinfo ~/ 100 % 100;
    bustableList.add(tmp);
  }
  return bustableList;
}

//建筑集导入
List<Building> buildingInput(List<String> line) {
  List<String> descripStr = line[0].split(';');
  List<List<String>> descripList = [];
  for (int i = 0; i < descripStr.length; i++) {
    List<String> tmpStr = descripStr[i].split(',');
    List<String> tmpList = [];
    for (int j = 0; j < tmpStr.length; j++) {
      tmpList.add(tmpStr[j]);
    }
    descripList.add(tmpList);
  }
  //print(descrip_list);
  List<String> entryStr = line[1].split(';');
  List<List<int>> entryList = [];
  for (int i = 0; i < entryStr.length; i++) {
    List<String> tmpStr = entryStr[i].split(',');
    List<int> tmpList = [];
    for (int j = 0; j < tmpStr[j].length; j++) {
      tmpList.add(int.parse(tmpStr[j]));
    }
    entryList.add(tmpList);
  }

  //print(entry_list);

  List<String> numberStr = line[2].split(',');
  List<int> numberList = [];
  for (int i = 0; i < numberStr.length; i++) {
    numberList.add(int.parse(numberStr[i]));
  }

  //print(number_list);
  List<Building> buildList = [];
  for (int i = 0; i < descripStr.length; i++) {
    Building tmp = new Building();
    tmp.doors = entryList[i];
    tmp.description = descripList[i];
    tmp.incampus = numberList[i];

    buildList.add(tmp);
  }

  return buildList;
}
