import 'dart:io';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart'; //LatLng 类型在这里面
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:permission_handler/permission_handler.dart';

import 'amapapikey.dart'; //高德apikey所在文件

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
  MyHomePage({Key key = const Key('main'), this.title = 'main'})
      : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //高德地图widget的回调
  AMapController? _mapController;
  //用户位置
  AMapLocation _userPosition =
      AMapLocation(latLng: LatLng(39.909187, 116.397451));
  //定位权限状态
  PermissionStatus _locatePermissionStatus = PermissionStatus.denied;
  //地图Marker
  Map<String, Marker> _mapMarkers = {};
  //地图直线
  Map<String, Polyline> _mapPolylines = {};
  //导航状态
  NaviState _navistate = NaviState();
  //采集的地图点集数据
  MapVertex _mapVertex = MapVertex();
  //底栏项目List
  static const List<BottomNavigationBarItem> _navbaritems = [
    //搜索标志
    BottomNavigationBarItem(
      icon: Icon(Icons.save),
      label: '保存' /*'Search'*/,
    ),
    //设置标志
    BottomNavigationBarItem(
      icon: Icon(Icons.delete),
      label: '回退' /*'Setting'*/,
    )
  ];

  //地图widget创建时的回调函数，获得controller并将调节视角。
  void _onMapCreated(AMapController controller) {
    _mapController = controller;
    _getLastCameraPosition();
  }

  //地图点击回调函数，在被点击处创建标志。
  void _onMapTapped(LatLng taplocation) {
    setState(() {
      _mapMarkers['onTapMarker'] =
          Marker(position: taplocation, onTap: _onTapMarkerTapped);
    });
  }

  //标志点击回调函数，记录该标志的坐标。
  void _onTapMarkerTapped(String markerid) async {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('提示'),
              content: Text('要记录该点吗？已有 ${_mapVertex.listVertex.length} 个点。'),
              actions: <Widget>[
                TextButton(
                  child: Text('取消'),
                  onPressed: () => Navigator.of(context).pop(), //关闭对话框
                ),
                TextButton(
                  child: Text('确定'),
                  onPressed: () {
                    LatLng tmp = _mapMarkers['onTapMarker']!.position;
                    _mapVertex.listVertex.add(tmp);
                    _mapMarkers.remove('onTapMarker');
                    Navigator.of(context).pop();
                  }, //关闭对话框
                ),
              ],
            ));
    setState(() {});
  }

  void _onStoredVertexMarkerTapped(String markerid) async {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('提示'),
              content: Text('要删除该点吗？已有 ${_mapVertex.listVertex.length} 个点。'),
              actions: <Widget>[
                TextButton(
                  child: Text('取消'),
                  onPressed: () => Navigator.of(context).pop(), //关闭对话框
                ),
                TextButton(
                  child: Text('确定'),
                  onPressed: () {
                    _mapVertex.listVertex
                        .remove(_mapMarkers[markerid]!.position);
                    _mapMarkers.remove(markerid);
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

  //导航按钮功能函数
  void _setNavigation() async {
    if (_navistate.naviStatus) {
      await showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('提示'),
                content: Text('取消显示所有点吗？'),
                actions: <Widget>[
                  TextButton(
                    child: Text('取消'),
                    onPressed: () => Navigator.of(context).pop(), //关闭对话框
                  ),
                  TextButton(
                    child: Text('确定'),
                    onPressed: () {
                      _mapMarkers
                          .removeWhere((key, value) => key != 'onTapMarker');
                      _navistate.reverseState();
                      Navigator.of(context).pop();
                    }, //关闭对话框
                  ),
                ],
              ));
    } else {
      if (_mapVertex.listVertex.isEmpty) {
        await showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text('提示'),
                  content: Text('没有点可以显示。'),
                  actions: <Widget>[
                    TextButton(
                      child: Text('取消'),
                      onPressed: () => Navigator.of(context).pop(), //关闭对话框
                    ),
                  ],
                ));
      } else {
        await showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text('提示'),
                  content: Text('要显示所有点吗？'),
                  actions: <Widget>[
                    TextButton(
                      child: Text('取消'),
                      onPressed: () => Navigator.of(context).pop(), //关闭对话框
                    ),
                    TextButton(
                      child: Text('确定'),
                      onPressed: () {
                        int counter = 0;
                        _mapVertex.listVertex.forEach((element) {
                          Marker tmp = Marker(
                            position: element,
                            onTap: _onStoredVertexMarkerTapped,
                            infoWindow: InfoWindow(title: counter.toString()),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueGreen),
                          );
                          _mapMarkers[tmp.id] = tmp;
                          counter++;
                        });
                        _navistate.reverseState();
                        Navigator.of(context).pop();
                      }, //关闭对话框
                    ),
                  ],
                ));
      }
    }
    //翻转导航状态
    setState(() {});
  }

  //定位按钮按下回调函数，将地图widget视角调整至用户位置。
  void _setCamUserLoaction() async {
    //没有定位权限，提示用户授予权限
    if (_locatePermissionStatus != PermissionStatus.granted) {
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
                      _locatePermissionStatus =
                          await Permission.location.request();
                      Navigator.of(context).pop();
                    }, //关闭对话框
                  ),
                ],
              ));
    }
    //定位不正常（时间time为0），提示用户打开定位开关
    else if (_userPosition.time == 0) {
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
      await _mapController?.moveCamera(
          CameraUpdate.newLatLngZoom(_userPosition.latLng, 17.5),
          duration: 500);
    }
  }

  //底栏按钮点击回调函数
  void _onBarItemTapped(int index) async {
    //按点击的底栏项目调出对应activity
    switch (index) {
      case 0:
        if (_mapVertex.listVertex.isEmpty) {
          await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: Text('提示'),
                    content: Text('没有点可以保存。'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('取消'),
                        onPressed: () => Navigator.of(context).pop(), //关闭对话框
                      ),
                    ],
                  ));
        } else {
          await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: Text('提示'),
                    content:
                        Text('保存点到硬盘吗？已有 ${_mapVertex.listVertex.length} 个点。'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('取消'),
                        onPressed: () => Navigator.of(context).pop(), //关闭对话框
                      ),
                      TextButton(
                        child: Text('确定'),
                        onPressed: () async {
                          Directory? toStore =
                              await getExternalStorageDirectory();
                          if (toStore != null) {
                            File vtxdata =
                                File(toStore.path + '/optvertex.json');
                            await vtxdata.writeAsString(jsonEncode(_mapVertex));
                          }
                          Navigator.of(context).pop();
                        }, //关闭对话框
                      ),
                    ],
                  ));
        }
        break;
      case 1:
        if (_mapVertex.listVertex.isEmpty) {
          await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: Text('提示'),
                    content: Text('没有点可以删除。'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('取消'),
                        onPressed: () => Navigator.of(context).pop(), //关闭对话框
                      ),
                    ],
                  ));
        } else {
          await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: Text('提示'),
                    content:
                        Text('删除最后一个点吗？已有 ${_mapVertex.listVertex.length} 个点。'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('取消'),
                        onPressed: () => Navigator.of(context).pop(), //关闭对话框
                      ),
                      TextButton(
                        child: Text('确定'),
                        onPressed: () {
                          _mapVertex.listVertex.removeLast();
                          Navigator.of(context).pop();
                        }, //关闭对话框
                      ),
                    ],
                  ));
        }
        break;
    }
  }

  //定位权限申请函数
  void _requestlocationPermission() async {
    // 申请位置权限
    _locatePermissionStatus = await Permission.location.status;
    if (_locatePermissionStatus != PermissionStatus.granted) {
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
                      _locatePermissionStatus =
                          await Permission.location.request();
                      Navigator.of(context).pop();
                    }, //关闭对话框
                  ),
                ],
              ));
    }
  }

  //获得最后一次地图视角
  void _getLastCameraPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await _mapController
        ?.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
      bearing: prefs.getDouble('lastCamPositionbearing') ?? 0,
      target: LatLng(prefs.getDouble('lastCamPositionLat') ?? 39.909187,
          prefs.getDouble('lastCamPositionLng') ?? 116.397451),
      zoom: prefs.getDouble('lastCamPositionzoom') ?? 17.5,
    )));
  }

//读取已保存的点
  void _getStoredVertex() async {
    Directory? toStore = await getExternalStorageDirectory();
    if (toStore != null) {
      File vtxdata = File(toStore.path + '/optvertex.json');
      if (await vtxdata.exists()) {
        var jsonMap = await vtxdata.readAsString();
        _mapVertex = MapVertex.fromJson(jsonDecode(jsonMap));
      }
    }
  }

  //State创建时执行一次
  @override
  void initState() {
    super.initState();
    //检测并申请定位权限
    _getStoredVertex();
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
        tooltip: _navistate.naviStatus
            ? '停止导航'
            : '开始导航' /*'Stop Navigation' : 'Start Navigation'*/,
        child:
            _navistate.naviStatus ? Icon(Icons.stop) : Icon(Icons.play_arrow),
      ),
      //悬浮按键位置
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class NaviState {
  bool naviStatus = false;
  int? startVertex;
  List endVertex = [];

  NaviState();

  reverseState() {
    naviStatus = !naviStatus;
  }
}

class MapVertex {
  List<LatLng> listVertex = [];
  MapVertex();

  MapVertex.fromList(this.listVertex);

  MapVertex.fromJson(Map<String, dynamic> json) {
    List listVertexJson = json['listVertex'] as List;
    listVertexJson.forEach((element) {
      listVertex.add(LatLng(
          element['latitude'] as double, element['longitude'] as double));
    });
  }

  Map<String, dynamic> toJson() {
    List listVertexJson = [];
    listVertex.forEach((element) {
      listVertexJson.add(<String, dynamic>{
        'latitude': element.latitude,
        'longitude': element.longitude,
      });
    });
    return <String, dynamic>{
      'listVertex': listVertexJson,
    };
  }
}
