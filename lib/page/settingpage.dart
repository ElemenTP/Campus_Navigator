import 'dart:io';

import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:campnavi/page/logicdatapage.dart';
import 'package:campnavi/page/logpage.dart';
import 'package:campnavi/page/mapdatapage.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:campnavi/global/global.dart';
import 'package:campnavi/translation/translation.dart';
import 'package:campnavi/controller/maincontroller.dart';

///设置界面
class SettingPage extends StatelessWidget {
  const SettingPage({Key key = const Key('setting')}) : super(key: key);

  static MainController c = Get.find();

  ///获取审图号函数，遵守高德地图Open Api的要求
  void _getApprovalNumber() async {
    //按要求获取常规地图审图号
    await c.mapController?.value.getMapContentApprovalNumber().then((value) {
      if (value != null) c.mapContentApprovalNumber = value.obs;
    });
    //按要求获取卫星地图审图号
    await c.mapController?.value
        .getSatelliteImageApprovalNumber()
        .then((value) {
      if (value != null) c.satelliteImageApprovalNumber = value.obs;
    });
  }

  ///清除地图缓存函数
  void _cleanMapCache() async {
    await c.mapController?.value.clearDisk();
    /*Get.dialog(AlertDialog(
      title: Text('tip'.tr),
      content: Text('cachecleaned'.tr),
      actions: <Widget>[
        TextButton(
          child: Text('ok'.tr),
          onPressed: () => Get.back(),
        ),
      ],
    ));*/
    Get.snackbar('tip'.tr, 'cachecleaned'.tr,
        snackPosition: SnackPosition.BOTTOM);
  }

  ///清除日志文件函数
  void _cleanLogFile() {
    logger.cleanLogFile();
    c.logExisted.value = logger.fileExists();
    /*Get.dialog(AlertDialog(
      title: Text('tip'.tr),
      content: Text('logcleared'.tr),
      actions: <Widget>[
        TextButton(
          child: Text('ok'.tr),
          onPressed: () => Get.back(),
        ),
      ],
    ));*/
    Get.snackbar('tip'.tr, 'logcleared'.tr,
        snackPosition: SnackPosition.BOTTOM);
  }

  ///导出日志文件函数
  void _outputLogFile() async {
    Directory? toStore = await getExternalStorageDirectory();
    if (toStore != null) {
      String optFilePath = '${toStore.path}/CampNaviLog${DateTime.now()}.txt';
      File optData = File(optFilePath);
      await optData.writeAsString(logger.getLogContentString());
      Get.dialog(AlertDialog(
        title: Text('tip'.tr),
        content: Text('logexportsuccess'.tr + optFilePath),
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
        content: Text('logexportfail'.tr),
        actions: <Widget>[
          TextButton(
            child: Text('ok'.tr),
            onPressed: () => Get.back(),
          ),
        ],
      ));
    }
  }

  ///管理地图文件函数，列出软件私有存储空间中所有导入的地图文件，用户可选择将任意一个设为默认，
  ///或删除

  ///管理逻辑位置文件函数，列出软件私有存储空间中所有导入的逻辑位置文件，用户可选择将任意一个
  ///设为默认，或删除，将立刻生效

  ///申请定位权限函数
  void _requestLocationPermission() async {
    // 申请位置权限
    c.locatePermissionStatus.value = await Permission.location.request();
  }

  ///展示高德地图审图号信息界面
  void _showAmapAbout() async {
    const TextStyle textStyle =
        TextStyle(fontSize: 14, fontWeight: FontWeight.normal);
    Get.dialog(AlertDialog(
      title: Text('amapmapapprovalnumber'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'mapcontentapprovalnumber'.tr,
            style: textStyle,
          ),
          Obx(
            () => Text(
              c.mapContentApprovalNumber.value,
              style: textStyle,
            ),
          ),
          Text(
            'satelliteimageapprovalnumber'.tr,
            style: textStyle,
          ),
          Obx(
            () => Text(
              c.satelliteImageApprovalNumber.value,
              style: textStyle,
            ),
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
                    groupValue: c.preferMapType.value,
                    onChanged: (MapType? value) {
                      c.preferMapType.value = value!;
                      prefs.write('preferMapType', 'satellite');
                    },
                  ),
                  RadioListTile(
                    title: Text('normal'.tr),
                    value: MapType.normal,
                    groupValue: c.preferMapType.value,
                    onChanged: (MapType? value) {
                      c.preferMapType.value = value!;
                      prefs.write('preferMapType', 'normal');
                    },
                  ),
                  RadioListTile(
                    title: Text('night'.tr),
                    value: MapType.night,
                    groupValue: c.preferMapType.value,
                    onChanged: (MapType? value) {
                      c.preferMapType.value = value!;
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
      StatefulBuilder(builder: (context, setState) {
        List<Widget> widgets = <Widget>[
          RadioListTile(
            title: Text('followsystem'.tr),
            value: Get.deviceLocale!,
            groupValue: Get.locale,
            onChanged: (Locale? value) {
              setState(() {
                Get.updateLocale(value!);
              });
              prefs.write('preferLocale', 'device');
            },
          ),
        ];
        for (Locale element in supporedLocales) {
          widgets.add(
            RadioListTile(
              title: Text(languagecode2Str[element.languageCode] ?? 'err!'),
              value: element,
              groupValue: Get.locale,
              onChanged: (Locale? value) {
                setState(() {
                  Get.updateLocale(value!);
                });
                prefs.write('preferLocale', element.languageCode);
              },
            ),
          );
        }
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
    const TextStyle subtitleStyle =
        TextStyle(fontSize: 12, fontWeight: FontWeight.bold);
    c.logExisted.value = logger.fileExists();
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
                  style: subtitleStyle,
                ),
              ),
              SwitchListTile(
                title: Text('locateswitch'.tr),
                subtitle: Text('needlocate'.tr),
                value: c.locateEnabled.value,
                onChanged: (value) {
                  c.locateEnabled.value = value;
                  prefs.write('locateEnabled', value);
                },
              ),
              SwitchListTile(
                title: Text('compassswitch'.tr),
                subtitle: Text('compassswitchdes'.tr),
                value: c.compassEnabled.value,
                onChanged: (value) {
                  c.compassEnabled.value = value;
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
                  style: subtitleStyle,
                ),
              ),
              ListTile(
                title: Text(
                  'managedata'.tr,
                ),
                subtitle: Text('manageimporteddata'.tr),
                onTap: () => Get.to(const MapDataPage()),
              ),
              ListTile(
                subtitle: Text(
                  'logicloc'.tr,
                  style: subtitleStyle,
                ),
              ),
              ListTile(
                title: Text(
                  'managedata'.tr,
                ),
                subtitle: Text('manageimporteddata'.tr),
                onTap: () => Get.to(const LogicDataPage()),
              ),
              ListTile(
                subtitle: Text(
                  'log'.tr,
                  style: subtitleStyle,
                ),
              ),
              SwitchListTile(
                  value: c.logEnabled.value,
                  title: Text(
                    'logswitch'.tr,
                  ),
                  onChanged: (value) {
                    c.logEnabled.value = value;
                    logger.setLogState(value, prefs);
                    if (value && !c.logExisted.value) {
                      c.logExisted.value = true;
                    }
                  }),
              ListTile(
                title: Text(
                  'viewlogs'.tr,
                ),
                subtitle: c.logExisted.value
                    ? Text('viewstoredlogs'.tr)
                    : Text('nolog'.tr),
                onTap: c.logExisted.value
                    ? () => Get.to(() => const LogPage())
                    : null,
              ),
              ListTile(
                title: Text(
                  'exportlogs'.tr,
                ),
                subtitle: c.logExisted.value
                    ? Text('exportlogstostorge'.tr)
                    : Text('nolog'.tr),
                onTap: c.logExisted.value ? _outputLogFile : null,
              ),
              ListTile(
                title: Text(
                  'clearlogs'.tr,
                ),
                subtitle: c.logExisted.value
                    ? Text('clearstoredlogs'.tr)
                    : Text('nolog'.tr),
                onTap: c.logExisted.value ? _cleanLogFile : null,
              ),
              ListTile(
                subtitle: Text(
                  'themeandlanguage'.tr,
                  style: subtitleStyle,
                ),
              ),
              SwitchListTile(
                title: Text(
                  'themefollowsystem'.tr,
                ),
                value: c.themeFollowSystem.value,
                onChanged: (bool? value) {
                  if (value!) {
                    Get.changeThemeMode(ThemeMode.system);
                  } else {
                    if (c.useDarkTheme.value) {
                      Get.changeThemeMode(ThemeMode.dark);
                    } else {
                      Get.changeThemeMode(ThemeMode.light);
                    }
                  }
                  c.themeFollowSystem.value = value;
                  prefs.write('themeFollowSystem', value);
                },
              ),
              SwitchListTile(
                title: Text(
                  'usedarktheme'.tr,
                ),
                value: c.useDarkTheme.value,
                onChanged: c.themeFollowSystem.value
                    ? null
                    : (bool? value) {
                        if (value!) {
                          Get.changeThemeMode(ThemeMode.dark);
                        } else {
                          Get.changeThemeMode(ThemeMode.light);
                        }
                        c.useDarkTheme.value = value;
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
                  style: subtitleStyle,
                ),
              ),
              ListTile(
                title: Text(
                  'requestlocationpermission'.tr,
                ),
                subtitle: Text(
                  c.locatePermissionStatus.value.isGranted
                      ? 'locationpermissiongranted'.tr
                      : 'locationpermissionneeded'.tr,
                ),
                onTap: c.locatePermissionStatus.value.isGranted
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
                applicationVersion:
                    '${packageInfo.version}+${packageInfo.buildNumber} $appType',
                applicationLegalese: '@notsabers 2021-2022',
              )
            ],
          ),
        ),
      ),
    );
  }
}
