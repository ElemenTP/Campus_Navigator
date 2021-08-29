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
import 'package:campnavi/translation/translation.dart';

///设置界面
class SettingPage extends StatelessWidget {
  SettingPage({Key key = const Key('setting')}) : super(key: key);

  static SettingPageController spc = Get.find();

  static HomePageController hpc = Get.find();

  ///检查软件是否为发行版
  static bool get isRelease => bool.fromEnvironment('dart.vm.product');

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
      title: Text('tip'.tr),
      content: Text("地图缓存已清除。"),
      actions: <Widget>[
        TextButton(
          child: Text('ok'.tr),
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
      title: Text('tip'.tr),
      content: Text("日志文件已清除。"),
      actions: <Widget>[
        TextButton(
          child: Text('ok'.tr),
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
        title: Text('tip'.tr),
        content: Text("导出成功，文件路径$optFilePath。"),
        actions: <Widget>[
          TextButton(
            child: Text('ok'.tr),
            onPressed: () => Get.back(),
          ),
        ],
      ));
    } else {
      Get.dialog(AlertDialog(
        title: Text('tip'.tr),
        content: Text("导出失败，无法访问路径。"),
        actions: <Widget>[
          TextButton(
            child: Text('ok'.tr),
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
        title: Text('tip'.tr),
        content: Text("导入地图数据文件功能需要存储权限。"),
        actions: <Widget>[
          TextButton(
            child: Text('ok'.tr),
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
          title: Text('tip'.tr),
          content: Text("地图数据格式不正确，请检查地图数据。"),
          actions: <Widget>[
            TextButton(
              child: Text('ok'.tr),
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
        title: Text('tip'.tr),
        content: Text("地图数据已成功应用，重启软件生效。"),
        actions: <Widget>[
          TextButton(
            child: Text('ok'.tr),
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
                            child: Text('cancel'.tr),
                            onPressed: () => Get.back(),
                          ),
                          TextButton(
                            child: Text('ok'.tr),
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
                                child: Text('cancel'.tr),
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
                child: Text('back'.tr),
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
        title: Text('tip'.tr),
        content: Text("导入地图数据文件功能需要存储权限。"),
        actions: <Widget>[
          TextButton(
            child: Text('ok'.tr),
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
          title: Text('tip'.tr),
          content: Text("逻辑位置数据格式不正确，请检查逻辑位置数据。"),
          actions: <Widget>[
            TextButton(
              child: Text('ok'.tr),
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
        title: Text('tip'.tr),
        content: Text("逻辑位置数据已成功应用。"),
        actions: <Widget>[
          TextButton(
            child: Text('ok'.tr),
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
                            child: Text('cancel'.tr),
                            onPressed: () => Get.back(),
                          ),
                          TextButton(
                            child: Text('ok'.tr),
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
                                child: Text('cancel'.tr),
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
                child: Text('back'.tr),
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

  ///展示高德地图审图号信息界面
  void _showAmapAbout() async {
    Get.dialog(AlertDialog(
      title: Text('amapmapapprovalnumber'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'mapcontentapprovalnumber'.tr,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
          Text(
            '${spc.mapContentApprovalNumber.value}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
          Text(
            'satelliteimageapprovalnumber'.tr,
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
          child: Text('ok'.tr),
          onPressed: () => Get.back(),
        ),
      ],
    ));
  }

  ///选择地图类型
  void _selectMapType() {
    Get.dialog(
      AlertDialog(
        title: Text(
          'maptype'.tr,
        ),
        content: SingleChildScrollView(
          child: Obx(() => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile(
                    title: Text('satellite'.tr),
                    value: MapType.satellite,
                    groupValue: spc.preferMapType.value,
                    onChanged: (MapType? value) {
                      spc.preferMapType.value = value!;
                      prefs.write('preferMapType', 'satellite');
                    },
                  ),
                  RadioListTile(
                    title: Text('normal'.tr),
                    value: MapType.normal,
                    groupValue: spc.preferMapType.value,
                    onChanged: (MapType? value) {
                      spc.preferMapType.value = value!;
                      prefs.write('preferMapType', 'normal');
                    },
                  ),
                  RadioListTile(
                    title: Text('night'.tr),
                    value: MapType.night,
                    groupValue: spc.preferMapType.value,
                    onChanged: (MapType? value) {
                      spc.preferMapType.value = value!;
                      prefs.write('preferMapType', 'night');
                    },
                  ),
                ],
              )),
        ),
        actions: [
          TextButton(
            child: Text('ok'.tr),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  ///选择应用语言
  void _selectLanguage() {
    Get.dialog(
      StatefulBuilder(builder: (context, _setState) {
        List<Widget> widgets = <Widget>[
          RadioListTile(
            title: Text('followsystem'.tr),
            value: Get.deviceLocale!,
            groupValue: Get.locale,
            onChanged: (Locale? value) {
              _setState(() {
                Get.updateLocale(value!);
              });
              prefs.write('preferLocale', 'device');
            },
          ),
        ];
        supporedLocales.forEach((element) {
          widgets.add(
            RadioListTile(
              title: Text(languagecode2Str[element.languageCode] ?? 'err!'),
              value: element,
              groupValue: Get.locale,
              onChanged: (Locale? value) {
                _setState(() {
                  Get.updateLocale(value!);
                });
                prefs.write('preferLocale', element.languageCode);
              },
            ),
          );
        });
        return AlertDialog(
          title: Text('language'.tr),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widgets,
            ),
          ),
          actions: [
            TextButton(
              child: Text('ok'.tr),
              onPressed: () => Get.back(),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    spc.logExisted.value = logFile.existsSync();
    _getApprovalNumber();
    return Scaffold(
      //顶栏
      appBar: AppBar(
        title: Text('setting'.tr),
      ),
      //中央内容区
      body: SingleChildScrollView(
        child: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                subtitle: Text(
                  'locatingandmap'.tr,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              SwitchListTile(
                title: Text('locateswitch'.tr),
                subtitle: Text('needlocate'.tr),
                value: spc.locateEnabled.value,
                onChanged: (value) {
                  spc.locateEnabled.value = value;
                  prefs.write('locateEnabled', value);
                },
              ),
              SwitchListTile(
                title: Text('compassswitch'.tr),
                subtitle: Text('compassswitchdes'.tr),
                value: spc.compassEnabled.value,
                onChanged: (value) {
                  spc.compassEnabled.value = value;
                  prefs.write('compassEnabled', value);
                },
              ),
              ListTile(
                title: Text(
                  'maptype'.tr,
                ),
                subtitle: Text('choosemaptype'.tr),
                onTap: _selectMapType,
              ),
              ListTile(
                subtitle: Text(
                  'mapdata'.tr,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                title: Text(
                  'importdata'.tr,
                ),
                subtitle: Text('importdatafromfile'.tr),
                onTap: _pickMapData,
              ),
              ListTile(
                title: Text(
                  'managedata'.tr,
                ),
                subtitle: Text('manageimporteddata'.tr),
                onTap: _manageMapData,
              ),
              ListTile(
                subtitle: Text(
                  'logicloc'.tr,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                title: Text(
                  'importdata'.tr,
                ),
                subtitle: Text('importdatafromfile'.tr),
                onTap: _pickLogicData,
              ),
              ListTile(
                title: Text(
                  'managedata'.tr,
                ),
                subtitle: Text('manageimporteddata'.tr),
                onTap: _manageLogicData,
              ),
              ListTile(
                subtitle: Text(
                  'log'.tr,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              SwitchListTile(
                  value: spc.logEnabled.value,
                  title: Text(
                    'logswitch'.tr,
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
                  'viewlogs'.tr,
                ),
                subtitle: spc.logExisted.value
                    ? Text('viewstoredlogs'.tr)
                    : Text('nolog'.tr),
                onTap: spc.logExisted.value
                    ? () => Navigator.push(context,
                        MaterialPageRoute(builder: (context) => _MyLogPage()))
                    : null,
              ),
              ListTile(
                title: Text(
                  'exportlogs'.tr,
                ),
                subtitle: spc.logExisted.value
                    ? Text('exportlogstostorge'.tr)
                    : Text('nolog'.tr),
                onTap: spc.logExisted.value ? _outputLogFile : null,
              ),
              ListTile(
                title: Text(
                  'clearlogs'.tr,
                ),
                subtitle: spc.logExisted.value
                    ? Text('clearstoredlogs'.tr)
                    : Text('nolog'.tr),
                onTap: spc.logExisted.value ? _cleanLogFile : null,
              ),
              ListTile(
                subtitle: Text(
                  'themeandlanguage'.tr,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              SwitchListTile(
                title: Text(
                  'themefollowsystem'.tr,
                ),
                value: spc.themeFollowSystem.value,
                onChanged: (bool? value) {
                  if (value!)
                    Get.changeThemeMode(ThemeMode.system);
                  else {
                    if (spc.useDarkTheme.value)
                      Get.changeThemeMode(ThemeMode.dark);
                    else
                      Get.changeThemeMode(ThemeMode.light);
                  }
                  spc.themeFollowSystem.value = value;
                  prefs.write('themeFollowSystem', value);
                },
              ),
              SwitchListTile(
                title: Text(
                  'usedarktheme'.tr,
                ),
                value: spc.useDarkTheme.value,
                onChanged: spc.themeFollowSystem.value
                    ? null
                    : (bool? value) {
                        if (value!)
                          Get.changeThemeMode(ThemeMode.dark);
                        else
                          Get.changeThemeMode(ThemeMode.light);
                        spc.useDarkTheme.value = value;
                        prefs.write('useDarkTheme', value);
                      },
              ),
              ListTile(
                title: Text(
                  'language'.tr,
                ),
                subtitle: Text('selectlanguage'.tr),
                onTap: _selectLanguage,
              ),
              ListTile(
                subtitle: Text(
                  'others'.tr,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                title: Text(
                  'requestlocationpermission'.tr,
                ),
                subtitle: Text(
                  spc.locatePermissionStatus.value.isGranted
                      ? 'locationpermissiongranted'.tr
                      : 'locationpermissionneeded'.tr,
                ),
                onTap: spc.locatePermissionStatus.value.isGranted
                    ? null
                    : _requestLocationPermission,
              ),
              ListTile(
                title: Text(
                  'clearmapcache'.tr,
                ),
                onTap: _cleanMapCache,
              ),
              ListTile(
                title: Text(
                  'amapmapapprovalnumber'.tr,
                ),
                onTap: _showAmapAbout,
              ),
              AboutListTile(
                applicationName: 'title'.tr,
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
