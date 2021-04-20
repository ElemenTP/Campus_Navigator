import 'dart:async';
//import 'dart:io';
//import 'header.dart';
//import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart'; //LatLng 类型在这里面
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'amapapikey.dart'; //高德apikey所在文件
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:amap_flutter_location/amap_location_option.dart';

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
  LatLng userPosition = LatLng(39.909187, 116.397451);
  //构建地图时的初始视角
  //CameraPosition _initialCameraPosition =
  //CameraPosition(target: LatLng(39.909187, 116.397451), zoom: 17.5);
  //卫星地图审图号
  String _satelliteImageApprovalNumber;
  //文字风格
  static const TextStyle _optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  //当前所选页面，默认为第二页
  int _selectedpage = 1;
  //底栏项目List
  static const List<BottomNavigationBarItem> _navbaritems = [
    //搜索标志
    BottomNavigationBarItem(
      icon: Icon(Icons.search),
      label: 'Search',
    ),
    //地图标志
    BottomNavigationBarItem(
      icon: Icon(Icons.map),
      label: 'Map',
    ),
    //设置标志
    BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: 'Settings',
    )
  ];

  //Map<String, Object> _locationResult;

  StreamSubscription<Map<String, Object>> _locationListener;

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

  void _refreashMap() {
    setState(() {
      //反转指南针开关并通知重新绘制界面
      //_compassEnabled = _compassEnabled ^ true;
      _selectedpage = 1;
    });
  }

  void _onBarItemTapped(int index) {
    setState(() {
      //按所低栏所选项目改变页面并通知重新绘制界面
      _selectedpage = index;
    });
  }

/*
  void _genMapCameraPosition() {
    if (_locationResult != null) {
      if (_locationResult.containsKey('latitude') &&
          _locationResult.containsKey('longitude')) {
        _initialCameraPosition = CameraPosition(
            target: LatLng(
                _locationResult['latitude'], _locationResult['longitude']),
            zoom: 17.5);
      }
    }
  }
*/
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

  ///开始定位
  void _startLocation() {
    if (null != _locationPlugin) {
      ///开始定位之前设置定位参数
      _setLocationOption();
      _locationPlugin.startLocation();
    }
  }

  ///停止定位
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

    /// 动态申请定位权限
    requestlocationPermission();

    ///注册定位结果监听
    _locationListener = _locationPlugin
        .onLocationChanged()
        .listen((Map<String, Object> result) {
      setState(() {
        //_locationResult = result;
        userPosition = LatLng(result['latitude'], result['longitude']);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();

    ///移除定位监听
    if (null != _locationListener) {
      _locationListener.cancel();
    }

    ///销毁定位
    if (null != _locationPlugin) {
      _locationPlugin.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    //_startLocation();
    switch (_selectedpage) {
      case 0:
        _stopLocation();
        content = Text(
          'No items yet!',
          style: _optionStyle,
        );
        break;

      case 1:
        _startLocation();
        content = AMapWidget(
          apiKey: amapApiKeys,
          initialCameraPosition:
              CameraPosition(target: userPosition, zoom: 17.5),
          onMapCreated: onMapCreated,
          compassEnabled: true, //_compassEnabled,
          mapType: MapType.satellite,
        );
        getApprovalNumber();
        break;

      case 2:
        _stopLocation();
        content = Text(
          '卫星地图审图号：' + '$_satelliteImageApprovalNumber',
          style: _optionStyle,
        );
        break;
    }
/*
    ///创建一个地图
    final AMapWidget map = AMapWidget(
      apiKey: amapApiKeys,
      initialCameraPosition: _initialCameraPosition,
      onMapCreated: onMapCreated,
      compassEnabled: true, //_compassEnabled,
      mapType: MapType.satellite,
    );
    //不同页面的widget列表
    final List<Widget> _wigetpages = [
      Text(
        'No items yet!',
        style: _optionStyle,
      ),
      map,
      Text(
        '卫星地图审图号：' + '$_satelliteImageApprovalNumber',
        style: _optionStyle,
      )
    ];
*/
    return Scaffold(
      //顶栏
      appBar: AppBar(
        title: Text(widget.title),
      ),
      //中央内容区
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: content,
      ),
      //底导航栏
      bottomNavigationBar: BottomNavigationBar(
        items: _navbaritems,
        currentIndex: _selectedpage,
        selectedItemColor: Colors.blueGrey,
        onTap: _onBarItemTapped,
      ),
      //悬浮按键
      floatingActionButton: FloatingActionButton(
        onPressed: _refreashMap,
        tooltip: 'Navigation Start',
        child: Icon(Icons.play_arrow),
      ),
      //悬浮按键位置
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
