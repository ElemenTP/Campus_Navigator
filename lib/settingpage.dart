import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

class MySettingPage extends StatefulWidget {
  MySettingPage({Key key, @required this.mapController}) : super(key: key);

  final AMapController mapController;

  @override
  State<StatefulWidget> createState() => _MySettingPageState();
}

class _MySettingPageState extends State<MySettingPage> {
  //普通地图审图号
  String _mapContentApprovalNumber;
  //卫星地图审图号
  String _satelliteImageApprovalNumber;

  //获取审图号函数
  void _getApprovalNumber() async {
    //按要求获取普通地图审图号
    _mapContentApprovalNumber =
        await widget.mapController?.getMapContentApprovalNumber();
    //按要求获取卫星地图审图号
    _satelliteImageApprovalNumber =
        await widget.mapController?.getSatelliteImageApprovalNumber();
    setState(() {});
  }

  //清除地图缓存函数
  void _cleanMapCache() async {
    await widget.mapController?.clearDisk();
    Fluttertoast.showToast(
      msg: '已清除缓存',
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16,
    );
  }

  @override
  void initState() {
    super.initState();
    //获取审图号
    _getApprovalNumber();
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
                    '清除缓存',
                    style: TextStyle(fontSize: 22),
                  ),
                  onPressed: _cleanMapCache,
                )
              ],
            ),
            Text(
              '普通地图审图号：$_mapContentApprovalNumber',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '卫星地图审图号：$_satelliteImageApprovalNumber',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '校园导航 debug',
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
