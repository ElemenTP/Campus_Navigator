import 'dart:async';
//import 'dart:io';

//import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart'; //LatLng 类型在这里面
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:amap_flutter_location/amap_location_option.dart';

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
      title: 'CampNavi',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: MyHomePage(title: 'Campus Navigator'),
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
  //用户位置
  LatLng _userPosition = LatLng(39.909187, 116.397451);
  //地图Marker
  Map<String, Marker> _mapMarkers = {};
  //卫星地图审图号
  String _satelliteImageApprovalNumber;
  //导航状态
  bool _navistate = false;
  //底栏项目List
  static const List<BottomNavigationBarItem> _navbaritems = [
    //搜索标志
    BottomNavigationBarItem(
      icon: Icon(Icons.search),
      label: 'Search',
    ),
    //设置标志
    BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: 'Settings',
    )
  ];
  //定位数据监听类
  StreamSubscription<Map<String, Object>> _locationListener;
  //初始化高德地图定位组件
  AMapFlutterLocation _locationPlugin = new AMapFlutterLocation();

  void _onMapCreated(AMapController controller) {
    setState(() {
      _mapController = controller;
      _getApprovalNumber();
    });
  }

  void _onMapTapped(LatLng taplocation) {
    setState(() {
      _mapMarkers['onTapMarker'] =
          Marker(position: taplocation, onTap: _onTapMarkerTapped);
    });
  }

  void _onTapMarkerTapped(String markerid) {
    Fluttertoast.showToast(
      msg:
          '${_mapMarkers['onTapMarker'].position.latitude} + ${_mapMarkers['onTapMarker'].position.longitude}',
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16,
    );
  }

  void _onMapCamMoved(CameraPosition newposition) {
    setState(() {
      _mapMarkers.remove('onTapMarker');
    });
  }

  void _getApprovalNumber() async {
    //按要求获取卫星地图审图号
    _satelliteImageApprovalNumber =
        await _mapController?.getSatelliteImageApprovalNumber();
  }

  void _setNavigation() {
    setState(() {
      _navistate = !_navistate;
    });
  }

  void _setCamUserLoaction() async {
    await _mapController.moveCamera(
        CameraUpdate.newLatLngZoom(_userPosition, 17.5),
        animated: true);
  }

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

  void _requestlocationPermission() async {
    // 申请位置权限
    var status = await Permission.location.status;
    if (status != PermissionStatus.granted)
      status = await Permission.location.request();
    if (status != PermissionStatus.granted)
      Fluttertoast.showToast(
        msg: 'This application needs location permission to work properly!',
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16,
      );
  }

  //开始定位
  void _startLocation() {
    if (null != _locationPlugin) {
      //开始定位之前设置定位参数
      _setLocationOption();
      _locationPlugin.startLocation();
    }
  }

  //停止定位
  void _stopLocation() {
    if (null != _locationPlugin) {
      _locationPlugin.stopLocation();
    }
  }

  void _setLocationOption() {
    if (null != _locationPlugin) {
      AMapLocationOption locationOption = new AMapLocationOption();
      //设置Android端连续定位的定位间隔
      locationOption.locationInterval = 1000;
      locationOption.needAddress = false;
      //将定位参数设置给定位插件
      _locationPlugin.setLocationOption(locationOption);
    }
  }

  @override
  void initState() {
    super.initState();

    AMapFlutterLocation.setApiKey(amapApiKeys.androidKey, '');

    // 动态申请定位权限
    _requestlocationPermission();

    //注册定位结果监听
    _locationListener = _locationPlugin
        .onLocationChanged()
        .listen((Map<String, Object> result) {
      setState(() {
        //_locationResult = result;
        _userPosition = LatLng(result['latitude'], result['longitude']);
        _mapMarkers['userMarker'] = Marker(position: _userPosition);
      });
    });

    //开始定位
    _startLocation();
  }

  @override
  void dispose() {
    super.dispose();

    //停止定位
    _stopLocation();

    //移除定位监听
    if (null != _locationListener) {
      _locationListener.cancel();
    }

    //销毁定位
    if (null != _locationPlugin) {
      _locationPlugin.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    AMapWidget map = AMapWidget(
      apiKey: amapApiKeys,
      onMapCreated: _onMapCreated,
      onTap: _onMapTapped,
      onCameraMove: _onMapCamMoved,
      initialCameraPosition:
          CameraPosition(target: LatLng(39.909187, 116.397451), zoom: 17.5),
      compassEnabled: true, //_compassEnabled,
      mapType: MapType.satellite,
      markers: Set<Marker>.of(_mapMarkers.values),
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
          onPressed: _setCamUserLoaction,
          tooltip: 'Locate',
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
        onPressed: _setNavigation,
        tooltip: _navistate ? 'Stop Navigation' : 'Start Navigation',
        child: _navistate ? Icon(Icons.stop) : Icon(Icons.play_arrow),
      ),
      //悬浮按键位置
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
