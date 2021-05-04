//import 'dart:io';

//import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart'; //LatLng 类型在这里面
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:permission_handler/permission_handler.dart';

//import 'header.dart';
import 'amapapikey.dart'; //高德apikey所在文件
import 'searchpage.dart'; //搜索界面
import 'settingpage.dart'; //设置界面

void main() {
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
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //高德地图widget的回调
  AMapController _mapController;
  //地图初始视角
  CameraPosition _initCameraPosition;
  //用户位置
  AMapLocation _userPosition =
      AMapLocation(latLng: LatLng(39.909187, 116.397451));
  //定位权限状态
  PermissionStatus _locatePermissionStatus;
  //地图Marker
  Map<String, Marker> _mapMarkers = {};
  //地图直线
  Map<String, Polyline> _mapPolylines = {};
  //卫星地图审图号
  String _satelliteImageApprovalNumber;
  //导航状态
  bool _navistate = false;
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

  //地图widget创建时的回调函数，获得controller并获得审图号。
  void _onMapCreated(AMapController controller) {
    setState(() {
      _mapController = controller;
      _getApprovalNumber();
    });
  }

  //地图点击回调函数，在被点击处创建标志。
  void _onMapTapped(LatLng taplocation) {
    setState(() {
      _mapMarkers['onTapMarker'] =
          Marker(position: taplocation, onTap: _onTapMarkerTapped);
    });
  }

  //标志点击回调函数，显示该标志的坐标。
  void _onTapMarkerTapped(String markerid) {
    Fluttertoast.showToast(
      msg:
          '${_mapMarkers['onTapMarker'].position.latitude} + ${_mapMarkers['onTapMarker'].position.longitude}',
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16,
    );
  }

  //地图视角改变回调函数，移除所有点击添加的标志。
  void _onMapCamMoved(CameraPosition newPosition) {
    setState(() {
      _mapMarkers.remove('onTapMarker');
    });
  }

  //地图视角改变结束回调函数，将视角信息记录在NVM中。
  void _onCameraMoveEnd(CameraPosition endPosition) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble('lastCamPositionbearing', endPosition.bearing);
    prefs.setDouble('lastCamPositionLat', endPosition.target.latitude);
    prefs.setDouble('lastCamPositionLng', endPosition.target.longitude);
    prefs.setDouble('lastCamPositionzoom', endPosition.zoom);
  }

  //用户位置改变回调函数，记录用户位置。
  void _onLocationChanged(AMapLocation aMapLocation) {
    _userPosition = aMapLocation;
  }

  //获取审图号函数
  void _getApprovalNumber() async {
    //按要求获取卫星地图审图号
    _satelliteImageApprovalNumber =
        await _mapController?.getSatelliteImageApprovalNumber();
  }

  //导航按钮功能函数
  void _setNavigation() {
    setState(() {
      if (_navistate) {
        _mapPolylines.clear();
        Fluttertoast.showToast(
          msg: '导航结束',
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16,
        );
      } else {
        List<LatLng> points = [
          LatLng(40.15680947715327, 116.2841939815524),
          LatLng(40.15775245451647, 116.2877612783767),
          LatLng(40.15814809111908, 116.2892995252204),
          LatLng(40.15674285325732, 116.2899499608954),
        ];
        Polyline polyline = Polyline(
          points: points,
          joinType: JoinType.round,
          capType: CapType.arrow,
          color: Color(0xCC2196F3),
        );
        _mapPolylines[polyline.id] = polyline;
        Fluttertoast.showToast(
          msg: '导航开始',
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16,
        );
      }
      //翻转导航状态
      _navistate = !_navistate;
    });
  }

  //定位按钮按下回调函数，将地图widget视角调整至用户位置。
  void _setCamUserLoaction() async {
    //没有定位权限，提示用户授予权限
    if (_locatePermissionStatus != PermissionStatus.granted)
      Fluttertoast.showToast(
        msg: '欲使用此功能，请授予定位权限。',
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16,
      );
    //定位不正常（时间time为0），提示用户打开定位开关
    else if (_userPosition.time == 0) {
      Fluttertoast.showToast(
        msg: '欲使用此功能，请打开系统定位开关。',
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16,
      );
    } else {
      await _mapController.moveCamera(
          CameraUpdate.newLatLngZoom(_userPosition.latLng, 17.5),
          animated: true);
    }
  }

  //底栏按钮点击回调函数
  void _onBarItemTapped(int index) {
    //按点击的底栏项目调出对应activity
    switch (index) {
      case 0:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => MySearchPage()));
        break;
      case 1:
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => MySettingPage(
                    satelliteImageApprovalNumber:
                        _satelliteImageApprovalNumber)));
        break;
    }
  }

  //定位权限申请函数
  void _requestlocationPermission() async {
    // 申请位置权限
    _locatePermissionStatus = await Permission.location.status;
    if (_locatePermissionStatus != PermissionStatus.granted)
      _locatePermissionStatus = await Permission.location.request();
    if (_locatePermissionStatus != PermissionStatus.granted)
      Fluttertoast.showToast(
        msg:
            '大部分功能需要定位权限才能正常工作！' /*'This application needs location permission to work properly!'*/,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16,
      );
  }

  //获得最后一次地图视角
  void _getLastCameraPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _initCameraPosition = CameraPosition(
      bearing: prefs.getDouble('lastCamPositionbearing') ?? 0,
      target: LatLng(prefs.getDouble('lastCamPositionLat') ?? 39.909187,
          prefs.getDouble('lastCamPositionLng') ?? 116.397451),
      zoom: prefs.getDouble('lastCamPositionzoom') ?? 17.5,
    );
  }

  //State创建时执行一次
  @override
  void initState() {
    super.initState();
    //检测并申请定位权限
    _requestlocationPermission();
    //获取最后一次地图视角
    _getLastCameraPosition();
  }

  //State的build函数
  @override
  Widget build(BuildContext context) {
    AMapWidget map = AMapWidget(
      //高德api Key
      apiKey: amapApiKeys,
      //创建地图回调函数
      onMapCreated: _onMapCreated,
      //地图点击回调函数
      onTap: _onMapTapped,
      //地图视角移动回调函数
      onCameraMove: _onMapCamMoved,
      //地图视角移动结束回调函数
      onCameraMoveEnd: _onCameraMoveEnd,
      //用户位置移动回调函数
      onLocationChanged: _onLocationChanged,
      //地图初始视角，为最后一次的视角，默认为天安门广场
      initialCameraPosition: _initCameraPosition,
      //开启指南针
      compassEnabled: true,
      //开启显示用户位置功能
      myLocationStyleOptions: MyLocationStyleOptions(true),
      //地图类型，使用卫星地图
      mapType: MapType.satellite,
      //地图上的标志
      markers: Set<Marker>.of(_mapMarkers.values),
      //地图上的线
      polylines: Set<Polyline>.of(_mapPolylines.values),
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
        tooltip: _navistate
            ? '停止导航'
            : '开始导航' /*'Stop Navigation' : 'Start Navigation'*/,
        child: _navistate ? Icon(Icons.stop) : Icon(Icons.play_arrow),
      ),
      //悬浮按键位置
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
