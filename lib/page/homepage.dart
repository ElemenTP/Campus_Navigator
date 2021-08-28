import 'dart:math';

import 'package:campnavi/page/searchpage.dart';
import 'package:campnavi/page/settingpage.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:campnavi/global/global.dart';
import 'package:campnavi/util/naviutil.dart';
import 'package:campnavi/util/shortpath.dart';
import 'package:campnavi/apikey/amapapikey.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:campnavi/model/building.dart';
import 'package:campnavi/model/naviloc.dart';
import 'package:campnavi/model/bustimetable.dart';
import 'package:campnavi/controller/homepagecontroller.dart';
import 'package:campnavi/controller/settingpagecontroller.dart';

class HomePage extends StatelessWidget {
  HomePage({Key key = const Key('main')}) : super(key: key);

  static HomePageController hpc =
      Get.put<HomePageController>(HomePageController(), permanent: true);

  static SettingPageController spc =
      Get.put<SettingPageController>(SettingPageController(), permanent: true);

  ///底部导航栏内容，左侧是搜索界面按钮，右侧是设直界面按钮。
  static List<BottomNavigationBarItem> _navbaritems = [
    //搜索标志
    BottomNavigationBarItem(
      icon: Icon(Icons.search),
      label: '搜索' /*'Search'*/,
    ),
    //设置标志
    BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: '设置' /*'Setting'*/,
    )
  ];

  ///地图点击回调函数，检测被点击处是否在任何校区内，在则显示一个标志，不在则弹窗提示
  void _onMapTapped(LatLng taplocation) async {
    if (mapData.locationInCampus(taplocation) >= 0) {
      hpc.mapMarkers['onTap'] =
          Marker(position: taplocation, onTap: _onTapMarkerTapped);
    } else {
      Get.dialog(AlertDialog(
        title: Text('提示'),
        content: Text('该点不在任何校区内。'),
        actions: <Widget>[
          TextButton(
            child: Text('取消'),
            onPressed: () => Get.back(),
          ),
        ],
      ));
    }
  }

  ///点击创建的标志的点击回调函数，展示将坐标设为起点或终点的对话框。
  void _onTapMarkerTapped(String markerid) async {
    await Get.dialog(AlertDialog(
      title: Text('坐标'),
      content: Text('将坐标设为'),
      actions: <Widget>[
        TextButton(
          child: Text('取消'),
          onPressed: () => Get.back(),
        ),
        TextButton(
          child: Text('起点'),
          onPressed: hpc.startOnUserLoc.value
              ? null
              : () {
                  _addStartLocation(hpc.mapMarkers['onTap']!.position);
                  hpc.mapMarkers.remove('onTap');
                  Get.back(result: true);
                },
        ),
        TextButton(
          child: Text('终点'),
          onPressed: () {
            _addEndLocation(hpc.mapMarkers['onTap']!.position);
            hpc.mapMarkers.remove('onTap');
            Get.back(result: true);
          },
        ),
      ],
    ));
  }

  ///从地图上添加坐标形式的起点
  void _addStartLocation(LatLng location) {
    hpc.start.value = location;
    hpc.mapMarkers['start'] = Marker(
      position: location,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      onTap: (_) => _onStartMarkerTapped(),
    );
  }

  ///从地图上添加坐标形式的终点
  void _addEndLocation(LatLng location) {
    hpc.end.add(location);
    String tmpid = 'end' + location.hashCode.toString();
    hpc.mapMarkers[tmpid] = Marker(
      position: location,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      onTap: (_) => _onEndMarkerTapped(tmpid),
    );
  }

  ///出发地Marker点击回调，询问用户收否删除该起点。
  void _onStartMarkerTapped() async {
    await Get.dialog(AlertDialog(
      title: Text('删除起点'),
      content: Text('删除起点吗？'),
      actions: <Widget>[
        TextButton(
          child: Text('取消'),
          onPressed: () => Get.back(),
        ),
        TextButton(
          child: Text('确定'),
          onPressed: () {
            hpc.start.value = null;
            hpc.mapMarkers.remove('start');
            Get.back();
          },
        ),
      ],
    ));
  }

  ///目的地Marker点击回调，询问用户收否删除该终点。
  void _onEndMarkerTapped(String markerid) async {
    await Get.dialog(AlertDialog(
      title: Text('删除终点'),
      content: Text('删除终点吗？'),
      actions: <Widget>[
        TextButton(
          child: Text('取消'),
          onPressed: () => Get.back(),
        ),
        TextButton(
          child: Text('确定'),
          onPressed: () {
            hpc.end.remove(hpc.mapMarkers[markerid]!.position);
            hpc.mapMarkers.remove(markerid);
            Get.back();
          },
        ),
      ],
    ));
  }

  ///地图视角改变结束回调函数，将视角信息记录在NVM中。
  void _onCameraMoveEnd(CameraPosition endPosition) {
    prefs.write('lastCamPositionbearing', endPosition.bearing);
    prefs.write('lastCamPositionLat', endPosition.target.latitude);
    prefs.write('lastCamPositionLng', endPosition.target.longitude);
    prefs.write('lastCamPositionzoom', endPosition.zoom);
  }

  ///用户位置改变回调函数，记录用户位置，当选择正在导航且选择了实时导航时进行实时导航，如果用户
  ///位置信息有问题则不执行。导航路线列表为空时提示已到目的地，不是空时则1. 判断用户是否偏离当
  ///前路线，当用户距离路线的垂直距离大于40米或距离路线终点的距离大于路线长度加20米则认为用户
  ///偏离路线。 2. 判断用户是否已走过当前路线，当用户距离路线终点距离小于5米或距离起点的距离大
  ///于路线长度加5米或距离下一条路线的终点的距离小于下一条路线的长度时认为用户已走过当前路线。
  ///如果没有下一条路线，或者下一条路线是当前路线的折返时最后一个判断条件不生效。
  void _onLocationChanged(AMapLocation aMapLocation) async {
    //记录用户位置。
    hpc.userLocation.value = aMapLocation;
    //判断是否在进行实时导航，位置信息是否正确
    if (hpc.naviStatus.value &&
        hpc.realTime.value &&
        hpc.userLocation.value.time != 0) {
      //导航路线列表空了，说明已到达目的地。
      if (hpc.mapPolylines.isEmpty) {
        Get.dialog(AlertDialog(
          title: Text('提示'),
          content: Text('已到达全部终点，实时导航结束。'),
          actions: <Widget>[
            TextButton(
              child: Text('确定'),
              onPressed: () => Get.back(),
            ),
          ],
        ));
        if (spc.logEnabled.value)
          logSink.write(DateTime.now().toString() + ': 已到达全部终点，实时导航结束。\n');
        hpc.naviStatus.value = false;
        hpc.routeLength.value = 0;
      } else {
        //判断是否偏移路线，是否已经走过一条路线
        LatLng depaLatLng = hpc.mapPolylines.first.points.first;
        LatLng destLatLng = hpc.mapPolylines.first.points.last;
        double polylineLength =
            AMapTools.distanceBetween(depaLatLng, destLatLng);
        double distanceDepa = AMapTools.distanceBetween(
            hpc.userLocation.value.latLng, depaLatLng);
        double distanceDest = AMapTools.distanceBetween(
            hpc.userLocation.value.latLng, destLatLng);
        double distancetoLine = (2 *
                AMapTools.calculateArea(<LatLng>[
                  hpc.userLocation.value.latLng,
                  depaLatLng,
                  destLatLng
                ])) /
            polylineLength;
        double nextLength = 114514;
        double distanceNextDest = 1919810;
        if (hpc.mapPolylines.length > 1) {
          LatLng destNextLatLng = hpc.mapPolylines[1].points.last;
          if (depaLatLng != destNextLatLng) {
            nextLength = AMapTools.distanceBetween(destLatLng, destNextLatLng);
            distanceNextDest = AMapTools.distanceBetween(
                hpc.userLocation.value.latLng, destNextLatLng);
          }
        }
        if (distancetoLine > 40 || (distanceDest > polylineLength + 25)) {
          if (mapData.locationInCampus(hpc.userLocation.value.latLng) ==
              mapData.locationInCampus(destLatLng)) {
            Get.dialog(AlertDialog(
              title: Text('提示'),
              content: Text('重新规划路线。'),
              actions: <Widget>[
                TextButton(
                  child: Text('确定'),
                  onPressed: () => Get.back(),
                ),
              ],
            ));
            if (spc.logEnabled.value)
              logSink.write(DateTime.now().toString() + ': 重新规划路线。\n');
            await _showRoute();
          }
        } else if (distanceDest < 5 ||
            (distanceDepa > polylineLength + 5) ||
            distanceNextDest < nextLength) {
          if (spc.logEnabled.value)
            logSink.write(DateTime.now().toString() + ': 走过一条规划路线。\n');
          hpc.mapPolylines.removeAt(0);
        }
      }
    }
  }

  ///导航按钮按下功能函数，调用导航设置管理界面
  void _setNavigation() async {
    if (await _managehpc()) {
      await _showRoute();
    }
  }

  ///定位按钮按下回调函数，弹窗让用户选择目标视角。
  void _setCameraPosition() async {
    late LatLng newLocation;
    List<Widget> listWidget = <Widget>[
      Card(
        child: ListTile(
          title: Text('当前位置'),
          onTap: () {
            if (NaviUtil.stateLocationReqiurement(spc, hpc)) {
              newLocation = hpc.userLocation.value.latLng;
              Get.back(result: true);
            }
          },
        ),
      )
    ];
    for (int i = 0; i < mapData.mapCampus.length; ++i) {
      listWidget.add(Card(
        child: ListTile(
          title: Text(mapData[i].name),
          onTap: () {
            newLocation = mapData.getVertexLatLng(i, mapData[i].gate);
            Get.back(result: true);
          },
        ),
      ));
    }
    if (await Get.dialog(AlertDialog(
          title: Text('选择目标视角'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: listWidget,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () => Get.back<bool>(result: false),
            ),
          ],
        )) ??
        false) {
      await hpc.mapController?.value.moveCamera(
          CameraUpdate.newLatLngZoom(newLocation, DEFAULT_ZOOM),
          duration: 500);
    }
  }

  ///底栏按钮点击回调函数，按点击的底栏项目调出对应activity。
  void _onBarItemTapped(int index) async {
    switch (index) {
      case 0:
        await Get.to(() => SearchPage());
        break;
      case 1:
        await Get.to(() => SettingPage());
        break;
    }
  }

  ///定位权限申请函数
  void _requestLocationPermission() async {
    //申请位置权限
    spc.locatePermissionStatus.value = await Permission.location.status;
    if (!spc.locateEnabled.value) return;
    //用户拒绝则弹窗提示
    if (!spc.locatePermissionStatus.value.isGranted) {
      Get.dialog(AlertDialog(
        title: Text('提示'),
        content: Text('校园导航的大部分功能需要定位权限才能正常工作，请授予定位权限。'),
        actions: <Widget>[
          TextButton(
            child: Text('取消'),
            onPressed: () => Get.back(),
          ),
          TextButton(
            child: Text('确定'),
            onPressed: () async {
              Get.back();
              spc.locatePermissionStatus.value =
                  await Permission.location.request();
            },
          ),
        ],
      ));
    }
  }

  ///管理导航状态界面，用户可1. 管理起点和各个终点。2. 选择是否以当前位置为起点。3. 当以当前
  ///位置为起点时可以选择使用实时导航。4. 选择是否使用最短时间策略，使用则显示时间而非路程长度。
  ///5. 是否骑车。6. 是否考略拥挤度。当存在起点和终点时可以开始导航。
  Future<bool> _managehpc() async {
    return await Get.dialog(
          AlertDialog(
            title: Text('导航'),
            content: SingleChildScrollView(
              child: Obx(() {
                late Card startWidget;
                if (hpc.startOnUserLoc.value) {
                  startWidget = Card(
                    child: ListTile(
                      title: Text('当前位置。'),
                    ),
                  );
                } else if (hpc.start.value.runtimeType == LatLng) {
                  startWidget = Card(
                    child: ListTile(
                      title: Text(
                          '坐标：${hpc.start.value!.longitude}，${hpc.start.value!.latitude}。'),
                      onTap: () {
                        hpc.start.value = null;
                        hpc.mapMarkers.remove('start');
                      },
                    ),
                  );
                } else if (hpc.start.value.runtimeType == Building) {
                  startWidget = Card(
                    child: ListTile(
                      title: Text('建筑：${hpc.start.value!.description.first}。'),
                      onTap: () {
                        hpc.start.value = null;
                        hpc.mapMarkers.remove('start');
                      },
                    ),
                  );
                } else {
                  startWidget = Card(
                    child: ListTile(
                      title: Text('未设置出发点。'),
                    ),
                  );
                }
                late Widget endWidget;
                List<Widget> inColumn = [];
                hpc.end.forEach((element) {
                  inColumn.add(element.runtimeType == LatLng
                      ? Card(
                          child: ListTile(
                            title: Text(
                                '坐标：${element.longitude}，${element.latitude}。'),
                            onTap: () {
                              hpc.end.remove(element);
                              hpc.mapMarkers
                                  .remove('end' + element.hashCode.toString());
                            },
                          ),
                        )
                      : Card(
                          child: ListTile(
                            title: Text('建筑：${element.description.first}。'),
                            onTap: () {
                              hpc.end.remove(element);
                              hpc.mapMarkers
                                  .remove('end' + element.hashCode.toString());
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
                endWidget = Column(
                  children: inColumn,
                );
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    startWidget,
                    SwitchListTile(
                        value: hpc.startOnUserLoc.value,
                        title: Text('从当前位置开始'),
                        onChanged: (state) {
                          hpc.startOnUserLoc.value = state;
                          if (!state) hpc.realTime.value = state;
                          hpc.start.value = null;
                          hpc.mapMarkers.remove('start');
                        }),
                    SwitchListTile(
                      value: hpc.realTime.value,
                      title: Text('实时导航'),
                      onChanged: hpc.startOnUserLoc.value
                          ? (state) => hpc.realTime.value = state
                          : null,
                    ),
                    LimitedBox(
                      maxHeight: 270,
                      child: SingleChildScrollView(
                        child: endWidget,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        hpc.start.value = null;
                        hpc.end.clear();
                        hpc.mapMarkers.removeWhere(
                            (key, value) => !key.contains('onTap'));
                      },
                      icon: Icon(Icons.delete),
                      label: Text('清除全部地点'),
                    ),
                    SwitchListTile(
                      value: hpc.onbike.value,
                      title: Text('允许骑车'),
                      onChanged: (state) => hpc.onbike.value = state,
                    ),
                    SwitchListTile(
                      value: hpc.minTime.value,
                      title: Text('最短时间'),
                      onChanged: (state) {
                        hpc.minTime.value = state;
                        if (!state) hpc.crowding.value = state;
                      },
                    ),
                    SwitchListTile(
                      value: hpc.crowding.value,
                      title: Text('拥挤'),
                      onChanged: hpc.minTime.value
                          ? (state) => hpc.crowding.value = state
                          : null,
                    ),
                    Text(
                      '提示：点击可删除起点/终点',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.normal),
                    ),
                  ],
                );
              }),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('取消'),
                onPressed: () => Get.back<bool>(result: false),
              ),
              TextButton(
                child: Text('停止'),
                onPressed: hpc.naviStatus.value
                    ? () {
                        hpc.naviStatus.value = false;
                        Get.back(result: true);
                      }
                    : null,
              ),
              TextButton(
                child: Text('开始'),
                onPressed:
                    (hpc.startOnUserLoc.value || hpc.start.value != null) &&
                            hpc.end.isNotEmpty
                        ? () {
                            hpc.naviStatus.value = true;
                            Get.back(result: true);
                          }
                        : null,
              ),
            ],
          ),
        ) ??
        false;
  }

  ///展示导航路线函数，先对终点列表进行排序：当前点从起点开始，在未排序的点中寻找与当前点直线
  ///距离最短的点，设为当前点的下一个点。坐标类型的点以本身为特征坐标，建筑类型的点则以一种平
  ///均算法得到的点作为排序特质点。排序结束后，逐个使用狄杰斯特拉算法生成路线并绘制在地图上。
  ///对建筑类型的点此时将会遍历选择路程最近的门作为狄杰斯特拉点。当路程跨校区时，将在地图数据
  ///提供的交通工具信息中智能选择校区间导航方法，导航采用最短路程策略则确保人行走时间最短，最
  ///短时间策略则确保交通耗时最短。
  Future<void> _showRoute() async {
    //清空线列表和路线长度
    hpc.mapPolylines.clear();
    hpc.routeLength.value = 0;
    //检查导航状态，为开始时绘制路线
    if (hpc.naviStatus.value) {
      //导航开始时的日期时间，用于智能选择校区间导航方法
      DateTime routeBeginTime = DateTime.now();
      if (spc.logEnabled.value) {
        logSink.write(routeBeginTime.toString() + ': 开始导航，开始计算路线。\n');
        logSink.write(DateTime.now().toString() +
            ': ' +
            '实时导航' +
            (hpc.realTime.value ? '开启' : '关闭') +
            '，骑车' +
            (hpc.onbike.value ? '开启' : '关闭') +
            '。\n');
        logSink.write(DateTime.now().toString() +
            ': ' +
            '最短时间' +
            (hpc.minTime.value ? '开启' : '关闭') +
            '，拥挤度' +
            (hpc.crowding.value ? '开启' : '关闭') +
            '。\n');
      }
      //如果是选择以用户当前位置为起点，则判断是否有定位权限，定位是否正常，在不在校区内
      if (hpc.startOnUserLoc.value) {
        if (NaviUtil.stateLocationReqiurement(spc, hpc)) {
          int startCampus =
              mapData.locationInCampus(hpc.userLocation.value.latLng);
          if (startCampus >= 0) {
            hpc.start.value = hpc.userLocation.value.latLng;
            if (spc.logEnabled.value)
              logSink.write(DateTime.now().toString() + ': 以用户坐标为起点。\n');
          } else {
            Get.dialog(AlertDialog(
              title: Text('提示'),
              content: Text('您不在任何校区内。'),
              actions: <Widget>[
                TextButton(
                  child: Text('取消'),
                  onPressed: () => Get.back(),
                ),
              ],
            ));
            if (spc.logEnabled.value)
              logSink.write(DateTime.now().toString() + ': 您不在任何校区内，停止导航。\n');
            hpc.naviStatus.value = false;
            return;
          }
        } else {
          if (spc.logEnabled.value)
            logSink.write(DateTime.now().toString() + ': 没有定位权限或定位不正常，停止导航。\n');
          hpc.naviStatus.value = false;
          return;
        }
      }
      if (spc.logEnabled.value)
        logSink.write(DateTime.now().toString() + ': 开始目的地排序。\n');
      try {
        //排序所用新列表
        List naviOrder = [hpc.start];
        naviOrder.addAll(hpc.end);
        //终点集合中，坐标以其本身，建筑以特征坐标，按直线距离顺序排序
        for (int i = 0; i < naviOrder.length - 2; ++i) {
          int nextEnd = i + 1;
          double minDistance = double.infinity;
          for (int j = i + 1; j < naviOrder.length; ++j) {
            double curDistance = AMapTools.distanceBetween(
                NaviUtil.getLocation(naviOrder[i]),
                NaviUtil.getLocation(naviOrder[j]));
            if (curDistance < minDistance) {
              minDistance = curDistance;
              nextEnd = j;
            }
          }
          if (nextEnd != i + 1) {
            var tmp = naviOrder[i + 1];
            naviOrder[i + 1] = naviOrder[nextEnd];
            naviOrder[nextEnd] = tmp;
          }
        }
        int transmethod = hpc.onbike.value ? 1 : 0;
        hpc.crowding.value
            ? mapData.randomCrowding()
            : mapData.disableCrowding();
        if (spc.logEnabled.value) {
          logSink.write(DateTime.now().toString() + ': 完成目的地排序。\n');
          naviOrder.forEach((element) {
            logSink.write(DateTime.now().toString() +
                ': ' +
                (element.runtimeType == LatLng
                    ? '坐标: ' + element.toJson().toString()
                    : '建筑: ' + (element as Building).description.first) +
                '\n');
          });
          logSink.write(DateTime.now().toString() + ': 开始狄杰斯特拉算法。\n');
        }
        //将排好序的列表中的元素一一绘制虚线，使用狄杰斯特拉算法得到路径，绘制实线
        for (int i = 0; i < naviOrder.length; ++i) {
          int campusNum = 0;
          LatLng realLatLng = LatLng(0, 0);
          LatLng juncLatLng = LatLng(0, 0);
          double juncLength = 114514;
          NaviLoc curNaviLoc = NaviLoc(campusNum, 0, realLatLng);
          if (naviOrder[i].runtimeType == LatLng) {
            realLatLng = naviOrder[i];
            campusNum = mapData.locationInCampus(realLatLng);
            int nearVertex = mapData.nearestVertex(campusNum, realLatLng);
            juncLatLng = mapData.getVertexLatLng(campusNum, nearVertex);
            juncLength = (AMapTools.distanceBetween(juncLatLng, realLatLng) *
                    (hpc.onbike.value ? BIKESPEED : 1)) /
                (hpc.crowding.value ? 1 - Random().nextDouble() : 1);
            curNaviLoc = NaviLoc(campusNum, nearVertex, naviOrder[i]);
          } else if (naviOrder[i].runtimeType == Building) {
            Building curBuilding = naviOrder[i] as Building;
            campusNum = mapData.buildingInCampus(curBuilding);
            LatLng disReference = i == 0
                ? NaviUtil.getLocation(naviOrder[1])
                : (naviOrder[i - 1] as NaviLoc).location;
            int choosedDoor = 0;
            if (curBuilding.doors.length > 1) {
              double minDistance = double.infinity;
              for (int j = 0; j < curBuilding.doors.length; ++j) {
                double curDistance = AMapTools.distanceBetween(
                    disReference, curBuilding.doors[j]);
                if (curDistance < minDistance) {
                  minDistance = curDistance;
                  choosedDoor = j;
                }
              }
            }
            realLatLng = curBuilding.doors[choosedDoor];
            int juncVertex = curBuilding.juncpoint[choosedDoor];
            juncLatLng = mapData.getVertexLatLng(campusNum, juncVertex);
            juncLength = (AMapTools.distanceBetween(juncLatLng, realLatLng) *
                    (hpc.onbike.value ? BIKESPEED : 1)) /
                (hpc.crowding.value ? 1 - Random().nextDouble() : 1);
            curNaviLoc = NaviLoc(campusNum, juncVertex, realLatLng);
          }
          naviOrder[i] = curNaviLoc;
          //该点不是起点，与前一个点狄杰斯特拉并绘制路线
          if (i != 0) {
            NaviLoc startVertex = naviOrder[i - 1] as NaviLoc;
            NaviLoc endVertex = curNaviLoc;
            //未跨校区
            if (startVertex.campusNum == endVertex.campusNum) {
              if (startVertex.vertexNum != endVertex.vertexNum) {
                ShortPath path = ShortPath(
                    mapData.getAdjacentMatrix(startVertex.campusNum),
                    startVertex.vertexNum,
                    endVertex.vertexNum,
                    transmethod);
                hpc.routeLength.value += path.getRelativeLen();
                NaviUtil.displayRoute(
                    path.getRoute(), startVertex.campusNum, hpc);
              }
            } //跨校区
            else {
              double lengthPublicTransStart = 0;
              double lengthPublicTransEnd = 0;
              double lengthSchoolBusStart = 0;
              double lengthSchoolBusEnd = 0;
              List<int> routePublicTransStart = [];
              List<int> routePublicTransEnd = [];
              List<int> routeSchoolBusStart = [];
              List<int> routeSchoolBusEnd = [];
              int startBusStop = mapData[startVertex.campusNum].busstop;
              int endBusStop = mapData[endVertex.campusNum].busstop;
              int startGate = mapData[startVertex.campusNum].gate;
              int endGate = mapData[endVertex.campusNum].gate;
              if (startVertex.vertexNum != startBusStop) {
                ShortPath startBusStopPath = ShortPath(
                    mapData.getAdjacentMatrix(startVertex.campusNum),
                    startVertex.vertexNum,
                    startBusStop,
                    transmethod);
                lengthSchoolBusStart = startBusStopPath.getRelativeLen();
                routeSchoolBusStart = startBusStopPath.getRoute();
              }
              if (startVertex.vertexNum != startGate) {
                ShortPath startGatePath = ShortPath(
                    mapData.getAdjacentMatrix(startVertex.campusNum),
                    startVertex.vertexNum,
                    startGate,
                    transmethod);
                lengthPublicTransStart = startGatePath.getRelativeLen();
                routePublicTransStart = startGatePath.getRoute();
              }
              if (endVertex.vertexNum != endBusStop) {
                ShortPath endBusStopPath = ShortPath(
                    mapData.getAdjacentMatrix(endVertex.campusNum),
                    endBusStop,
                    endVertex.vertexNum,
                    transmethod);
                lengthSchoolBusEnd = endBusStopPath.getRelativeLen();
                routeSchoolBusEnd = endBusStopPath.getRoute();
              }
              if (endVertex.vertexNum != endGate) {
                ShortPath endGatePath = ShortPath(
                    mapData.getAdjacentMatrix(endVertex.campusNum),
                    endGate,
                    endVertex.vertexNum,
                    transmethod);
                lengthPublicTransEnd = endGatePath.getRelativeLen();
                routePublicTransEnd = endGatePath.getRoute();
              }
              DateTime timeAtGetOnPubTrans = routeBeginTime.add(Duration(
                seconds: (hpc.routeLength + lengthPublicTransStart).toInt(),
              ));
              DateTime timeAtGetOnSchoolBus = routeBeginTime.add(Duration(
                  seconds: (hpc.routeLength + lengthSchoolBusStart).toInt()));
              List bestPubTrans = mapData.getBestTimeTable(
                  startVertex.campusNum,
                  endVertex.campusNum,
                  timeAtGetOnPubTrans,
                  onlySchoolBus: false);
              List bestSchoolBus = mapData.getBestTimeTable(
                  startVertex.campusNum,
                  endVertex.campusNum,
                  timeAtGetOnSchoolBus,
                  onlySchoolBus: true);
              if (bestPubTrans.isEmpty && bestSchoolBus.isEmpty) throw '!';
              late String toPrint;
              String startCampusName = mapData[startVertex.campusNum].name;
              String endCampusName = mapData[endVertex.campusNum].name;
              if (bestPubTrans.isEmpty && bestSchoolBus.isNotEmpty) {
                hpc.routeLength.value += (lengthSchoolBusStart +
                    lengthSchoolBusEnd +
                    (hpc.minTime.value ? (bestSchoolBus.last as int) * 60 : 0));
                if (routeSchoolBusStart.isNotEmpty)
                  NaviUtil.displayRoute(
                      routeSchoolBusStart, startVertex.campusNum, hpc);
                if (routeSchoolBusEnd.isNotEmpty)
                  NaviUtil.displayRoute(
                      routeSchoolBusEnd, endVertex.campusNum, hpc);
                toPrint = (bestSchoolBus.first as BusTimeTable).description;
              } else if (bestPubTrans.isNotEmpty && bestSchoolBus.isEmpty) {
                hpc.routeLength.value += (lengthPublicTransStart +
                    lengthPublicTransEnd +
                    (hpc.minTime.value ? (bestPubTrans.last as int) * 60 : 0));
                if (routePublicTransStart.isNotEmpty)
                  NaviUtil.displayRoute(
                      routePublicTransStart, startVertex.campusNum, hpc);
                if (routePublicTransEnd.isNotEmpty)
                  NaviUtil.displayRoute(
                      routePublicTransEnd, endVertex.campusNum, hpc);
                toPrint = (bestPubTrans.first as BusTimeTable).description;
              } else {
                if ((lengthSchoolBusStart +
                        lengthSchoolBusEnd +
                        (hpc.minTime.value
                            ? (bestSchoolBus.last as int) * 60
                            : 0)) >
                    (lengthPublicTransStart +
                        lengthPublicTransEnd +
                        (hpc.minTime.value
                            ? (bestPubTrans.last as int) * 60
                            : 0))) {
                  hpc.routeLength.value += (lengthPublicTransStart +
                      lengthPublicTransEnd +
                      (hpc.minTime.value
                          ? (bestPubTrans.last as int) * 60
                          : 0));
                  if (routePublicTransStart.isNotEmpty)
                    NaviUtil.displayRoute(
                        routePublicTransStart, startVertex.campusNum, hpc);
                  if (routePublicTransEnd.isNotEmpty)
                    NaviUtil.displayRoute(
                        routePublicTransEnd, endVertex.campusNum, hpc);
                  toPrint = (bestPubTrans.first as BusTimeTable).description;
                } else {
                  hpc.routeLength.value += (lengthSchoolBusStart +
                      lengthSchoolBusEnd +
                      (hpc.minTime.value
                          ? (bestSchoolBus.last as int) * 60
                          : 0));
                  if (routeSchoolBusStart.isNotEmpty)
                    NaviUtil.displayRoute(
                        routeSchoolBusStart, startVertex.campusNum, hpc);
                  if (routeSchoolBusEnd.isNotEmpty)
                    NaviUtil.displayRoute(
                        routeSchoolBusEnd, endVertex.campusNum, hpc);
                  toPrint = (bestSchoolBus.first as BusTimeTable).description;
                }
              }
              await Get.dialog(AlertDialog(
                title: Text('提示'),
                content: Text(
                    '从$startCampusName移动到$endCampusName，请乘坐' + toPrint + '。'),
                actions: <Widget>[
                  TextButton(
                    child: Text('取消'),
                    onPressed: () => Get.back(),
                  ),
                ],
              ));
            }
          }
          //该点不是终点，绘制其与连接点间的虚线
          if (i != naviOrder.length - 1) {
            NaviUtil.entryRoute(realLatLng, juncLatLng, hpc);
            hpc.routeLength.value += juncLength;
          }
          //该点不是起点，绘制连接点与其之间的虚线
          if (i != 0) {
            NaviUtil.entryRoute(juncLatLng, realLatLng, hpc);
            hpc.routeLength.value += juncLength;
          }
        }
        if (spc.logEnabled.value)
          logSink
              .write(DateTime.now().toString() + ': 狄杰斯特拉算法结束，路线计算函数正常结束。\n');
      } catch (_) {
        Get.dialog(AlertDialog(
          title: Text('提示'),
          content: Text('未找到路线。请检查地图数据。'),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () => Get.back(),
            ),
          ],
        ));
        if (spc.logEnabled.value)
          logSink.write(DateTime.now().toString() + ': 未找到路线。停止导航。\n');
        //路线绘制出现错误，将导航状态设为停止同时清空路线和长度
        hpc.naviStatus.value = false;
        hpc.mapPolylines.clear();
        hpc.routeLength.value = 0;
      }
    } else {
      if (spc.logEnabled.value)
        logSink.write(DateTime.now().toString() + ': 停止导航。\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    _requestLocationPermission();
    return Scaffold(
      //顶栏
      appBar: AppBar(
        title: Text('title'.tr),
      ),
      //中央内容区
      body: Scaffold(
        body: ConstrainedBox(
          constraints: BoxConstraints.expand(),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Obx(
                () => AMapWidget(
                  //高德api Key
                  apiKey: amapApiKeys,
                  //创建地图回调函数，获得controller。
                  onMapCreated: (controller) =>
                      hpc.mapController = controller.obs,
                  //地图初始视角
                  initialCameraPosition: CameraPosition(
                    bearing: prefs.read<double>('lastCamPositionbearing') ?? 0,
                    target: LatLng(
                        prefs.read<double>('lastCamPositionLat') ?? 39.909187,
                        prefs.read<double>('lastCamPositionLng') ?? 116.397451),
                    zoom: prefs.read<double>('lastCamPositionzoom') ??
                        DEFAULT_ZOOM,
                  ),
                  //地图点击回调函数
                  onTap: _onMapTapped,
                  //地图视角移动回调函数，移除点击添加的标志。
                  onCameraMove: (_) => hpc.mapMarkers.remove('onTap'),
                  //地图视角移动结束回调函数
                  onCameraMoveEnd: _onCameraMoveEnd,
                  //用户位置移动回调函数
                  onLocationChanged: _onLocationChanged,
                  //开启指南针
                  compassEnabled: spc.compassEnabled.value,
                  //开启显示用户位置功能
                  myLocationStyleOptions:
                      MyLocationStyleOptions(spc.locateEnabled.value),
                  //地图类型，使用卫星地图
                  mapType: spc.preferMapType.value,
                  //地图上的标志
                  markers: Set<Marker>.of(hpc.mapMarkers.values),
                  //地图上的线
                  polylines: Set<Polyline>.of(hpc.mapPolylines),
                ),
              ),
              Obx(
                () => Visibility(
                  visible: hpc.naviStatus.value,
                  child: Positioned(
                    left: 18.0,
                    child: Chip(
                        label: Text(hpc.minTime.value
                            ? '约' +
                                (hpc.routeLength.value / 60)
                                    .toStringAsFixed(0) +
                                '分钟'
                            : '约' +
                                (hpc.routeLength.value /
                                        (hpc.onbike.value ? BIKESPEED : 1))
                                    .toStringAsFixed(0) +
                                '米')),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: UniqueKey(),
          onPressed: _setCameraPosition,
          tooltip: '切换地图视角' /*'Locate'*/,
          child: Icon(Icons.location_searching),
          mini: true,
        ),
        //避免被屏幕键盘改变形状
        resizeToAvoidBottomInset: false,
      ),
      //底导航栏
      bottomNavigationBar: BottomNavigationBar(
        items: _navbaritems,
        unselectedItemColor: Colors.blue,
        onTap: _onBarItemTapped,
      ),
      //悬浮按键
      floatingActionButton: FloatingActionButton(
        heroTag: UniqueKey(),
        onPressed: _setNavigation,
        tooltip: hpc.naviStatus.value
            ? '停止导航'
            : '开始导航' /*'Stop Navigation' : 'Start Navigation'*/,
        child: hpc.naviStatus.value ? Icon(Icons.stop) : Icon(Icons.play_arrow),
      ),
      //悬浮按键位置
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      //避免被屏幕键盘改变形状
      resizeToAvoidBottomInset: false,
    );
  }
}
