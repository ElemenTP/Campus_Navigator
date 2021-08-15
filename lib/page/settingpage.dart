import 'dart:convert';
import 'dart:io';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:campnavi/global/global.dart';
import 'package:campnavi/model/mapdata.dart';
import 'package:campnavi/model/logicloc.dart';
import 'package:campnavi/controller/settingpagecontroller.dart';
import 'package:campnavi/controller/homepagecontroller.dart';

///设置界面
class SettingPage extends StatelessWidget {
  SettingPage({Key key = const Key('setting')}) : super(key: key);

  static SettingPageController spc = Get.find();

  static HomePageController hpc = Get.find();

  ///检查软件是否为发行版
  static bool get isRelease => bool.fromEnvironment("dart.vm.product");

  ///获取审图号函数，遵守高德地图Open Api的要求
  void _getApprovalNumber() async {
    //按要求获取常规地图审图号
    await hpc.mapController?.value.getMapContentApprovalNumber().then((value) {
      if (value != null) spc.mapContentApprovalNumber = value.obs;
    });
    //按要求获取卫星地图审图号
    await hpc.mapController?.value
        .getSatelliteImageApprovalNumber()
        .then((value) {
      if (value != null) spc.satelliteImageApprovalNumber = value.obs;
    });
  }

  ///清除地图缓存函数
  void _cleanMapCache() async {
    await hpc.mapController?.value.clearDisk();
    Get.dialog(AlertDialog(
      title: Text("提示"),
      content: Text("地图缓存已清除。"),
      actions: <Widget>[
        TextButton(
          child: Text("确定"),
          onPressed: () => Get.back(),
        ),
      ],
    ));
  }

  ///清除日志文件函数
  void _cleanLogFile() async {
    if (spc.logEnabled.value)
      await logFile.writeAsString('');
    else {
      await logFile.delete();
      spc.logExisted.value = false;
    }
    Get.dialog(AlertDialog(
      title: Text("提示"),
      content: Text("日志文件已清除。"),
      actions: <Widget>[
        TextButton(
          child: Text("确定"),
          onPressed: () => Get.back(),
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
      Get.dialog(AlertDialog(
        title: Text("提示"),
        content: Text("导出成功，文件路径$optFilePath。"),
        actions: <Widget>[
          TextButton(
            child: Text("确定"),
            onPressed: () => Get.back(),
          ),
        ],
      ));
    } else {
      Get.dialog(AlertDialog(
        title: Text("提示"),
        content: Text("导出失败，无法访问路径。"),
        actions: <Widget>[
          TextButton(
            child: Text("确定"),
            onPressed: () => Get.back(),
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
      Get.dialog(AlertDialog(
        title: Text("提示"),
        content: Text("导入地图数据文件功能需要存储权限。"),
        actions: <Widget>[
          TextButton(
            child: Text("确定"),
            onPressed: () => Get.back(),
          ),
        ],
      ));
    }
    if (pickedFile != null) {
      File iptFile = File(pickedFile.files.single.path!);
      late MapData newData;
      try {
        newData = MapData.fromJson(jsonDecode(await iptFile.readAsString()));
        if (newData.mapCampus.length == 0) throw '!';
      } catch (_) {
        Get.dialog(AlertDialog(
          title: Text("提示"),
          content: Text("地图数据格式不正确，请检查地图数据。"),
          actions: <Widget>[
            TextButton(
              child: Text("确定"),
              onPressed: () => Get.back(),
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
      prefs.write('dataFileDir', customMapDataPath);
      Get.dialog(AlertDialog(
        title: Text("提示"),
        content: Text("地图数据已成功应用，重启软件生效。"),
        actions: <Widget>[
          TextButton(
            child: Text("确定"),
            onPressed: () => Get.back(),
          ),
        ],
      ));
      if (spc.logEnabled.value)
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
    /*Navigator.push(
        context, MaterialPageRoute(builder: (context) => _MapDataManagePage()));*/
    await showDialog(
      context: Get.context!,
      builder: (context) => StatefulBuilder(
        builder: (context, _setState) {
          String? dataFileDir = prefs.read<String>('dataFileDir');
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
                            onPressed: () => Get.back(),
                          ),
                          TextButton(
                            child: Text('确定'),
                            onPressed: () async {
                              await prefs.remove('dataFileDir');
                              _setState(() {});
                              Get.back();
                              if (spc.logEnabled.value)
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
                                onPressed: () => Get.back(),
                              ),
                              TextButton(
                                child: Text('删除'),
                                onPressed: () async {
                                  if ((dataFileDir ?? '') == element.path)
                                    await prefs.remove('dataFileDir');
                                  await element.delete();
                                  _setState(() {});
                                  Get.back();
                                  if (spc.logEnabled.value)
                                    logSink.write(DateTime.now().toString() +
                                        ': 删除地图数据，' +
                                        element.path.substring(prefixLength) +
                                        '。\n');
                                },
                              ),
                              TextButton(
                                child: Text('使用'),
                                onPressed: () async {
                                  prefs.write('dataFileDir', element.path);
                                  _setState(() {});
                                  Get.back();
                                  if (spc.logEnabled.value)
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
                onPressed: () => Get.back(),
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
      Get.dialog(AlertDialog(
        title: Text("提示"),
        content: Text("导入地图数据文件功能需要存储权限。"),
        actions: <Widget>[
          TextButton(
            child: Text("确定"),
            onPressed: () => Get.back(),
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
        Get.dialog(AlertDialog(
          title: Text("提示"),
          content: Text("逻辑位置数据格式不正确，请检查逻辑位置数据。"),
          actions: <Widget>[
            TextButton(
              child: Text("确定"),
              onPressed: () => Get.back(),
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
      prefs.write('logicLocFileDir', customLogicLocPath);
      mapLogicLoc = newLogicLoc;
      Get.dialog(AlertDialog(
        title: Text("提示"),
        content: Text("逻辑位置数据已成功应用。"),
        actions: <Widget>[
          TextButton(
            child: Text("确定"),
            onPressed: () => Get.back(),
          ),
        ],
      ));
      if (spc.logEnabled.value)
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
      context: Get.context!,
      builder: (context) => StatefulBuilder(
        builder: (context, _setState) {
          String? logicLocFileDir = prefs.read<String>('logicLocFileDir');
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
                            onPressed: () => Get.back(),
                          ),
                          TextButton(
                            child: Text('确定'),
                            onPressed: () async {
                              await prefs.remove('logicLocFileDir');
                              mapLogicLoc = LogicLoc();
                              _setState(() {});
                              Get.back();
                              if (spc.logEnabled.value)
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
                                onPressed: () => Get.back(),
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
                                  Get.back();
                                  if (spc.logEnabled.value)
                                    logSink.write(DateTime.now().toString() +
                                        ': 删除逻辑位置，' +
                                        element.path.substring(prefixLength) +
                                        '。\n');
                                },
                              ),
                              TextButton(
                                child: Text('使用'),
                                onPressed: () async {
                                  prefs.write('logicLocFileDir', element.path);
                                  File logicLocFile = File(element.path);
                                  mapLogicLoc = LogicLoc.fromJson(jsonDecode(
                                      await logicLocFile.readAsString()));
                                  _setState(() {});
                                  Get.back();
                                  if (spc.logEnabled.value)
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
                onPressed: () => Get.back(),
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
    spc.locatePermissionStatus.value = await Permission.location.request();
  }

  ///展示关于软件界面
  /*void _showAbout() async {
    Get.dialog(AlertDialog(
      title: Text("关于"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '校园导航',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '常规地图审图号\n${spc.mapContentApprovalNumber.value}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
          Text(
            '卫星地图审图号\n${spc.satelliteImageApprovalNumber.value}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
          Text(
            packageInfo.version +
                '+' +
                packageInfo.buildNumber +
                ' ' +
                (isRelease ? 'Release' : 'Debug'),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          ),
          Text(
            '@notsabers 2021',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: Text("许可"),
          onPressed: () => showLicensePage(
            context: Get.context!,
            applicationName: '校园导航',
            applicationVersion:
                packageInfo.version + '+' + packageInfo.buildNumber,
          ),
        ),
        TextButton(
          child: Text("确定"),
          onPressed: () => Get.back(),
        ),
      ],
    ));
  }*/

  void _showAmapAbout() async {
    Get.dialog(AlertDialog(
      title: Text("高德地图审图号"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '常规地图审图号',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
          Text(
            '${spc.mapContentApprovalNumber.value}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
          Text(
            '卫星地图审图号',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
          Text(
            '${spc.satelliteImageApprovalNumber.value}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: Text("确定"),
          onPressed: () => Get.back(),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    spc.logExisted.value = logFile.existsSync();
    _getApprovalNumber();
    return Scaffold(
      //顶栏
      appBar: AppBar(
        title: Text('设置'),
      ),
      //中央内容区
      body: SingleChildScrollView(
        child: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                subtitle: Text(
                  '定位与地图',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              SwitchListTile(
                title: Text('定位开关'),
                subtitle: Text('大多数功能需要开启定位'),
                value: spc.locateEnabled.value,
                onChanged: (value) {
                  spc.locateEnabled.value = value;
                  prefs.write('locateEnabled', value);
                },
              ),
              SwitchListTile(
                title: Text('指南针开关'),
                subtitle: Text('开启或关闭地图左上角的指南针'),
                value: spc.compassEnabled.value,
                onChanged: (value) {
                  spc.compassEnabled.value = value;
                  prefs.write('compassEnabled', value);
                },
              ),
              ListTile(
                title: Text(
                  '地图类型',
                ),
                subtitle: Text('选择使用的地图类型'),
                onTap: () => Get.dialog(AlertDialog(
                  title: Text(
                    '地图类型',
                  ),
                  content: SingleChildScrollView(
                    child: Obx(() {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile(
                            title: Text('卫星地图（默认）'),
                            value: MapType.satellite,
                            groupValue: spc.preferMapType.value,
                            onChanged: (MapType? value) {
                              spc.preferMapType.value = value!;
                              prefs.write('preferMapType', value);
                            },
                          ),
                          RadioListTile(
                            title: Text('普通地图'),
                            value: MapType.normal,
                            groupValue: spc.preferMapType.value,
                            onChanged: (MapType? value) {
                              spc.preferMapType.value = value!;
                              prefs.write('preferMapType', value);
                            },
                          ),
                          RadioListTile(
                            title: Text('夜间地图'),
                            value: MapType.night,
                            groupValue: spc.preferMapType.value,
                            onChanged: (MapType? value) {
                              spc.preferMapType.value = value!;
                              prefs.write('preferMapType', value);
                            },
                          ),
                          RadioListTile(
                            title: Text('导航地图'),
                            value: MapType.navi,
                            groupValue: spc.preferMapType.value,
                            onChanged: (MapType? value) {
                              spc.preferMapType.value = value!;
                              prefs.write('preferMapType', value);
                            },
                          ),
                          RadioListTile(
                            title: Text('公交地图'),
                            value: MapType.bus,
                            groupValue: spc.preferMapType.value,
                            onChanged: (MapType? value) {
                              spc.preferMapType.value = value!;
                              prefs.write('preferMapType', value);
                            },
                          ),
                        ],
                      );
                    }),
                  ),
                  actions: [
                    TextButton(
                      child: Text("确定"),
                      onPressed: () => Get.back(),
                    ),
                  ],
                )),
              ),
              ListTile(
                subtitle: Text(
                  '地图数据',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                title: Text(
                  '导入数据',
                ),
                subtitle: Text('从文件导入地图数据'),
                onTap: _pickMapData,
              ),
              ListTile(
                title: Text(
                  '管理数据',
                ),
                subtitle: Text('管理已导入地图数据'),
                onTap: _manageMapData,
              ),
              ListTile(
                subtitle: Text(
                  '逻辑位置',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                title: Text(
                  '导入数据',
                ),
                subtitle: Text('从文件导入逻辑位置数据'),
                onTap: _pickLogicData,
              ),
              ListTile(
                title: Text(
                  '管理数据',
                ),
                subtitle: Text('管理已导入逻辑位置数据'),
                onTap: _manageLogicData,
              ),
              ListTile(
                subtitle: Text(
                  '日志',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              SwitchListTile(
                  value: spc.logEnabled.value,
                  title: Text(
                    '日志开关',
                  ),
                  onChanged: (value) {
                    spc.logEnabled.value = value;
                    prefs.write('logEnabled', spc.logEnabled.value);
                    if ((spc.logEnabled.value) && (!spc.logExisted.value)) {
                      logSink = logFile.openWrite(mode: FileMode.append);
                      spc.logExisted.value = true;
                    }
                  }),
              ListTile(
                title: Text(
                  '查看日志',
                ),
                subtitle: spc.logExisted.value ? Text('查看存储的日志') : Text('没有日志'),
                onTap: spc.logExisted.value
                    ? () => Navigator.push(context,
                        MaterialPageRoute(builder: (context) => _MyLogPage()))
                    : null,
              ),
              ListTile(
                title: Text(
                  '导出日志',
                ),
                subtitle:
                    spc.logExisted.value ? Text('导出日志到内部存储空间') : Text('没有日志'),
                onTap: spc.logExisted.value ? _outputLogFile : null,
              ),
              ListTile(
                title: Text(
                  '清除日志',
                ),
                subtitle: spc.logExisted.value ? Text('清除存储的日志') : Text('没有日志'),
                onTap: spc.logExisted.value ? _cleanLogFile : null,
              ),
              ListTile(
                subtitle: Text(
                  '其他',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                title: Text(
                  '申请定位权限',
                ),
                subtitle: Text(
                  spc.locatePermissionStatus.value.isGranted
                      ? '已获取定位权限'
                      : '定位与导航功能依赖定位权限工作',
                ),
                onTap: spc.locatePermissionStatus.value.isGranted
                    ? null
                    : _requestLocationPermission,
              ),
              ListTile(
                title: Text(
                  '清除缓存',
                ),
                subtitle: Text('清除地图缓存'),
                onTap: _cleanMapCache,
              ),
              /*ListTile(
                title: Text(
                  '关于',
                ),
                onTap: _showAbout,
              ),*/
              ListTile(
                title: Text(
                  '高德审图号',
                ),
                onTap: _showAmapAbout,
              ),
              AboutListTile(
                applicationName: '校园导航',
                applicationVersion: packageInfo.version +
                    '+' +
                    packageInfo.buildNumber +
                    ' ' +
                    (isRelease ? 'Release' : 'Debug'),
                applicationLegalese: '@notsabers 2021',
              )
            ],
          ),
        ),
      ),
    );
  }
}

///日志内容展示界面，从文件中按行读出日志并放在列表中
class _MyLogPage extends StatelessWidget {
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

///地图数据管理界面
class MapDataManagePage extends StatelessWidget {
  MapDataManagePage({Key key = const Key('mapdata')}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}

///地图数据管理界面
class LogicDataManagePage extends StatelessWidget {
  LogicDataManagePage({Key key = const Key('mapdata')}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
