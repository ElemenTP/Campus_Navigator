import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:campnavi/global/global.dart';
import 'package:campnavi/model/searchresult.dart';
import 'package:permission_handler/permission_handler.dart';

class MainController extends GetxController {
  ///导航状态
  RxBool naviStatus = false.obs;

  ///是否启用拥挤度
  RxBool crowding = false.obs;

  ///是否骑车
  RxBool onbike = false.obs;

  ///是否以用户位置为起点
  RxBool startOnUserLoc = false.obs;

  ///是否实时导航
  RxBool realTime = false.obs;

  ///是够使用最短时间策略
  RxBool minTime = false.obs;

  ///起点
  RxList start = [].obs;

  ///终点集合
  RxList end = [].obs;

  ///路径相对长度
  RxDouble routeLength = 0.0.obs;

  ///地图Marker
  RxMap<String, Marker> mapMarkers = <String, Marker>{}.obs;

  ///地图直线
  RxList<Polyline> mapPolylines = <Polyline>[].obs;

  ///地图控制器
  Rx<AMapController>? mapController;

  ///用户位置
  Rx<AMapLocation> userLocation =
      const AMapLocation(latLng: LatLng(39.909187, 116.397451)).obs;

  ///输入框控制器
  TextEditingController textController = TextEditingController();

  ///搜索结果列表
  RxList<SearchResult> searchResult = <SearchResult>[].obs;

  ///筛选校区用布尔列表
  RxList<bool> campusFilter =
      List<bool>.filled(mapData.mapCampus.length, true).obs;

  ///输入框焦点控制器
  FocusNode textFocusNode = FocusNode();

  ///定位权限状态
  Rx<PermissionStatus> locatePermissionStatus = PermissionStatus.denied.obs;

  ///日志开关
  RxBool logEnabled = (prefs.read<bool>('logEnabled') ?? false).obs;

  ///日志存在
  RxBool logExisted = logFile.existsSync().obs;

  ///指南针开关
  RxBool compassEnabled = (prefs.read<bool>('compassEnabled') ?? true).obs;

  ///位置能力开关
  RxBool locateEnabled = (prefs.read<bool>('locateEnabled') ?? true).obs;

  ///显示地图类型
  Rx<MapType> preferMapType =
      (str2MapType[prefs.read<String>('preferMapType') ?? 'satellite'] ??
              MapType.satellite)
          .obs;

  ///预设卫星地图审图号
  RxString satelliteImageApprovalNumber = '卫星地图未正常加载'.obs;

  ///预设常规地图审图号
  RxString mapContentApprovalNumber = '常规地图未正常加载'.obs;

  ///主题跟随系统
  RxBool themeFollowSystem =
      (prefs.read<bool>('themeFollowSystem') ?? true).obs;

  ///使用暗色主题
  RxBool useDarkTheme = (prefs.read<bool>('useDarkTheme') ?? false).obs;
}
