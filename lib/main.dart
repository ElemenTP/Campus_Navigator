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
import 'searchpage.dart';
import 'settingpage.dart'; //搜索界面

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
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
  LatLng userPosition;
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

  void onMapCreated(AMapController controller) {
    setState(() {
      _mapController = controller;
    });
  }

  void getApprovalNumber() async {
    //按要求卫星地图审图号
    _satelliteImageApprovalNumber =
        await _mapController?.getSatelliteImageApprovalNumber();
  }

  void _setNavigation() {
    setState(() {
      _navistate = !_navistate;
    });
  }

  void _onBarItemTapped(int index) {
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

  void requestlocationPermission() async {
    // 申请位置权限
    var status = await Permission.location.status;
    if (status != PermissionStatus.granted)
      status = await Permission.location.request();
    if (status != PermissionStatus.granted)
      Fluttertoast.showToast(
        msg: '大部分功能需要定位权限才能正常工作！',
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
    requestlocationPermission();

    //注册定位结果监听
    _locationListener = _locationPlugin
        .onLocationChanged()
        .listen((Map<String, Object> result) {
      setState(() {
        //_locationResult = result;
        userPosition = LatLng(result['latitude'], result['longitude']);
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
      onMapCreated: onMapCreated,
      initialCameraPosition:
          CameraPosition(target: LatLng(39.909187, 116.397451), zoom: 17.5),
      compassEnabled: true, //_compassEnabled,
      mapType: MapType.satellite,
    );
    getApprovalNumber();

    return Scaffold(
      //顶栏
      appBar: AppBar(
        title: Text(widget.title),
      ),
      //中央内容区
      body: Center(
        child: map,
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
