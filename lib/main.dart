import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:permission_handler/permission_handler.dart';

import 'header.dart';
import 'amapapikey.dart';
import 'searchpage.dart';
import 'settingpage.dart';
import 'shortpath.dart';

void main() async {
  //初始化Flutter环境
  WidgetsFlutterBinding.ensureInitialized();
  //获取软件信息
  packageInfo = await PackageInfo.fromPlatform();
  //获取持久化设置内容
  prefs = await SharedPreferences.getInstance();
  //初始化日志功能
  logEnabled = prefs.getBool('logEnabled') ?? false;
  Directory logFileDir = await getApplicationDocumentsDirectory();
  logFile = File(logFileDir.path + '/NaviLog.txt');
  if (logEnabled) logSink = logFile.openWrite(mode: FileMode.append);
  //初始化地图数据
  String? dataFileDir = prefs.getString('dataFileDir');
  if (dataFileDir == null) {
    mapData = MapData.fromJson(
        jsonDecode(await rootBundle.loadString('mapdata/default.json')));
    if (logEnabled) logSink.write(DateTime.now().toString() + ': 读取默认地图数据。\n');
  } else {
    File dataFile = File(dataFileDir);
    mapData = MapData.fromJson(jsonDecode(await dataFile.readAsString()));
    if (logEnabled)
      logSink.write(DateTime.now().toString() +
          ': 读取地图数据' +
          dataFileDir.split('/').last +
          '\n');
  }
  //初始化逻辑位置
  String? logicLocFileDir = prefs.getString('logicLocFileDir');
  if (logicLocFileDir == null) {
    mapLogicLoc = LogicLoc();
    if (logEnabled) logSink.write(DateTime.now().toString() + ': 没有逻辑位置数据。\n');
  } else {
    File logicLocFile = File(logicLocFileDir);
    mapLogicLoc =
        LogicLoc.fromJson(jsonDecode(await logicLocFile.readAsString()));
    if (logEnabled)
      logSink.write(DateTime.now().toString() +
          ': 读取逻辑位置数据' +
          logicLocFileDir.split('/').last +
          '\n');
  }
  //运行应用界面
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '校园导航',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: MyHomePage(title: '校园导航' /*'Campus Navigator'*/),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key = const Key('main'), this.title = 'main'})
      : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

///主界面，用于显示地图
class _MyHomePageState extends State<MyHomePage> {
  ///底部导航栏内容，左侧是搜索界面按钮，右侧是设直界面按钮。
  static const List<BottomNavigationBarItem> _navbaritems = [
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
      setState(() {
        mapMarkers['onTap'] =
            Marker(position: taplocation, onTap: _onTapMarkerTapped);
      });
    } else {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('提示'),
                content: Text('该点不在任何校区内。'),
                actions: <Widget>[
                  TextButton(
                    child: Text('取消'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ));
    }
  }

  ///点击创建的标志的点击回调函数，展示将坐标设为起点或终点的对话框。
  void _onTapMarkerTapped(String markerid) async {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('坐标'),
              content: Text('将坐标设为'),
              actions: <Widget>[
                TextButton(
                  child: Text('取消'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('起点'),
                  onPressed: naviState.startOnUserLoc
                      ? null
                      : () {
                          _addStartLocation(mapMarkers['onTap']!.position);
                          mapMarkers.remove('onTap');
                          Navigator.of(context).pop(true);
                        },
                ),
                TextButton(
                  child: Text('终点'),
                  onPressed: () {
                    _addEndLocation(mapMarkers['onTap']!.position);
                    mapMarkers.remove('onTap');
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            ));
    setState(() {});
  }

  ///从地图上添加坐标形式的起点
  void _addStartLocation(LatLng location) {
    naviState.start = location;
    mapMarkers['start'] = Marker(
      position: location,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      onTap: (_) => _onStartMarkerTapped(),
    );
  }

  ///从地图上添加坐标形式的终点
  void _addEndLocation(LatLng location) {
    naviState.end.add(location);
    String tmpid = 'end' + location.hashCode.toString();
    mapMarkers[tmpid] = Marker(
      position: location,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      onTap: (_) => _onEndMarkerTapped(tmpid),
    );
  }

  ///出发地Marker点击回调，询问用户收否删除该起点。
  void _onStartMarkerTapped() async {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('删除起点'),
              content: Text('删除起点吗？'),
              actions: <Widget>[
                TextButton(
                  child: Text('取消'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('确定'),
                  onPressed: () {
                    naviState.start = null;
                    mapMarkers.remove('start');
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ));
    setState(() {});
  }

  ///目的地Marker点击回调，询问用户收否删除该终点。
  void _onEndMarkerTapped(String markerid) async {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('删除终点'),
              content: Text('删除终点吗？'),
              actions: <Widget>[
                TextButton(
                  child: Text('取消'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('确定'),
                  onPressed: () {
                    naviState.end.remove(mapMarkers[markerid]!.position);
                    mapMarkers.remove(markerid);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ));
    setState(() {});
  }

  ///地图视角改变结束回调函数，将视角信息记录在NVM中。
  void _onCameraMoveEnd(CameraPosition endPosition) {
    prefs.setDouble('lastCamPositionbearing', endPosition.bearing);
    prefs.setDouble('lastCamPositionLat', endPosition.target.latitude);
    prefs.setDouble('lastCamPositionLng', endPosition.target.longitude);
    prefs.setDouble('lastCamPositionzoom', endPosition.zoom);
  }

  ///用户位置改变回调函数，记录用户位置，当选择正在导航且选择了实时导航时进行实时导航，如果用户
  ///位置信息有问题则不执行。导航路线列表为空时提示已到目的地，不是空时则1. 判断用户是否偏离当
  ///前路线，当用户距离路线的垂直距离大于40米或距离路线终点的距离大于路线长度加20米则认为用户
  ///偏离路线。 2. 判断用户是否已走过当前路线，当用户距离路线终点距离小于5米或距离起点的距离大
  ///于路线长度加5米或距离下一条路线的终点的距离小于下一条路线的长度时认为用户已走过当前路线。
  ///如果没有下一条路线，或者下一条路线是当前路线的折返时最后一个判断条件不生效。
  void _onLocationChanged(AMapLocation aMapLocation) async {
    //记录用户位置。
    userLocation = aMapLocation;
    //判断是否在进行实时导航，位置信息是否正确
    if (naviState.naviStatus && naviState.realTime && userLocation.time != 0) {
      //导航路线列表空了，说明已到达目的地。
      if (mapPolylines.isEmpty) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text('提示'),
                  content: Text('已到达全部终点，实时导航结束。'),
                  actions: <Widget>[
                    TextButton(
                      child: Text('确定'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ));
        if (logEnabled)
          logSink.write(DateTime.now().toString() + ': 已到达全部终点，实时导航结束。\n');
        naviState.naviStatus = false;
        naviState.routeLength = 0;
        setState(() {});
      } else {
        //判断是否偏移路线，是否已经走过一条路线
        LatLng depaLatLng = mapPolylines.first.points.first;
        LatLng destLatLng = mapPolylines.first.points.last;
        double polylineLength =
            AMapTools.distanceBetween(depaLatLng, destLatLng);
        double distanceDepa =
            AMapTools.distanceBetween(userLocation.latLng, depaLatLng);
        double distanceDest =
            AMapTools.distanceBetween(userLocation.latLng, destLatLng);
        double distancetoLine = (2 *
                AMapTools.calculateArea(
                    <LatLng>[userLocation.latLng, depaLatLng, destLatLng])) /
            polylineLength;
        double nextLength = 114514;
        double distanceNextDest = 1919810;
        if (mapPolylines.length > 1) {
          LatLng destNextLatLng = mapPolylines[1].points.last;
          if (depaLatLng != destNextLatLng) {
            nextLength = AMapTools.distanceBetween(destLatLng, destNextLatLng);
            distanceNextDest =
                AMapTools.distanceBetween(userLocation.latLng, destNextLatLng);
          }
        }
        if (distancetoLine > 40 || (distanceDest > polylineLength + 25)) {
          if (mapData.locationInCampus(userLocation.latLng) ==
              mapData.locationInCampus(destLatLng)) {
            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                      title: Text('提示'),
                      content: Text('重新规划路线。'),
                      actions: <Widget>[
                        TextButton(
                          child: Text('确定'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ));
            if (logEnabled)
              logSink.write(DateTime.now().toString() + ': 重新规划路线。\n');
            await _showRoute();
            setState(() {});
          }
        } else if (distanceDest < 5 ||
            (distanceDepa > polylineLength + 5) ||
            distanceNextDest < nextLength) {
          if (logEnabled)
            logSink.write(DateTime.now().toString() + ': 走过一条规划路线。\n');
          setState(() => mapPolylines.removeAt(0));
        }
      }
    }
  }

  ///导航按钮按下功能函数，调用导航设置管理界面
  void _setNavigation() async {
    if (await _manageNaviState()) {
      await _showRoute();
    }
    setState(() {});
  }

  ///定位按钮按下回调函数，弹窗让用户选择目标视角。
  void _setCameraPosition() async {
    late LatLng newLocation;
    if (await showDialog(
            context: context,
            builder: (context) {
              List<Widget> listWidget = <Widget>[
                Card(
                  child: ListTile(
                    title: Text('当前位置'),
                    onTap: () {
                      if (NaviTools.stateLocationReqiurement(context)) {
                        newLocation = userLocation.latLng;
                        Navigator.of(context).pop(true);
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
                      Navigator.of(context).pop(true);
                    },
                  ),
                ));
              }
              return AlertDialog(
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
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              );
            }) ??
        false) {
      await mapController?.moveCamera(
          CameraUpdate.newLatLngZoom(newLocation, DEFAULT_ZOOM),
          duration: 500);
    }
  }

  ///底栏按钮点击回调函数，按点击的底栏项目调出对应activity。
  void _onBarItemTapped(int index) async {
    switch (index) {
      case 0:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MySearchPage()),
        );
        break;
      case 1:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MySettingPage()),
        );
        break;
    }
    setState(() {});
  }

  ///定位权限申请函数
  void _requestLocationPermission() async {
    //申请位置权限
    locatePermissionStatus = await Permission.location.status;
    //用户拒绝则弹窗提示
    if (!locatePermissionStatus.isGranted) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('提示'),
                content: Text('校园导航的大部分功能需要定位权限才能正常工作，请授予定位权限。'),
                actions: <Widget>[
                  TextButton(
                    child: Text('取消'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                    child: Text('确定'),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      locatePermissionStatus =
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
  Future<bool> _manageNaviState() async {
    return await showDialog(
            context: context,
            builder: (context) => StatefulBuilder(
                  builder: (context, _setState) => AlertDialog(
                    title: Text('导航'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          naviState.getStartWidget(_setState),
                          SwitchListTile(
                              value: naviState.startOnUserLoc,
                              title: Text('从当前位置开始'),
                              onChanged: (state) {
                                _setState(() {
                                  naviState.startOnUserLoc = state;
                                  if (!state) naviState.realTime = state;
                                });
                                naviState.start = null;
                                mapMarkers.remove('start');
                              }),
                          SwitchListTile(
                            value: naviState.realTime,
                            title: Text('实时导航'),
                            onChanged: naviState.startOnUserLoc
                                ? (state) =>
                                    _setState(() => naviState.realTime = state)
                                : null,
                          ),
                          LimitedBox(
                            maxHeight: 270,
                            child: SingleChildScrollView(
                              child: naviState.getEndWidget(_setState),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              _setState(() {
                                naviState.start = null;
                                naviState.end.clear();
                              });
                              mapMarkers.removeWhere(
                                  (key, value) => !key.contains('onTap'));
                            },
                            icon: Icon(Icons.delete),
                            label: Text('清除全部地点'),
                          ),
                          SwitchListTile(
                            value: naviState.onbike,
                            title: Text('允许骑车'),
                            onChanged: (state) =>
                                _setState(() => naviState.onbike = state),
                          ),
                          SwitchListTile(
                            value: naviState.minTime,
                            title: Text('最短时间'),
                            onChanged: (state) => _setState(() {
                              naviState.minTime = state;
                              if (!state) naviState.crowding = state;
                            }),
                          ),
                          SwitchListTile(
                            value: naviState.crowding,
                            title: Text('拥挤'),
                            onChanged: naviState.minTime
                                ? (state) =>
                                    _setState(() => naviState.crowding = state)
                                : null,
                          ),
                          Text(
                            '提示：点击可删除起点/终点',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text('取消'),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      TextButton(
                        child: Text('停止'),
                        onPressed: naviState.naviStatus
                            ? () {
                                naviState.naviStatus = false;
                                Navigator.of(context).pop(true);
                              }
                            : null,
                      ),
                      TextButton(
                        child: Text('开始'),
                        onPressed: (naviState.startOnUserLoc ||
                                    naviState.start != null) &&
                                naviState.end.isNotEmpty
                            ? () {
                                naviState.naviStatus = true;
                                Navigator.of(context).pop(true);
                              }
                            : null,
                      ),
                    ],
                  ),
                )) ??
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
    mapPolylines.clear();
    naviState.routeLength = 0;
    //检查导航状态，为开始时绘制路线
    if (naviState.naviStatus) {
      //导航开始时的日期时间，用于智能选择校区间导航方法
      DateTime routeBeginTime = DateTime.now();
      if (logEnabled) {
        logSink.write(routeBeginTime.toString() + ': 开始导航，开始计算路线。\n');
        logSink.write(DateTime.now().toString() +
            ': ' +
            '实时导航' +
            (naviState.realTime ? '开启' : '关闭') +
            '，骑车' +
            (naviState.onbike ? '开启' : '关闭') +
            '。\n');
        logSink.write(DateTime.now().toString() +
            ': ' +
            '最短时间' +
            (naviState.minTime ? '开启' : '关闭') +
            '，拥挤度' +
            (naviState.crowding ? '开启' : '关闭') +
            '。\n');
      }
      //如果是选择以用户当前位置为起点，则判断是否有定位权限，定位是否正常，在不在校区内
      if (naviState.startOnUserLoc) {
        if (NaviTools.stateLocationReqiurement(context)) {
          int startCampus = mapData.locationInCampus(userLocation.latLng);
          if (startCampus >= 0) {
            naviState.start = userLocation.latLng;
            if (logEnabled)
              logSink.write(DateTime.now().toString() + ': 以用户坐标为起点。\n');
          } else {
            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                      title: Text('提示'),
                      content: Text('您不在任何校区内。'),
                      actions: <Widget>[
                        TextButton(
                          child: Text('取消'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ));
            if (logEnabled)
              logSink.write(DateTime.now().toString() + ': 您不在任何校区内，停止导航。\n');
            naviState.naviStatus = false;
            return;
          }
        } else {
          if (logEnabled)
            logSink.write(DateTime.now().toString() + ': 没有定位权限或定位不正常，停止导航。\n');
          naviState.naviStatus = false;
          return;
        }
      }
      if (logEnabled) logSink.write(DateTime.now().toString() + ': 开始目的地排序。\n');
      try {
        //排序所用新列表
        List naviOrder = [naviState.start];
        naviOrder.addAll(naviState.end);
        //终点集合中，坐标以其本身，建筑以特征坐标，按直线距离顺序排序
        for (int i = 0; i < naviOrder.length - 2; ++i) {
          int nextEnd = i + 1;
          double minDistance = double.infinity;
          for (int j = i + 1; j < naviOrder.length; ++j) {
            double curDistance = AMapTools.distanceBetween(
                NaviTools.getLocation(naviOrder[i]),
                NaviTools.getLocation(naviOrder[j]));
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
        int transmethod = naviState.onbike ? 1 : 0;
        naviState.crowding
            ? mapData.randomCrowding()
            : mapData.disableCrowding();
        if (logEnabled) {
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
                    (naviState.onbike ? BIKESPEED : 1)) /
                (naviState.crowding ? 1 - Random().nextDouble() : 1);
            curNaviLoc = NaviLoc(campusNum, nearVertex, naviOrder[i]);
          } else if (naviOrder[i].runtimeType == Building) {
            Building curBuilding = naviOrder[i] as Building;
            campusNum = mapData.buildingInCampus(curBuilding);
            LatLng disReference = i == 0
                ? NaviTools.getLocation(naviOrder[1])
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
                    (naviState.onbike ? BIKESPEED : 1)) /
                (naviState.crowding ? 1 - Random().nextDouble() : 1);
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
                naviState.routeLength += path.getRelativeLen();
                NaviTools.displayRoute(path.getRoute(), startVertex.campusNum);
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
                seconds:
                    (naviState.routeLength + lengthPublicTransStart).toInt(),
              ));
              DateTime timeAtGetOnSchoolBus = routeBeginTime.add(Duration(
                  seconds:
                      (naviState.routeLength + lengthSchoolBusStart).toInt()));
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
                naviState.routeLength += (lengthSchoolBusStart +
                    lengthSchoolBusEnd +
                    (naviState.minTime ? (bestSchoolBus.last as int) * 60 : 0));
                if (routeSchoolBusStart.isNotEmpty)
                  NaviTools.displayRoute(
                      routeSchoolBusStart, startVertex.campusNum);
                if (routeSchoolBusEnd.isNotEmpty)
                  NaviTools.displayRoute(
                      routeSchoolBusEnd, endVertex.campusNum);
                toPrint = (bestSchoolBus.first as BusTimeTable).description;
              } else if (bestPubTrans.isNotEmpty && bestSchoolBus.isEmpty) {
                naviState.routeLength += (lengthPublicTransStart +
                    lengthPublicTransEnd +
                    (naviState.minTime ? (bestPubTrans.last as int) * 60 : 0));
                if (routePublicTransStart.isNotEmpty)
                  NaviTools.displayRoute(
                      routePublicTransStart, startVertex.campusNum);
                if (routePublicTransEnd.isNotEmpty)
                  NaviTools.displayRoute(
                      routePublicTransEnd, endVertex.campusNum);
                toPrint = (bestPubTrans.first as BusTimeTable).description;
              } else {
                if ((lengthSchoolBusStart +
                        lengthSchoolBusEnd +
                        (naviState.minTime
                            ? (bestSchoolBus.last as int) * 60
                            : 0)) >
                    (lengthPublicTransStart +
                        lengthPublicTransEnd +
                        (naviState.minTime
                            ? (bestPubTrans.last as int) * 60
                            : 0))) {
                  naviState.routeLength += (lengthPublicTransStart +
                      lengthPublicTransEnd +
                      (naviState.minTime
                          ? (bestPubTrans.last as int) * 60
                          : 0));
                  if (routePublicTransStart.isNotEmpty)
                    NaviTools.displayRoute(
                        routePublicTransStart, startVertex.campusNum);
                  if (routePublicTransEnd.isNotEmpty)
                    NaviTools.displayRoute(
                        routePublicTransEnd, endVertex.campusNum);
                  toPrint = (bestPubTrans.first as BusTimeTable).description;
                } else {
                  naviState.routeLength += (lengthSchoolBusStart +
                      lengthSchoolBusEnd +
                      (naviState.minTime
                          ? (bestSchoolBus.last as int) * 60
                          : 0));
                  if (routeSchoolBusStart.isNotEmpty)
                    NaviTools.displayRoute(
                        routeSchoolBusStart, startVertex.campusNum);
                  if (routeSchoolBusEnd.isNotEmpty)
                    NaviTools.displayRoute(
                        routeSchoolBusEnd, endVertex.campusNum);
                  toPrint = (bestSchoolBus.first as BusTimeTable).description;
                }
              }
              await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: Text('提示'),
                        content: Text('从$startCampusName移动到$endCampusName，请乘坐' +
                            toPrint +
                            '。'),
                        actions: <Widget>[
                          TextButton(
                            child: Text('取消'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ));
            }
          }
          //该点不是终点，绘制其与连接点间的虚线
          if (i != naviOrder.length - 1) {
            NaviTools.entryRoute(realLatLng, juncLatLng);
            naviState.routeLength += juncLength;
          }
          //该点不是起点，绘制连接点与其之间的虚线
          if (i != 0) {
            NaviTools.entryRoute(juncLatLng, realLatLng);
            naviState.routeLength += juncLength;
          }
        }
        if (logEnabled)
          logSink
              .write(DateTime.now().toString() + ': 狄杰斯特拉算法结束，路线计算函数正常结束。\n');
      } catch (_) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text('提示'),
                  content: Text('未找到路线。请检查地图数据。'),
                  actions: <Widget>[
                    TextButton(
                      child: Text('取消'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ));
        if (logEnabled)
          logSink.write(DateTime.now().toString() + ': 未找到路线。停止导航。\n');
        //路线绘制出现错误，将导航状态设为停止同时清空路线和长度
        naviState.naviStatus = false;
        mapPolylines.clear();
        naviState.routeLength = 0;
      }
    } else {
      if (logEnabled) logSink.write(DateTime.now().toString() + ': 停止导航。\n');
    }
  }

  @override
  void initState() {
    _requestLocationPermission();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AMapWidget map = AMapWidget(
      //高德api Key
      apiKey: amapApiKeys,
      //创建地图回调函数，获得controller。
      onMapCreated: (controller) => mapController = controller,
      //地图初始视角
      initialCameraPosition: CameraPosition(
        bearing: prefs.getDouble('lastCamPositionbearing') ?? 0,
        target: LatLng(prefs.getDouble('lastCamPositionLat') ?? 39.909187,
            prefs.getDouble('lastCamPositionLng') ?? 116.397451),
        zoom: prefs.getDouble('lastCamPositionzoom') ?? DEFAULT_ZOOM,
      ),
      //地图点击回调函数
      onTap: _onMapTapped,
      //地图视角移动回调函数，移除点击添加的标志。
      onCameraMove: (_) => setState(() => mapMarkers.remove('onTap')),
      //地图视角移动结束回调函数
      onCameraMoveEnd: _onCameraMoveEnd,
      //用户位置移动回调函数
      onLocationChanged: _onLocationChanged,
      //开启指南针
      compassEnabled: true,
      //开启显示用户位置功能
      myLocationStyleOptions: MyLocationStyleOptions(true),
      //地图类型，使用卫星地图
      mapType: MapType.satellite,
      //地图上的标志
      markers: Set<Marker>.of(mapMarkers.values),
      //地图上的线
      polylines: Set<Polyline>.of(mapPolylines),
    );

    List<Widget> listWidget = <Widget>[
      map,
    ];
    //如果正在导航则显示路程/时间
    if (naviState.naviStatus) {
      listWidget.add(Positioned(
        left: 18.0,
        child: Chip(label: Text(naviState.getlengthString())),
      ));
    }
    return Scaffold(
      //顶栏
      appBar: AppBar(
        title: Text(widget.title),
      ),
      //中央内容区
      body: Scaffold(
        body: ConstrainedBox(
          constraints: BoxConstraints.expand(),
          child: Stack(
            alignment: Alignment.center,
            children: listWidget,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'locatebtn',
          onPressed: _setCameraPosition,
          tooltip: '切换地图视角' /*'Locate'*/,
          child: Icon(Icons.location_searching),
          mini: true,
        ),
      ),
      //底导航栏
      bottomNavigationBar: BottomNavigationBar(
        items: _navbaritems,
        unselectedItemColor: Colors.blueGrey,
        onTap: _onBarItemTapped,
      ),
      //悬浮按键
      floatingActionButton: FloatingActionButton(
        heroTag: 'navibtn',
        onPressed: _setNavigation,
        tooltip: naviState.naviStatus
            ? '停止导航'
            : '开始导航' /*'Stop Navigation' : 'Start Navigation'*/,
        child: naviState.naviStatus ? Icon(Icons.stop) : Icon(Icons.play_arrow),
      ),
      //悬浮按键位置
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
