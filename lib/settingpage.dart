import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:flutter/material.dart';

class MySettingPage extends StatefulWidget {
  MySettingPage({Key key = const Key('setting'), @required this.mapController})
      : super(key: key);

  final AMapController? mapController;

  @override
  State<StatefulWidget> createState() => _MySettingPageState();
}

class _MySettingPageState extends State<MySettingPage> {
  //卫星地图审图号
  String _satelliteImageApprovalNumber = '地图未正常加载';

  //获取审图号函数
  void _getApprovalNumber() async {
    //按要求获取卫星地图审图号
    await widget.mapController?.getSatelliteImageApprovalNumber().then((value) {
      if (value != null) _satelliteImageApprovalNumber = value;
    });
    setState(() {});
  }

  //清除地图缓存函数
  void _cleanMapCache() async {
    await widget.mapController?.clearDisk();
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
