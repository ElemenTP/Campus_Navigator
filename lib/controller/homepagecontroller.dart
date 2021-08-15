import 'package:get/get.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';

class HomePageController extends GetxController {
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
  Rx<dynamic> start = null.obs;

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
      AMapLocation(latLng: LatLng(39.909187, 116.397451)).obs;
}
