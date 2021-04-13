import 'package:flutter/material.dart';
//import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
//import 'package:amap_flutter_location/amap_flutter_location.dart';
//import 'package:amap_flutter_location/amap_location_option.dart';

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
  //LatLng _location = LatLng(39.909187, 116.397451);
  //测试用，地图指南针开关
  bool _compassEnabled = true;
  //卫星地图审图号
  String satelliteImageApprovalNumber;
  //文字风格
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  //当前所选页面，默认为第二页
  int _selectedpage = 1;
  //底栏项目List
  List<BottomNavigationBarItem> _navbaritems = [
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

  void onMapCreated(AMapController controller) {
    setState(() {
      _mapController = controller;
      getApprovalNumber();
    });
  }

  void getApprovalNumber() async {
    //按要求卫星地图审图号
    satelliteImageApprovalNumber =
        await _mapController?.getSatelliteImageApprovalNumber();
    setState(() {});
  }

  void _refreashMap() {
    setState(() {
      //反转指南针开关并通知重新绘制界面
      _compassEnabled = _compassEnabled ^ true;
    });
  }

  void _onBarItemTapped(int index) {
    setState(() {
      //按所低栏所选项目改变页面并通知重新绘制界面
      _selectedpage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    ///创建一个地图
    final AMapWidget map = AMapWidget(
      //apiKey: amapApiKeys,
      onMapCreated: onMapCreated,
      compassEnabled: _compassEnabled,
      mapType: MapType.satellite,
    );
    //不同页面的widget列表
    final List<Widget> _wigetpages = [
      Text(
        'No items yet!',
        style: optionStyle,
      ),
      map,
      Text(
        '卫星地图审图号：' + '$satelliteImageApprovalNumber',
        style: optionStyle,
      )
    ];

    //final AMapFlutterLocation locate = AMapFlutterLocation();
    return Scaffold(
      //顶栏
      appBar: AppBar(
        title: Text(widget.title),
      ),
      //中央内容区
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: _wigetpages[_selectedpage],
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
