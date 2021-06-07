import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart'; //LatLng 类型在这里面
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:permission_handler/permission_handler.dart';

import 'header.dart';
import 'amapapikey.dart'; //高德apikey所在文件
import 'searchpage.dart'; //搜索界面
import 'settingpage.dart'; //设置界面

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  logEnabled = prefs.getBool('logEnabled') ?? false;
  Directory logFileDir = await getApplicationDocumentsDirectory();
  logFile = File(logFileDir.path + '/NaviLog.txt');
  logSink = logFile.openWrite(mode: FileMode.append);
  String? filedir = prefs.getString('filedir');
  if (filedir == null) {
    mapData = MapData.fromJson(
        jsonDecode(await rootBundle.loadString('mapdata/default.json')));
    if (logEnabled) logSink.write(DateTime.now().toString() + ': 读取默认地图数据。\n');
  } else {
    File datafile = File(filedir);
    mapData = MapData.fromJson(jsonDecode(await datafile.readAsString()));
    if (logEnabled)
      logSink.write(DateTime.now().toString() + ': 读取地图数据' + filedir + '\n');
  }
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

class _MyHomePageState extends State<MyHomePage> {
  //底栏项目List
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

  //地图widget创建时的回调函数，获得controller并将调节视角。
  void _onMapCreated(AMapController controller) {
    mapController = controller;
  }

  //地图点击回调函数，在被点击处创建标志。
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
                    onPressed: () => Navigator.of(context).pop(), //关闭对话框
                  ),
                ],
              ));
    }
  }

  //标志点击回调函数
  void _onTapMarkerTapped(String markerid) async {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('坐标'),
              content: Text('将坐标设为'),
              actions: <Widget>[
                TextButton(
                  child: Text('取消'),
                  onPressed: () => Navigator.of(context).pop(), //关闭对话框
                ),
                TextButton(
                  child: Text('起点'),
                  onPressed: navistate.startOnUserLoc
                      ? null
                      : () {
                          _addStartLocation(mapMarkers['onTap']!.position);
                          mapMarkers.remove('onTap');
                          Navigator.of(context).pop(true);
                        }, //关闭对话框
                ),
                TextButton(
                  child: Text('终点'),
                  onPressed: () {
                    _addEndLocation(mapMarkers['onTap']!.position);
                    mapMarkers.remove('onTap');
                    Navigator.of(context).pop(true);
                  }, //关闭对话框
                ),
              ],
            ));
    setState(() {});
  }

  //从地图上添加坐标形式的出发地
  void _addStartLocation(LatLng location) {
    navistate.start = location;
    mapMarkers['start'] = Marker(
      position: location,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      onTap: (_) => _onStartMarkerTapped(),
    );
  }

  //从地图上添加坐标形式的目的地
  void _addEndLocation(LatLng location) {
    navistate.end.add(location);
    String tmpid = 'end' + location.hashCode.toString();
    mapMarkers[tmpid] = Marker(
      position: location,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      onTap: (_) => _onEndMarkerTapped(tmpid),
    );
  }

  //出发地Marker点击回调
  void _onStartMarkerTapped() async {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('删除起点'),
              content: Text('删除起点吗？'),
              actions: <Widget>[
                TextButton(
                  child: Text('取消'),
                  onPressed: () => Navigator.of(context).pop(), //关闭对话框
                ),
                TextButton(
                  child: Text('确定'),
                  onPressed: () {
                    navistate.start = null;
                    mapMarkers.remove('start');
                    Navigator.of(context).pop();
                  }, //关闭对话框
                ),
              ],
            ));
    setState(() {});
  }

  //目的地Marker点击回调
  void _onEndMarkerTapped(String markerid) async {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('删除终点'),
              content: Text('删除终点吗？'),
              actions: <Widget>[
                TextButton(
                  child: Text('取消'),
                  onPressed: () => Navigator.of(context).pop(), //关闭对话框
                ),
                TextButton(
                  child: Text('确定'),
                  onPressed: () {
                    navistate.end.remove(mapMarkers[markerid]!.position);
                    mapMarkers.remove(markerid);
                    Navigator.of(context).pop();
                  }, //关闭对话框
                ),
              ],
            ));
    setState(() {});
  }

  //地图视角改变回调函数，移除所有点击添加的标志。
  void _onMapCamMoved(CameraPosition newPosition) {
    setState(() {
      mapMarkers.remove('onTap');
    });
  }

  //地图视角改变结束回调函数，将视角信息记录在NVM中。
  void _onCameraMoveEnd(CameraPosition endPosition) {
    prefs.setDouble('lastCamPositionbearing', endPosition.bearing);
    prefs.setDouble('lastCamPositionLat', endPosition.target.latitude);
    prefs.setDouble('lastCamPositionLng', endPosition.target.longitude);
    prefs.setDouble('lastCamPositionzoom', endPosition.zoom);
  }

  //用户位置改变回调函数，记录用户位置。
  void _onLocationChanged(AMapLocation aMapLocation) {
    userLocation = aMapLocation;
  }

  //导航按钮功能函数
  void _setNavigation() async {
    if (await navistate.manageNaviState(context)) {
      if (navistate.naviStatus) {
        mapPolylines.clear();
        navistate.routeLength.clear();
        bool showRouteResult = false;
        try {
          showRouteResult = await showRoute(context);
        } catch (_) {
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: Text('提示'),
                    content: Text('未找到路线。请检查地图数据。'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('取消'),
                        onPressed: () => Navigator.of(context).pop(), //关闭对话框
                      ),
                    ],
                  ));
          if (logEnabled)
            logSink.write(DateTime.now().toString() + ': 未找到路线。请检查地图数据。\n');
        }
        if (!showRouteResult) {
          navistate.naviStatus = false;
          if (logEnabled)
            logSink.write(DateTime.now().toString() + ': 停止导航。\n');
          mapPolylines.clear();
          navistate.routeLength.clear();
        }
      } else {
        mapPolylines.clear();
        navistate.routeLength.clear();
      }
    }
    setState(() {});
  }

  //定位按钮按下回调函数，将地图widget视角调整至用户位置。
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
                      if (stateLocationReqiurement(context)) {
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
                    title: Text(mapData.mapCampus[i].name),
                    onTap: () {
                      newLocation =
                          mapData.getVertexLatLng(i, mapData.mapCampus[i].gate);
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
                    onPressed: () => Navigator.of(context).pop(false), //关闭对话框
                  ),
                ],
              );
            }) ??
        false) {
      await mapController?.moveCamera(
          CameraUpdate.newLatLngZoom(newLocation, 17.5),
          duration: 500);
    }
  }

  //底栏按钮点击回调函数
  void _onBarItemTapped(int index) async {
    //按点击的底栏项目调出对应activity
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

  //定位权限申请函数
  void _requestLocationPermission() async {
    // 申请位置权限
    locatePermissionStatus = await Permission.location.status;
    if (!locatePermissionStatus.isGranted) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('提示'),
                content: Text('校园导航的大部分功能需要定位权限才能正常工作，请授予定位权限。'),
                actions: <Widget>[
                  TextButton(
                    child: Text('取消'),
                    onPressed: () => Navigator.of(context).pop(), //关闭对话框
                  ),
                  TextButton(
                    child: Text('确定'),
                    onPressed: () async {
                      locatePermissionStatus =
                          await Permission.location.request();
                      Navigator.of(context).pop();
                    }, //关闭对话框
                  ),
                ],
              ));
    }
  }

  //State创建时执行一次
  @override
  void initState() {
    //检测并申请定位权限
    _requestLocationPermission();
    super.initState();
  }

  //State的build函数
  @override
  Widget build(BuildContext context) {
    AMapWidget map = AMapWidget(
      //高德api Key
      apiKey: amapApiKeys,
      //创建地图回调函数
      onMapCreated: _onMapCreated,
      //地图初始视角
      initialCameraPosition: CameraPosition(
        bearing: prefs.getDouble('lastCamPositionbearing') ?? 0,
        target: LatLng(prefs.getDouble('lastCamPositionLat') ?? 39.909187,
            prefs.getDouble('lastCamPositionLng') ?? 116.397451),
        zoom: prefs.getDouble('lastCamPositionzoom') ?? 17.5,
      ),
      //地图点击回调函数
      onTap: _onMapTapped,
      //地图视角移动回调函数
      onCameraMove: _onMapCamMoved,
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
      polylines: Set<Polyline>.of(mapPolylines.values),
    );

    return Scaffold(
      //顶栏
      appBar: AppBar(
        title: Text(widget.title),
      ),
      //中央内容区
      body: Scaffold(
        body: map,
        floatingActionButton: FloatingActionButton(
          heroTag: 'locatebtn',
          onPressed: _setCameraPosition,
          tooltip: '回到当前位置' /*'Locate'*/,
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
        tooltip: navistate.naviStatus
            ? '停止导航'
            : '开始导航' /*'Stop Navigation' : 'Start Navigation'*/,
        child: navistate.naviStatus ? Icon(Icons.stop) : Icon(Icons.play_arrow),
      ),
      //悬浮按键位置
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
