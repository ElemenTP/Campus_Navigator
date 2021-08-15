import 'package:amap_flutter_base/amap_flutter_base.dart';

///用于进行多次狄杰斯特拉算法的单元
class NaviLoc {
  ///点所在校区编号
  late int campusNum;

  ///点在校区中点集的编号
  late int vertexNum;

  ///点的特征坐标
  late LatLng location;

  ///构造函数
  NaviLoc(this.campusNum, this.vertexNum, this.location);
}
