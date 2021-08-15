import 'dart:io';

import 'package:get_storage/get_storage.dart';
import 'package:campnavi/model/mapdata.dart';
import 'package:campnavi/model/logicloc.dart';
import 'package:package_info/package_info.dart';

///自行车速度
const double BIKESPEED = 0.5;

///默认地图缩放比例
const double DEFAULT_ZOOM = 18;

///食堂名称
const String CANTEEN_NAME = '食堂';

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
