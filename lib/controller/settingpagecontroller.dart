import 'package:get/get.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:campnavi/global/global.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingPageController extends GetxController {
  ///定位权限状态
  Rx<PermissionStatus> locatePermissionStatus = PermissionStatus.denied.obs;

  ///日志开关
  RxBool logEnabled = (prefs.read<bool>('logEnabled') ?? false).obs;

  ///日志存在
  RxBool logExisted = logFile.existsSync().obs;

  ///指南针开关
  RxBool compassEnabled = (prefs.read<bool>('compassEnabled') ?? true).obs;

  ///位置能力开关
  RxBool locateEnabled = (prefs.read<bool>('compassEnabled') ?? true).obs;

  ///显示地图类型
  Rx<MapType> preferMapType =
      (prefs.read<MapType>('preferMapType') ?? MapType.satellite).obs;

  ///预设卫星地图审图号
  RxString satelliteImageApprovalNumber = '卫星地图未正常加载'.obs;

  ///预设常规地图审图号
  RxString mapContentApprovalNumber = '常规地图未正常加载'.obs;
}
