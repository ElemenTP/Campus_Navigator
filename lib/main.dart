import 'dart:io';
import 'dart:convert';

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

void main() async {
  //初始化Flutter环境
  WidgetsFlutterBinding.ensureInitialized();
  //获取持久化设置内容
  prefs = await SharedPreferences.getInstance();
  //初始化日志功能
  logEnabled = prefs.getBool('logEnabled') ?? false;
  Directory logFileDir = await getApplicationDocumentsDirectory();
  logFile = File(logFileDir.path + '/NaviLog.txt');
  logSink = logFile.openWrite(mode: FileMode.append);
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
                    onPressed: () => Navigator.of(context).pop(), //关闭对话框
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
                  onPressed: () => Navigator.of(context).pop(), //关闭对话框
                ),
                TextButton(
                  child: Text('起点'),
                  onPressed: naviState.startOnUserLoc
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
                  onPressed: () => Navigator.of(context).pop(), //关闭对话框
                ),
                TextButton(
                  child: Text('确定'),
                  onPressed: () {
                    naviState.start = null;
                    mapMarkers.remove('start');
                    Navigator.of(context).pop();
                  }, //关闭对话框
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
                  onPressed: () => Navigator.of(context).pop(), //关闭对话框
                ),
                TextButton(
                  child: Text('确定'),
                  onPressed: () {
                    naviState.end.remove(mapMarkers[markerid]!.position);
                    mapMarkers.remove(markerid);
                    Navigator.of(context).pop();
                  }, //关闭对话框
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
                      onPressed: () => Navigator.of(context).pop(), //关闭对话框
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
                          onPressed: () => Navigator.of(context).pop(), //关闭对话框
                        ),
                      ],
                    ));
            if (logEnabled)
              logSink.write(DateTime.now().toString() + ': 重新规划路线。\n');
            await NaviTools.showRoute(context);
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
    if (await naviState.manageNaviState(context)) {
      await NaviTools.showRoute(context);
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
