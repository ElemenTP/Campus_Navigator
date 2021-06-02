import 'dart:io';

//import 'package:path_provider/path_provider.dart';
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
  String? filedir = prefs.getString('filedir');
  if (filedir == null) {
    mapData = MapData.fromJson(
        jsonDecode(await rootBundle.loadString('mapdata/default.json')));
  } else {
    File datafile = File(filedir);
    mapData = MapData.fromJson(jsonDecode(await datafile.readAsString()));
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
    if (mapData.locationisallowed(taplocation)) {
      setState(() {
        mapMarkers['onTapMarker'] =
            Marker(position: taplocation, onTap: _onTapMarkerTapped);
      });
    } else {
      await showDialog(
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
                          _addStartLocation(
                              mapMarkers['onTapMarker']!.position);
                          mapMarkers.remove('onTapMarker');
                          Navigator.of(context).pop(true);
                        }, //关闭对话框
                ),
                TextButton(
                  child: Text('终点'),
                  onPressed: () {
                    _addEndLocation(mapMarkers['onTapMarker']!.position);
                    mapMarkers.remove('onTapMarker');
                    Navigator.of(context).pop(true);
                  }, //关闭对话框
                ),
              ],
            ));
    setState(() {});
  }

  //从地图上添加坐标形式的出发地
  void _addStartLocation(LatLng location) {
    navistate.startBuilding = null;
    navistate.startLocation = location;
    mapMarkers['startLocationMarker'] = Marker(
      position: location,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      onTap: (markerid) => _onStartMarkerTapped(),
    );
  }

  //从地图上添加坐标形式的目的地
  void _addEndLocation(LatLng location) {
    if (!navistate.endLocation.contains(location)) {
      navistate.endLocation.add(location);
      String tmpid = 'endLocationMarker' + location.toJson().toString();
      mapMarkers[tmpid] = Marker(
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        onTap: (markerid) => _onEndMarkerTapped(tmpid),
      );
    }
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
                    navistate.startLocation = null;
                    mapMarkers.remove('startLocationMarker');
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
                    navistate.endLocation
                        .remove(mapMarkers[markerid]!.position);
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
      mapMarkers.remove('onTapMarker');
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
    if (await navistate.manageNaviState(context)) {}
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
