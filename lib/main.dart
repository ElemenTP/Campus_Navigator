//import 'dart:io';

//import 'package:path_provider/path_provider.dart';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart'; //LatLng 类型在这里面
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';
import 'header.dart';
import 'amapapikey.dart'; //高德apikey所在文件
import 'searchpage.dart'; //搜索界面
import 'settingpage.dart'; //设置界面

Set<Marker> markerlist = {};
Set<Polyline> polylineset = {};
Set<Polygon> polygonlist = {};
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  int i = 0;
  mapData = MapData.fromJson(
      jsonDecode(await rootBundle.loadString('mapdata/buildnew.json')));
  mapData.mapVertex[0].listVertex.forEach((element) {
    markerlist.add(Marker(
        position: element,
        infoWindow: InfoWindow(
            title: mapData.mapVertex[0].detail[i++],
            snippet: (i - 1).toString()),
        visible: false));
  });

  mapData.mapEdge[0].listEdge.forEach((element) {
    Polyline polyline = Polyline(points: <LatLng>[
      mapData.mapVertex[0].listVertex[element.pointa],
      mapData.mapVertex[0].listVertex[element.pointb]
    ]);
    polylineset.add(polyline);
  });

  int j = 0;
  mapData.mapVertex[1].listVertex.forEach((element) {
    markerlist.add(Marker(
        position: element,
        infoWindow: InfoWindow(
            title: mapData.mapVertex[1].detail[j++],
            snippet: (j - 1).toString()),
        visible: false));
  });

  Offset a = Offset(mapData.mapVertex[0].listVertex[20].latitude,
      mapData.mapVertex[0].listVertex[20].longitude);
  Offset p1 = Offset(mapData.mapVertex[0].listVertex[3].latitude,
      mapData.mapVertex[0].listVertex[3].longitude);
  Offset p2 = Offset(mapData.mapVertex[0].listVertex[3].latitude,
      mapData.mapVertex[0].listVertex[3].longitude);
  Offset res = AMapTools.getVerticalPointOnLine(a, p1, p2);
  markerlist.add(Marker(
      position: LatLng(res.dx, res.dy),
      infoWindow: InfoWindow(title: "vertical"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)));
  List<LatLng> circlelist = [];
  const int times = 36;
  for (int i = 0; i < times; i++) {
    Offset c = Offset.fromDirection(i * 2 * pi / times, 1 / 1000);
    Offset c1 =
        Offset(res.dx + c.dx, res.dy + c.dy / cos((res.dx + c.dx) / 180 * pi));
    circlelist.add(LatLng(c1.dx, c1.dy));
  }
  Color col = Colors.deepOrange.shade100;

  Polygon circle = Polygon(
      points: circlelist,
      fillColor: Color(0),
      strokeColor: col,
      strokeWidth: 0.4);
  polygonlist.add(circle);
  mapData.mapBuilding.forEach((element) {
    element.listBuilding.forEach((e1) {
      e1.doors.forEach((e2) {
        markerlist.add(Marker(
            position: e2,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange),
            visible: false));
      });
    });
  });

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
  //地图Marker
  Map<String, Marker> _mapMarkers = {};
  //地图直线
  Map<String, Polyline> _mapPolylines = {};
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
  void _onMapTapped(LatLng taplocation) {
    setState(() {
      _mapMarkers['onTapMarker'] =
          Marker(position: taplocation, onTap: _onTapMarkerTapped);
    });
  }

  //标志点击回调函数，显示该标志的坐标。
  void _onTapMarkerTapped(String markerid) {}

  //地图视角改变回调函数，移除所有点击添加的标志。
  void _onMapCamMoved(CameraPosition newPosition) {
    setState(() {
      _mapMarkers.remove('onTapMarker');
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
    userPosition = aMapLocation;
  }

  //导航按钮功能函数
  void _setNavigation() async {
    if (navistate.naviStatus) {
      await showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('提示'),
                content: Text('要停止导航吗？'),
                actions: <Widget>[
                  TextButton(
                    child: Text('取消'),
                    onPressed: () => Navigator.of(context).pop(), //关闭对话框
                  ),
                  TextButton(
                    child: Text('确定'),
                    onPressed: () {
                      _mapPolylines.clear();
                      navistate.reverseState();
                      Navigator.of(context).pop();
                    }, //关闭对话框
                  ),
                ],
              ));
    } else {
      await showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('提示'),
                content: Text('要开始导航吗？'),
                actions: <Widget>[
                  TextButton(
                    child: Text('取消'),
                    onPressed: () => Navigator.of(context).pop(), //关闭对话框
                  ),
                  TextButton(
                    child: Text('确定'),
                    onPressed: () {
                      navistate.reverseState();
                      Navigator.of(context).pop();
                    }, //关闭对话框
                  ),
                ],
              ));
    }
    //翻转导航状态
    setState(() {});
  }

  //定位按钮按下回调函数，将地图widget视角调整至用户位置。
  void _setCamUserLoaction() async {
    //没有定位权限，提示用户授予权限
    if (locatePermissionStatus != PermissionStatus.granted) {
      await showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('提示'),
                content: Text('欲使用此功能，请授予定位权限。'),
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
    //定位不正常（时间time为0），提示用户打开定位开关
    else if (userPosition.time == 0) {
      await showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('提示'),
                content: Text('未开启系统定位开关，或者系统定位出错。'),
                actions: <Widget>[
                  TextButton(
                    child: Text('确定'),
                    onPressed: () => Navigator.of(context).pop(), //关闭对话框
                  ),
                ],
              ));
    } else {
      await mapController?.moveCamera(
          CameraUpdate.newLatLngZoom(userPosition.latLng, 17.5),
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
  void _requestlocationPermission() async {
    // 申请位置权限
    locatePermissionStatus = await Permission.location.status;
    if (!locatePermissionStatus.isGranted) {
      await showDialog(
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

  //获得最后一次地图视角
  /*void _getLastCameraPosition() async {
    await mapController
        ?.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
      bearing: prefs.getDouble('lastCamPositionbearing') ?? 0,
      target: LatLng(prefs.getDouble('lastCamPositionLat') ?? 39.909187,
          prefs.getDouble('lastCamPositionLng') ?? 116.397451),
      zoom: prefs.getDouble('lastCamPositionzoom') ?? 17.5,
    )));
  }*/

  //State创建时执行一次
  @override
  void initState() {
    super.initState();
    //检测并申请定位权限
    _requestlocationPermission();
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
      //markers: Set<Marker>.of(_mapMarkers.values),
      markers: markerlist,
      //地图上的线
      //polylines: Set<Polyline>.of(_mapPolylines.values),
      polylines: polylineset,
      polygons: polygonlist,
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
          onPressed: _setCamUserLoaction,
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
