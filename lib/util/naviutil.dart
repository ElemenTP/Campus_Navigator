import 'dart:math';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:campnavi/global/global.dart';
import 'package:campnavi/model/edge.dart';
import 'package:campnavi/model/building.dart';
import 'package:campnavi/controller/settingpagecontroller.dart';
import 'package:campnavi/controller/homepagecontroller.dart';

///导航工具类
class NaviUtil {
  ///用于展示拥挤度的颜色字典
  static const Map<int, dynamic> _colortype = {
    3: Colors.white,
    2: Colors.green,
    1: Colors.amber,
    0: Colors.red,
  };

  ///导航道路，传入dijstra得到的route和某校区点集，返回直线
  static void displayRoute(
      List<int> path, int campusNum, HomePageController hpc) {
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
      hpc.mapPolylines.add(polyline);
    }
  }

  ///传入两点（建筑点和路径点），返回虚线
  static void entryRoute(LatLng from, LatLng to, HomePageController hpc) {
    Polyline polyline = Polyline(
      points: <LatLng>[from, to],
      dashLineType: DashLineType.square,
      capType: CapType.arrow,
      joinType: JoinType.round,
    );
    hpc.mapPolylines.add(polyline);
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
  static bool stateLocationReqiurement(
      SettingPageController spc, HomePageController hpc) {
    ///用户关闭了定位开关
    if (!spc.locateEnabled.value) {
      Get.dialog(AlertDialog(
        title: Text('提示'),
        content: Text('使用本功能需要打开定位开关。'),
        actions: <Widget>[
          TextButton(
            child: Text('ok'.tr),
            onPressed: () {
              spc.locateEnabled.value = true;
              prefs.write('locateEnabled', true);
              Get.back();
            },
          ),
          TextButton(
            child: Text('cancel'.tr),
            onPressed: () => Get.back(),
          ),
        ],
      ));
      return false;
    }

    ///没有定位权限，提示用户授予权限
    if (!spc.locatePermissionStatus.value.isGranted) {
      Get.dialog(AlertDialog(
        title: Text('提示'),
        content: Text('欲使用此功能，请授予定位权限。'),
        actions: <Widget>[
          TextButton(
            child: Text('cancel'.tr),
            onPressed: () => Get.back(),
          ),
          TextButton(
            child: Text('ok'.tr),
            onPressed: () async {
              spc.locatePermissionStatus.value =
                  await Permission.location.request();
              Get.back();
            },
          ),
        ],
      ));
      return false;
    }

    ///定位不正常（时间time为0），提示用户打开定位开关
    else if (hpc.userLocation.value.time == 0) {
      Get.dialog(AlertDialog(
        title: Text('提示'),
        content: Text('未开启系统定位开关，或者系统定位出错。'),
        actions: <Widget>[
          TextButton(
            child: Text('ok'.tr),
            onPressed: () => Get.back(),
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
