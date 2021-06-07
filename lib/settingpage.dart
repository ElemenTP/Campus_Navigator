import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';

import 'header.dart';

///搜索界面
class MySettingPage extends StatefulWidget {
  MySettingPage({Key key = const Key('setting')}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MySettingPageState();
}

class _MySettingPageState extends State<MySettingPage> {
  ///卫星地图审图号
  String _satelliteImageApprovalNumber = '地图未正常加载';

  ///检查是否为发行版
  static bool get isRelease => bool.fromEnvironment("dart.vm.product");

  ///获取审图号函数
  void _getApprovalNumber() async {
    //按要求获取卫星地图审图号
    await mapController?.getSatelliteImageApprovalNumber().then((value) {
      if (value != null) _satelliteImageApprovalNumber = value;
    });
    setState(() {});
  }

  ///清除地图缓存函数
  void _cleanMapCache() async {
    await mapController?.clearDisk();
    showDialog(
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

  ///清除日志文件函数
  void _cleanLogFile() async {
    await logFile.writeAsString('');
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text("提示"),
              content: Text("日志文件已清除。"),
              actions: <Widget>[
                TextButton(
                  child: Text("确定"),
                  onPressed: () => Navigator.of(context).pop(), //关闭对话框
                ),
              ],
            ));
  }

  ///导出日志文件函数
  void _outputLogFile() async {
    Directory? toStore = await getExternalStorageDirectory();
    if (toStore != null) {
      String optFilePath =
          toStore.path + '/CampNaviLog' + DateTime.now().toString() + '.txt';
      File optData = File(optFilePath);
      await optData.writeAsString(await logFile.readAsString());
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text("提示"),
                content: Text("导出成功，文件路径$optFilePath。"),
                actions: <Widget>[
                  TextButton(
                    child: Text("确定"),
                    onPressed: () => Navigator.of(context).pop(), //关闭对话框
                  ),
                ],
              ));
    } else {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text("提示"),
                content: Text("导出失败，无法访问路径。"),
                actions: <Widget>[
                  TextButton(
                    child: Text("确定"),
                    onPressed: () => Navigator.of(context).pop(), //关闭对话框
                  ),
                ],
              ));
    }
  }

  ///导入地图文件函数
  void _pickMapData() async {
    FilePickerResult? pickedFile = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: ['json']);
    if (pickedFile != null) {
      File iptFile = File(pickedFile.files.single.path!);
      String iptJson = await iptFile.readAsString();
      try {
        MapData newData = MapData.fromJson(jsonDecode(iptJson));
        if (newData.mapCampus.length == 0 ||
            newData.mapCampus.length > newData.mapBuilding.length ||
            newData.mapCampus.length > newData.mapVertex.length ||
            newData.mapCampus.length > newData.mapEdge.length) {
          throw {'!'};
        }
      } catch (_) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text("提示"),
                  content: Text("地图数据格式不正确，请检查地图数据。"),
                  actions: <Widget>[
                    TextButton(
                      child: Text("确定"),
                      onPressed: () => Navigator.of(context).pop(), //关闭对话框
                    ),
                  ],
                ));
        return;
      }
      Directory customMapDataDir = await getApplicationDocumentsDirectory();
      String customMapDataPath = customMapDataDir.path +
          '/CustomMapData/' +
          pickedFile.files.single.name;
      File customMapDataFile = File(customMapDataPath);
      await customMapDataFile.writeAsString(iptJson);
      prefs.setString('filedir', customMapDataPath);
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text("提示"),
                content: Text("地图数据已成功应用，重启软件生效。"),
                actions: <Widget>[
                  TextButton(
                    child: Text("确定"),
                    onPressed: () => Navigator.of(context).pop(), //关闭对话框
                  ),
                ],
              ));
    }
  }

  ///管理地图文件函数
  void _manageMapData() async {}

  ///导入逻辑位置文件函数
  void _pickLogicData() async {}

  ///管理逻辑位置文件函数
  void _manageLogicData() async {}

  ///申请定位权限函数
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '地图数据',
                    ),
                  ],
                ),
                TextButton(
                  child: Text(
                    '导入数据',
                  ),
                  onPressed: _pickMapData,
                ),
                TextButton(
                  child: Text(
                    '管理数据',
                  ),
                  onPressed: _manageMapData,
                ),
              ],
            )),
            Card(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '逻辑位置',
                    ),
                  ],
                ),
                TextButton(
                  child: Text(
                    '导入数据',
                  ),
                  onPressed: _pickLogicData,
                ),
                TextButton(
                  child: Text(
                    '管理数据',
                  ),
                  onPressed: _manageLogicData,
                ),
              ],
            )),
            Card(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '日志开关',
                    ),
                    Switch(
                        value: logEnabled,
                        onChanged: (value) {
                          setState(() => logEnabled = value);
                          prefs.setBool('logEnabled', logEnabled);
                        }),
                  ],
                ),
                TextButton(
                  child: Text(
                    '查看日志',
                  ),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (context) => MyLogPage())),
                ),
                TextButton(
                  child: Text(
                    '导出日志',
                  ),
                  onPressed: _outputLogFile,
                ),
                TextButton(
                  child: Text(
                    '清除日志',
                  ),
                  onPressed: _cleanLogFile,
                ),
              ],
            )),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  child: Text(
                    locatePermissionStatus.isGranted ? '已获取定位权限' : '获取定位权限',
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
                  ),
                  onPressed: _cleanMapCache,
                ),
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
            ),
          ],
        ),
      ),
    );
  }
}

///日志内容展示界面
class MyLogPage extends StatelessWidget {
  late final List<String> listLogString;

  @override
  Widget build(BuildContext context) {
    listLogString = logFile.readAsLinesSync() + ['没有更多了。'];
    return Scaffold(
      appBar: AppBar(
        title: Text('日志'),
      ),
      body: Column(
        children: [
          Expanded(
              child: ListView.builder(
            itemCount: listLogString.length,
            itemBuilder: (context, index) => Card(
              child: ListTile(
                title: Text(listLogString[index]),
              ),
            ),
          ))
        ],
      ),
    );
  }
}
