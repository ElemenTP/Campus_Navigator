import 'dart:io';

//import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:campnavi/model/mapdata.dart';
import 'package:campnavi/model/logicloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';

///自行车速度
const double bikeSpeed = 0.5;

///默认地图缩放比例
const double defaultZoom = 18;

///食堂名称
const String canteenName = '食堂';

///默认搜索半径
const double defaultRadix = 100;

///用户设置
late GetStorage prefs;

///地图数据
late MapData mapData;

///逻辑位置
late LogicLoc mapLogicLoc;

///日志文件
late File logFile;

///日志写IOSink
late IOSink logSink;

///软件信息
late PackageInfo packageInfo;

///版本信息
late String appType;

late Directory applicationDataDir;

/*const Map<String, ThemeMode> str2ThemeMode = <String, ThemeMode>{
  'system': ThemeMode.system,
  'light': ThemeMode.light,
  'dark': ThemeMode.dark,
};*/

const Map<String, MapType> str2MapType = <String, MapType>{
  'satellite': MapType.satellite,
  'normal': MapType.normal,
  'night': MapType.night,
};
