//import 'dart:html';
//import 'dart:math';
//import 'dart:ui';

import 'header.dart';
//import 'package:flutter/material.dart';

class Shortpath //最短路径类，输入路径矩阵和起点，终点，运动类型，得到一条路径
{
  final double maxnum = double.infinity;
  final double onBike = 0.5; //骑车使得道路打折的倍数（小于一）
  int startvertexID; //起始点ID
  int endvertexID; //终点ID
  int transmethod; //运动方式
  List<int> route; //路径集
  double relativelen; //路径的相对长度
  double pathlength(List<List<Edge>> mapmatrix, int i, int j, int transmethod) {
    return (mapmatrix[startvertexID][i].length -
            mapmatrix[startvertexID][i].length * (transmethod * this.onBike)) /
        mapmatrix[startvertexID][i].crowding;
  } //给出矩阵上的一个边，计算它的长度，受拥挤度和出行方式的影响

  //距离等于实际距离乘上骑车加速系数的积除以拥挤度
  Shortpath(List<List<Edge>> mapmatrix, int startvertexID, int endvertexID,
      int transmethod) {
    if (transmethod == 1) {
      for (int i = 0; i < mapmatrix.length; i++) {
        for (int j = 0; j < mapmatrix[i].length; j++) {
          if (mapmatrix[i][j].availmthod == 0) {
            mapmatrix[i][j] = null;
          }
        }
      }
    } //如果运动方式是骑车的话，就遍历一遍矩阵，把仅能步行的边全部去除。

    /*-------------------------------------------------------------------*/
    List<int> points = List.generate(mapmatrix.length, (_) => -1,
        growable: false); //节点集，存放已经决定的最短路径的节点号,初始全为-1
    List<double> dist = List.generate(mapmatrix.length, (_) => maxnum,
        growable: false); //记录各点到起点的距离
    List<int> path = List.generate(mapmatrix.length, (_) => -1,
        growable: false); //存放各个节点到起点的路径的前驱。
    double min; //最小值，之后计算使用
    int pointTemp;
    for (int i = 0; i < mapmatrix.length; i++) {
      if (mapmatrix[startvertexID][i] != null)

      ///这里要注意的是dart是否允许这种类型的比较,后续debug注意（类型安全问题）
      {
        dist[i] = pathlength(mapmatrix, startvertexID, i, transmethod);
        path[i] = startvertexID;
      }
    } //初始化各节点到起点的距离
    points[startvertexID] = 0;
    dist[startvertexID] = 0; //加入起点，开始将点加入节点集
    for (int i = 0; i < mapmatrix.length; i++) {
      //对节点集进行扩充
      min = maxnum;
      for (int j = 0; j < mapmatrix.length; j++) {
        if ((points[j] == -1) && (dist[j] < min)) {
          min = dist[j];
          pointTemp = j;
        }
      }
      points[pointTemp] = 1;
      for (int j = 0; j < mapmatrix.length; j++) {
        //重新调成起点到各个节点间的最短距离
        if ((points[j] == -1) &&
            (dist[j] >
                dist[pointTemp] +
                    pathlength(mapmatrix, pointTemp, j, transmethod))) {
          dist[j] = dist[pointTemp] +
              pathlength(mapmatrix, pointTemp, j, transmethod);
          path[j] = pointTemp;
        }
      }
      if (pointTemp == endvertexID) {
        break; //如果已经到达出口，则退出循环
      }
    }
    if (path[endvertexID] == -1) {
      route = null;
      relativelen = double.infinity;
    } //发现如何都到不了终点。
    else {
      relativelen = dist[pointTemp];
      List<int> routeTemp;
      routeTemp.add(endvertexID);
      int pre = path[endvertexID];
      while (pre != startvertexID) {
        routeTemp.add(pre);
        pre = path[pre];
      }
      routeTemp.add(startvertexID);
      //通过前缀把路径从终点到起点加入
      for (int i = routeTemp.length - 1; i <= 0; i--) {
        route.add(routeTemp[i]);
      } //将route设为正序
    }
  }
}
