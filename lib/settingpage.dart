//import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'header.dart';

class MySettingPage extends StatefulWidget {
  MySettingPage({Key key = const Key('setting')}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MySettingPageState();
}

class _MySettingPageState extends State<MySettingPage> {
  //卫星地图审图号
  String _satelliteImageApprovalNumber = '地图未正常加载';
  //检查是否为发行版
  static bool get isRelease => bool.fromEnvironment("dart.vm.product");

  //获取审图号函数
  void _getApprovalNumber() async {
    //按要求获取卫星地图审图号
    await mapController?.getSatelliteImageApprovalNumber().then((value) {
      if (value != null) _satelliteImageApprovalNumber = value;
    });
    setState(() {});
  }

  //清除地图缓存函数
  void _cleanMapCache() async {
    await mapController?.clearDisk();
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text("提示"),
              content: Text("地图缓存已清除。"),
              actions: <Widget>[
                TextButton(
                  child: Text("确定"),
                  onPressed: () => Navigator.of(context).pop(), //关闭对话框
                ),
              ],
            ));
  }

  void _requestLocationPermission() async {
    // 申请位置权限
    locatePermissionStatus = await Permission.location.request();
    setState(() {});
  }

  @override
  void initState() {
    //获取审图号
    _getApprovalNumber();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //顶栏
        appBar: AppBar(
          title: Text('设置'),
        ),
        //中央内容区
        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  child: Text(
                    locatePermissionStatus.isGranted ? '已获取定位权限' : '获取定位权限',
                    style: TextStyle(fontSize: 22),
                  ),
                  onPressed: locatePermissionStatus.isGranted
                      ? null
                      : _requestLocationPermission,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  child: Text(
                    '清除缓存',
                    style: TextStyle(fontSize: 22),
                  ),
                  onPressed: _cleanMapCache,
                )
              ],
            ),
            Text(
              '卫星地图审图号：$_satelliteImageApprovalNumber',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '校园导航 ' + (isRelease ? 'Release' : 'Debug'),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
            Text(
              '@notsabers 2021',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            )
          ],
        ));
  }
}
