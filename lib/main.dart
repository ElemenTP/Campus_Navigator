import 'dart:io';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:campnavi/page/homepage.dart';
import 'package:campnavi/global/global.dart';
import 'package:campnavi/model/logicloc.dart';
import 'package:campnavi/model/mapdata.dart';
import 'package:campnavi/translation/translation.dart';

void main() async {
  //获取持久化设置内容
  await GetStorage.init();
  prefs = GetStorage();
  //初始化Flutter环境
  WidgetsFlutterBinding.ensureInitialized();
  //初始化日志功能
  bool logEnabled = prefs.read<bool>('logEnabled') ?? false;
  Directory logFileDir = await getApplicationDocumentsDirectory();
  logFile = File(logFileDir.path + '/NaviLog.txt');
  if (logEnabled) logSink = logFile.openWrite(mode: FileMode.append);
  //获取软件信息
  packageInfo = await PackageInfo.fromPlatform();
  //检查软件版本
  appType = (bool.fromEnvironment('dart.vm.product', defaultValue: false))
      ? 'Release'
      : (bool.fromEnvironment('dart.vm.profile', defaultValue: false))
          ? 'Profile'
          : 'Debug';
  if (logEnabled)
    logSink.write(DateTime.now().toString() +
        ': 版本：' +
        packageInfo.version +
        '+' +
        packageInfo.buildNumber +
        ' ' +
        appType +
        '\n');
  //初始化地图数据
  String? dataFileDir = prefs.read<String>('dataFileDir');
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
  String? logicLocFileDir = prefs.read<String>('logicLocFileDir');
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
  //读取语言偏好
  String preferLocaleStr = prefs.read<String>('preferLocale') ?? 'device';
  //运行应用界面
  runApp(GetMaterialApp(
    key: UniqueKey(),
    onGenerateTitle: (context) {
      print('title'.tr);
      return 'title'.tr;
    },
    translations: Translation(),
    supportedLocales: supporedLocales,
    localizationsDelegates: <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    locale: preferLocaleStr == 'device'
        ? Get.deviceLocale
        : Locale(preferLocaleStr),
    fallbackLocale: supporedLocales.last,
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    themeMode: (prefs.read<bool>('themeFollowSystem') ?? true)
        ? ThemeMode.system
        : (prefs.read<bool>('useDarkTheme') ?? false)
            ? ThemeMode.dark
            : ThemeMode.light,
    home: HomePage(),
  ));
}
