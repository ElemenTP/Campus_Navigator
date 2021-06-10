import 'header.dart';

///最短路径类，输入路径矩阵和起点，终点，交通类型，得到一条路径
class ShortPath {
  ///起始点ID
  final int startvertexID;

  ///终点ID
  final int endvertexID;

  ///运动方式
  final int transmethod;

  ///路径集
  List<int> route = [];

  ///路径的相对长度
  late double relativelen;

  ///给出一个边，计算它的相对长度，受拥挤度和出行方式的影响
  double pathlength(Edge edge, int transmethod) {
    return (edge.length * (transmethod == 1 ? BIKESPEED : 1)) / edge.crowding;
  }

  ///距离等于实际距离乘上骑车加速系数的积除以拥挤度
  ShortPath(List<List<Edge>> mapmatrix, this.startvertexID, this.endvertexID,
      this.transmethod) {
    List<int> points =
        List.filled(mapmatrix.length, -1); //节点集，存放已经决定的最短路径的节点号,初始全为-1
    List<double> dist =
        List.filled(mapmatrix.length, double.infinity); //记录各点到起点的距离
    List<int> path = List.filled(mapmatrix.length, -1); //存放各个节点到起点的路径的前驱。
    double min; //最小值，之后计算使用
    int pointTemp = -1; //不确定赋值
    for (int i = 0; i < mapmatrix.length; ++i) {
      if (mapmatrix[startvertexID][i].availmthod >= transmethod) {
        dist[i] = pathlength(mapmatrix[startvertexID][i], transmethod);
        path[i] = startvertexID;
      }
    } //初始化各节点到起点的距离
    points[startvertexID] = 0;
    dist[startvertexID] = 0; //加入起点，开始将点加入节点集
    for (int i = 0; i < mapmatrix.length; ++i) {
      //对节点集进行扩充
      min = double.infinity;
      for (int j = 0; j < mapmatrix.length; ++j) {
        if ((points[j] == -1) && (dist[j] < min)) {
          min = dist[j];
          pointTemp = j;
        }
      }
      points[pointTemp] = 1;
      for (int j = 0; j < mapmatrix.length; ++j) {
        //重新调成起点到各个节点间的最短距离
        if ((points[j] == -1) &&
            (dist[j] >
                dist[pointTemp] +
                    pathlength(mapmatrix[pointTemp][j], transmethod))) {
          dist[j] = dist[pointTemp] +
              pathlength(mapmatrix[pointTemp][j], transmethod);
          path[j] = pointTemp;
        }
      }
      if (pointTemp == endvertexID) {
        break; //如果已经到达出口，则退出循环
      }
    }
    if (path[endvertexID] == -1) {
      route.clear(); //清空
      relativelen = double.infinity;
    } //发现如何都到不了终点。
    else {
      relativelen = dist[pointTemp];
      route.add(endvertexID);
      int pre = path[endvertexID];
      while (pre != startvertexID) {
        route.add(pre);
        pre = path[pre];
      }
      route.add(startvertexID);
      //通过前缀把路径从终点到起点加入
    }
  }
  List<int> getroute() {
    return route.reversed.toList();
  }

  double getrelativelen() {
    return relativelen;
  }
}
