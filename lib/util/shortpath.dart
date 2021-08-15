import 'package:campnavi/global/global.dart';
import 'package:campnavi/model/edge.dart';

///最短路径类，输入路径矩阵和起点，终点，交通类型，得到一条最短路径。
class ShortPath {
  ///起始点ID
  final int startVertexID;

  ///终点ID
  final int endVertexID;

  ///运动方式
  final int transMethod;

  ///路径集
  List<int> route = [];

  ///路径的相对长度
  late double relativeLen;

  ///给出一个边，计算它的相对长度，受拥挤度和出行方式的影响
  ///距离等于实际距离乘上骑车加速系数的积除以拥挤度
  double pathLength(Edge edge) {
    return (edge.length *
            (transMethod == 1 && edge.availmthod == 1 ? BIKESPEED : 1)) /
        edge.crowding;
  }

  ///核心构造函数，读入一个记录着地图边信息的邻接矩阵，以及起点和终点信息。构建出一条最短路径，
  ///通过该构建方法构建出来一个实例的同时，也就获得了一条最短路径
  ShortPath(List<List<Edge>> mapMatrix, this.startVertexID, this.endVertexID,
      this.transMethod) {
    List<int> points = List.filled(mapMatrix.length, -1);
    //节点集，存放已经决定的最短路径的节点号,初始全为-1
    List<double> dist = List.filled(mapMatrix.length, double.infinity);
    //记录各点到起点的距离
    List<int> path = List.filled(mapMatrix.length, -1);
    //存放各个节点到起点的路径的前驱。
    double min;
    //最小值，之后计算使用
    int pointTemp = -1;
    //不确定赋值
    for (int i = 0; i < mapMatrix.length; ++i) {
      if (mapMatrix[startVertexID][i].availmthod >= 0) {
        dist[i] = pathLength(mapMatrix[startVertexID][i]);
        path[i] = startVertexID;
      }
    }
    //初始化各节点到起点的距离
    points[startVertexID] = 0;
    dist[startVertexID] = 0;
    //加入起点，开始将点加入节点集
    for (int i = 0; i < mapMatrix.length; ++i) {
      //对节点集进行扩充
      min = double.infinity;
      for (int j = 0; j < mapMatrix.length; ++j) {
        if ((points[j] == -1) && (dist[j] < min)) {
          min = dist[j];
          pointTemp = j;
        }
      }
      points[pointTemp] = 1;
      for (int j = 0; j < mapMatrix.length; ++j) {
        //重新调成起点到各个节点间的最短距离
        if ((points[j] == -1) &&
            (dist[j] > dist[pointTemp] + pathLength(mapMatrix[pointTemp][j]))) {
          dist[j] = dist[pointTemp] + pathLength(mapMatrix[pointTemp][j]);
          path[j] = pointTemp;
        }
      }
      if (pointTemp == endVertexID) {
        break;
        //如果已经到达出口，则退出循环
      }
    }
    if (path[endVertexID] == -1) {
      route.clear();
      //清空
      relativeLen = double.infinity;
    }
    //发现如何都到不了终点。
    else {
      relativeLen = dist[pointTemp];
      route.add(endVertexID);
      int pre = path[endVertexID];
      while (pre != startVertexID) {
        route.add(pre);
        pre = path[pre];
      }
      route.add(startVertexID);
      //通过前缀把路径从终点到起点加入
    }
  }

  ///返回最短路径，该路径由一个地图点集来定义，即该路径上的所有点。
  List<int> getRoute() {
    return route.reversed.toList();
  }

  ///返回计算得到的最短路径的长度
  double getRelativeLen() {
    return relativeLen;
  }
}
