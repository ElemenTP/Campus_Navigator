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
  ///预设卫星地图审图号
  String _satelliteImageApprovalNumber = '地图未正常加载';

  ///检查软件是否为发行版
  static bool get isRelease => bool.fromEnvironment("dart.vm.product");

  ///获取审图号函数，遵守高德地图Open Api的要求
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
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ));
  }

  ///清除日志文件函数
  void _cleanLogFile() async {
    if (logEnabled)
      await logFile.writeAsString('');
    else
      await logFile.delete();
    setState(() {});
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text("提示"),
              content: Text("日志文件已清除。"),
              actions: <Widget>[
                TextButton(
                  child: Text("确定"),
                  onPressed: () => Navigator.of(context).pop(),
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
                    onPressed: () => Navigator.of(context).pop(),
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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ));
    }
  }

  ///导入地图文件函数，调用Android系统的文件选择器选择文件，并对文件中的数据的有效性进行测试，
  ///不可用则提示用户，可用则存储在软件私有存储空间中并设为默认地图数据。
  void _pickMapData() async {
    FilePickerResult? pickedFile;
    try {
      pickedFile = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowMultiple: false,
          allowedExtensions: ['json']);
    } catch (_) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text("提示"),
                content: Text("导入地图数据文件功能需要存储权限。"),
                actions: <Widget>[
                  TextButton(
                    child: Text("确定"),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ));
    }
    if (pickedFile != null) {
      File iptFile = File(pickedFile.files.single.path!);
      late MapData newData;
      try {
        newData = MapData.fromJson(jsonDecode(await iptFile.readAsString()));
        if (newData.mapCampus.length == 0 ||
            newData.mapCampus.length > newData.mapBuilding.length ||
            newData.mapCampus.length > newData.mapVertex.length ||
            newData.mapCampus.length > newData.mapEdge.length) {
          throw '!';
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
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ));
        return;
      }
      Directory applicationDataDir = await getApplicationDocumentsDirectory();
      String customMapDataPath = applicationDataDir.path +
          '/CustomMapData/' +
          pickedFile.files.single.name;
      File customMapDataFile = File(customMapDataPath);
      if (!await customMapDataFile.exists()) {
        customMapDataFile = await customMapDataFile.create(recursive: true);
      }
      await customMapDataFile.writeAsString(jsonEncode(newData));
      prefs.setString('dataFileDir', customMapDataPath);
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text("提示"),
                content: Text("地图数据已成功应用，重启软件生效。"),
                actions: <Widget>[
                  TextButton(
                    child: Text("确定"),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ));
      if (logEnabled)
        logSink.write(DateTime.now().toString() +
            ': 导入新地图数据，' +
            pickedFile.files.single.name +
            '。\n');
    }
  }

  ///管理地图文件函数，列出软件私有存储空间中所有导入的地图文件，用户可选择将任意一个设为默认，
  ///或删除。
  void _manageMapData() async {
    Directory applicationDataDir = await getApplicationDocumentsDirectory();
    String customMapDataPath = applicationDataDir.path + '/CustomMapData';
    Directory customMapDataDir = Directory(customMapDataPath);
    if (!await customMapDataDir.exists())
      await customMapDataDir.create(recursive: true);
    int prefixLength = customMapDataPath.length + 1;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, _setState) {
          String? dataFileDir = prefs.getString('dataFileDir');
          List<FileSystemEntity> listMapDataFiles = customMapDataDir.listSync();
          List<Widget> listMapDataFileChoose = [];
          listMapDataFileChoose.add(Card(
            child: ListTile(
              title: Text('默认地图数据: 北京邮电大学沙河校区和海淀校区'),
              selected: dataFileDir == null,
              onTap: () => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: Text('提示'),
                        content: Text('将地图数据设为默认吗？重启软件生效。'),
                        actions: <Widget>[
                          TextButton(
                            child: Text('取消'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          TextButton(
                            child: Text('确定'),
                            onPressed: () async {
                              await prefs.remove('dataFileDir');
                              _setState(() {});
                              Navigator.of(context).pop();
                              if (logEnabled)
                                logSink.write(DateTime.now().toString() +
                                    ': 应用默认地图数据。\n');
                            },
                          ),
                        ],
                      )),
            ),
          ));
          listMapDataFiles.forEach((element) => listMapDataFileChoose.add(Card(
                child: ListTile(
                  title: Text(element.path.substring(prefixLength)),
                  selected: (dataFileDir ?? '') == element.path,
                  onTap: () => showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                            title: Text('提示'),
                            content: Text('如何处理该地图数据？重启软件生效。'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('取消'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              TextButton(
                                child: Text('删除'),
                                onPressed: () async {
                                  if ((dataFileDir ?? '') == element.path)
                                    await prefs.remove('dataFileDir');
                                  await element.delete();
                                  _setState(() {});
                                  Navigator.of(context).pop();
                                  if (logEnabled)
                                    logSink.write(DateTime.now().toString() +
                                        ': 删除地图数据，' +
                                        element.path.substring(prefixLength) +
                                        '。\n');
                                },
                              ),
                              TextButton(
                                child: Text('使用'),
                                onPressed: () async {
                                  prefs.setString('dataFileDir', element.path);
                                  _setState(() {});
                                  Navigator.of(context).pop();
                                  if (logEnabled)
                                    logSink.write(DateTime.now().toString() +
                                        ': 应用地图数据，' +
                                        element.path.substring(prefixLength) +
                                        '。\n');
                                },
                              ),
                            ],
                          )),
                ),
              )));
          return AlertDialog(
            title: Text('地图数据'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: listMapDataFileChoose,
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text("返回"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      ),
    );
  }

  ///导入逻辑位置文件函数。调用Android系统的文件选择器选择文件，并对文件中的数据的有效性进行
  ///测试，不可用则提示用户，可用则存储在软件私有存储空间中并设为默认逻辑位置数据，立即应用。
  void _pickLogicData() async {
    FilePickerResult? pickedFile;
    try {
      pickedFile = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowMultiple: false,
          allowedExtensions: ['json']);
    } catch (_) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text("提示"),
                content: Text("导入地图数据文件功能需要存储权限。"),
                actions: <Widget>[
                  TextButton(
                    child: Text("确定"),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ));
    }
    if (pickedFile != null) {
      File iptFile = File(pickedFile.files.single.path!);
      late LogicLoc newLogicLoc;
      try {
        newLogicLoc =
            LogicLoc.fromJson(jsonDecode(await iptFile.readAsString()));
        if (newLogicLoc.logicLoc.isEmpty) throw '!';
      } catch (_) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text("提示"),
                  content: Text("逻辑位置数据格式不正确，请检查逻辑位置数据。"),
                  actions: <Widget>[
                    TextButton(
                      child: Text("确定"),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ));
        return;
      }
      Directory applicationDataDir = await getApplicationDocumentsDirectory();
      String customLogicLocPath = applicationDataDir.path +
          '/CustomLogicLoc/' +
          pickedFile.files.single.name;
      File customLogicLocFile = File(customLogicLocPath);
      if (!await customLogicLocFile.exists()) {
        customLogicLocFile = await customLogicLocFile.create(recursive: true);
      }
      await customLogicLocFile.writeAsString(jsonEncode(newLogicLoc));
      prefs.setString('logicLocFileDir', customLogicLocPath);
      mapLogicLoc = newLogicLoc;
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text("提示"),
                content: Text("逻辑位置数据已成功应用。"),
                actions: <Widget>[
                  TextButton(
                    child: Text("确定"),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ));
      if (logEnabled)
        logSink.write(DateTime.now().toString() +
            ': 导入并应用新逻辑位置，' +
            pickedFile.files.single.name +
            '。\n');
    }
  }

  ///管理逻辑位置文件函数，列出软件私有存储空间中所有导入的逻辑位置文件，用户可选择将任意一个
  ///设为默认，或删除，将立刻生效。
  void _manageLogicData() async {
    Directory applicationDataDir = await getApplicationDocumentsDirectory();
    String customLogicLocPath = applicationDataDir.path + '/CustomLogicLoc';
    Directory customLogicLocDir = Directory(customLogicLocPath);
    if (!await customLogicLocDir.exists())
      await customLogicLocDir.create(recursive: true);
    int prefixLength = customLogicLocPath.length + 1;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, _setState) {
          String? logicLocFileDir = prefs.getString('logicLocFileDir');
          List<FileSystemEntity> listLogicLocFiles =
              customLogicLocDir.listSync();
          List<Widget> listLogicLocFileChoose = [];
          listLogicLocFileChoose.add(Card(
            child: ListTile(
              title: Text('不使用逻辑位置功能'),
              selected: logicLocFileDir == null,
              onTap: () => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: Text('提示'),
                        content: Text('不使用逻辑位置功能吗？立即生效。'),
                        actions: <Widget>[
                          TextButton(
                            child: Text('取消'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          TextButton(
                            child: Text('确定'),
                            onPressed: () async {
                              await prefs.remove('logicLocFileDir');
                              mapLogicLoc = LogicLoc();
                              _setState(() {});
                              Navigator.of(context).pop();
                              if (logEnabled)
                                logSink.write(
                                    DateTime.now().toString() + ': 不使用逻辑位置。\n');
                            },
                          ),
                        ],
                      )),
            ),
          ));
          listLogicLocFiles.forEach((element) =>
              listLogicLocFileChoose.add(Card(
                child: ListTile(
                  title: Text(element.path.substring(prefixLength)),
                  selected: (logicLocFileDir ?? '') == element.path,
                  onTap: () => showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                            title: Text('提示'),
                            content: Text('如何处理该逻辑位置数据？立即生效。'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('取消'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              TextButton(
                                child: Text('删除'),
                                onPressed: () async {
                                  if ((logicLocFileDir ?? '') == element.path) {
                                    await prefs.remove('logicLocFileDir');
                                    mapLogicLoc = LogicLoc();
                                  }
                                  await element.delete();
                                  _setState(() {});
                                  Navigator.of(context).pop();
                                  if (logEnabled)
                                    logSink.write(DateTime.now().toString() +
                                        ': 删除逻辑位置，' +
                                        element.path.substring(prefixLength) +
                                        '。\n');
                                },
                              ),
                              TextButton(
                                child: Text('使用'),
                                onPressed: () async {
                                  prefs.setString(
                                      'logicLocFileDir', element.path);
                                  File logicLocFile = File(element.path);
                                  mapLogicLoc = LogicLoc.fromJson(jsonDecode(
                                      await logicLocFile.readAsString()));
                                  _setState(() {});
                                  Navigator.of(context).pop();
                                  if (logEnabled)
                                    logSink.write(DateTime.now().toString() +
                                        ': 应用逻辑位置，' +
                                        element.path.substring(prefixLength) +
                                        '。\n');
                                },
                              ),
                            ],
                          )),
                ),
              )));
          return AlertDialog(
            title: Text('逻辑位置数据'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: listLogicLocFileChoose,
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text("返回"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      ),
    );
  }

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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      '日志',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '开关',
                    ),
                    Switch(
                        value: logEnabled,
                        onChanged: (value) {
                          setState(() => logEnabled = value);
                          prefs.setBool('logEnabled', logEnabled);
                          if (logEnabled && (!logFile.existsSync()))
                            logSink = logFile.openWrite(mode: FileMode.append);
                        }),
                  ],
                ),
                TextButton(
                  child: Text(
                    '查看日志',
                  ),
                  onPressed: logFile.existsSync()
                      ? () => Navigator.push(context,
                          MaterialPageRoute(builder: (context) => MyLogPage()))
                      : null,
                ),
                TextButton(
                  child: Text(
                    '导出日志',
                  ),
                  onPressed: logFile.existsSync() ? _outputLogFile : null,
                ),
                TextButton(
                  child: Text(
                    '清除日志',
                  ),
                  onPressed: logFile.existsSync() ? _cleanLogFile : null,
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

///日志内容展示界面，从文件中按行读出日志并放在列表中
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
