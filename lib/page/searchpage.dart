import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:campnavi/global/global.dart';
import 'package:campnavi/util/naviutil.dart';
import 'package:campnavi/util/shortpath.dart';
import 'package:campnavi/util/canteenarrange.dart';
import 'package:campnavi/model/building.dart';
import 'package:campnavi/model/searchresult.dart';
import 'package:campnavi/controller/searchpagecontroller.dart';
import 'package:campnavi/controller/settingpagecontroller.dart';
import 'package:campnavi/controller/homepagecontroller.dart';

///搜索界面，用于搜索功能，逻辑位置功能，提供附近建筑和食堂负载均衡的按钮
class SearchPage extends StatelessWidget {
  SearchPage({Key key = const Key('search')}) : super(key: key);

  static SearchPageController shc =
      Get.put<SearchPageController>(SearchPageController(), permanent: true);

  static SettingPageController spc = Get.find();

  static HomePageController hpc = Get.find();

  ///建筑搜索函数，基本逻辑是字符串匹配，将用户输入的字符串在用户筛选出来的所有校区的所有建筑
  ///的描述信息和逻辑位置信息中进行匹配，匹配到的建筑加入搜索结果
  void _onStartSearch() {
    shc.textFocusNode.unfocus();
    shc.searchResult.clear();
    String toSearch = shc.textController.text;
    if (spc.logEnabled.value)
      logSink.write(DateTime.now().toString() + ': 搜索开始，关键字：$toSearch。\n');
    for (int i = 0; i < mapData.mapCampus.length; ++i) {
      String curCampusName = mapData[i].name;
      if (shc.campusFilter[i]) {
        //在已选的校区中搜索
        mapData[i].listBuilding.forEach((element) {
          if (toSearch.isEmpty) {
            shc.searchResult.add(SearchResult(element, curCampusName));
          } else {
            //匹配逻辑位置关键字
            List<String> listLogicLoc = [];
            mapLogicLoc.logicLoc[element.description.first]
                ?.forEach((element1) {
              if (element1.contains(toSearch)) listLogicLoc.add(element1);
            });
            if (listLogicLoc.isNotEmpty) {
              shc.searchResult.add(SearchResult(
                  element,
                  curCampusName +
                      'matchlogicloc'.tr +
                      listLogicLoc.join(', ')));
              return;
            }
            //匹配建筑描述关键字
            List<String> listMatched = [];
            element.description.forEach((element1) {
              if (element1.contains(toSearch)) listMatched.add(element1);
            });
            if (listMatched.isNotEmpty)
              shc.searchResult.add(SearchResult(
                  element,
                  curCampusName +
                      'matchbuildingdes'.tr +
                      listMatched.join(', ')));
          }
        });
      }
    }
    if (spc.logEnabled.value)
      logSink.write(DateTime.now().toString() + ': 搜索结束。\n');
  }

  ///列表元素点击回调函数，弹窗询问用户将该建筑设为起点或终点
  void _onListTileTapped(int index) async {
    shc.textFocusNode.unfocus();
    Building curResult = shc.searchResult[index].result;
    if (hpc.start.isNotEmpty && hpc.start.first == curResult) {
      await Get.dialog(AlertDialog(
        title: Text('tip'.tr),
        content: Text('alreadystart'.tr),
        actions: <Widget>[
          TextButton(
            child: Text('cancel'.tr),
            onPressed: () => Get.back(),
          ),
          TextButton(
            child: Text('deletestart'.tr),
            onPressed: () {
              hpc.start.clear();
              hpc.mapMarkers.remove('start');
              Get.back();
            },
          ),
        ],
      ));
    } else if (hpc.end.contains(curResult)) {
      await Get.dialog(AlertDialog(
        title: Text('tip'.tr),
        content: Text('alreadyend'.tr),
        actions: <Widget>[
          TextButton(
            child: Text('cancel'.tr),
            onPressed: () => Get.back(),
          ),
          TextButton(
            child: Text('deleteend'.tr),
            onPressed: () {
              hpc.end.remove(shc.searchResult[index].result);
              hpc.mapMarkers.remove(
                  'end' + shc.searchResult[index].result.hashCode.toString());
              Get.back();
            },
          ),
        ],
      ));
    } else {
      await Get.dialog(AlertDialog(
        title: Text('tip'.tr),
        content: Text('useitas'.tr),
        actions: <Widget>[
          TextButton(
            child: Text('cancel'.tr),
            onPressed: () => Get.back(),
          ),
          TextButton(
            child: Text('startpoint'.tr),
            onPressed: hpc.startOnUserLoc.value
                ? null
                : () {
                    hpc.start.clear();
                    hpc.start.add(curResult);
                    hpc.mapMarkers['start'] = Marker(
                      position: curResult.getApproxLocation(),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueOrange),
                      onTap: (_) => Get.dialog(AlertDialog(
                        title: Text('deletestart'.tr),
                        content: Text('wantdeletestart'.tr),
                        actions: <Widget>[
                          TextButton(
                            child: Text('cancel'.tr),
                            onPressed: () => Get.back(),
                          ),
                          TextButton(
                            child: Text('ok'.tr),
                            onPressed: () {
                              hpc.start.clear();
                              hpc.mapMarkers.remove('start');
                              Get.back();
                            },
                          ),
                        ],
                      )),
                    );
                    Get.back();
                  },
          ),
          TextButton(
            child: Text('endpoint'.tr),
            onPressed: () {
              hpc.end.add(curResult);
              String markerId = 'end' + curResult.hashCode.toString();
              hpc.mapMarkers[markerId] = Marker(
                position: curResult.getApproxLocation(),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen),
                onTap: (_) => Get.dialog(
                  AlertDialog(
                    title: Text('deleteend'.tr),
                    content: Text('wantdeleteend'.tr),
                    actions: <Widget>[
                      TextButton(
                        child: Text('cancel'.tr),
                        onPressed: () => Get.back(),
                      ),
                      TextButton(
                        child: Text('ok'.tr),
                        onPressed: () {
                          hpc.end.remove(hpc.mapMarkers[markerId]!.position);
                          hpc.mapMarkers.remove(markerId);
                          Get.back();
                        },
                      ),
                    ],
                  ),
                ),
              );
              Get.back();
            },
          ),
        ],
      ));
    }
  }

  ///搜索附近建筑函数，让用户输入搜索半径，使用NaviTools中的绘制圆形功能绘制一个该半径的圆，
  ///在当前校区的所有建筑的所有门中寻找在圆内的，并将有门在圆内的建筑添加到结果列表中，并附加
  ///上使用狄杰斯特拉算法得到的当前位置到该建筑的最短路线长度。
  void _searchNearBuilding() async {
    shc.textFocusNode.unfocus();
    if (NaviUtil.stateLocationReqiurement(spc, hpc)) {
      int campusNum = mapData.locationInCampus(hpc.userLocation.value.latLng);
      if (campusNum >= 0) {
        double circleRad = DEFAULT_RADIX;
        shc.inputRadix.value = -1;
        if (await Get.dialog(Obx(() {
              void onInputEnd() {
                circleRad = shc.inputRadix.value;
                Get.back<bool>(result: false);
              }

              return AlertDialog(
                title: Text('searchradius'.tr),
                content: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'inputlabel'.tr,
                    hintText: 'inputhint'.tr,
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20.0))),
                  ),
                  autofocus: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  keyboardType: TextInputType.number,
                  validator: (_) =>
                      shc.inputRadix.value > 0 ? null : 'inputvalidate'.tr,
                  onChanged: (value) =>
                      shc.inputRadix.value = double.tryParse(value) ?? -1,
                  onEditingComplete:
                      shc.inputRadix.value > 0 ? onInputEnd : null,
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('cancel'.tr),
                    onPressed: () => Get.back<bool>(result: true),
                  ),
                  TextButton(
                    child: Text('default'.tr),
                    onPressed: () {
                      Get.back<bool>(result: false);
                    },
                  ),
                  TextButton(
                    child: Text('ok'.tr),
                    onPressed: shc.inputRadix.value > 0 ? onInputEnd : null,
                  ),
                ],
              );
            })) ??
            true) {
          return;
        }
        if (spc.logEnabled.value)
          logSink.write(DateTime.now().toString() + ': 开始搜索附近建筑。\n');
        try {
          mapData[campusNum].disableCrowding();
          List<LatLng> circlePolygon =
              NaviUtil.circleAround(hpc.userLocation.value.latLng, circleRad);
          List<Building> nearBuilding = [];
          int nearVertex =
              mapData.nearestVertex(campusNum, hpc.userLocation.value.latLng);
          LatLng nearLatLng = mapData.getVertexLatLng(campusNum, nearVertex);
          double juncLength = AMapTools.distanceBetween(
              nearLatLng, hpc.userLocation.value.latLng);
          mapData[campusNum].listBuilding.forEach((element) {
            for (LatLng doors in element.doors) {
              if (AMapTools.latLngIsInPolygon(doors, circlePolygon)) {
                nearBuilding.add(element);
                break;
              }
            }
          });
          if (nearBuilding.isEmpty) {
            Get.dialog(AlertDialog(
              title: Text('tip'.tr),
              content: Text('nobuildingfound'.tr),
              actions: <Widget>[
                TextButton(
                  child: Text('cancel'.tr),
                  onPressed: () => Get.back(),
                ),
              ],
            ));
            if (spc.logEnabled.value)
              logSink.write(DateTime.now().toString() + ': 未搜索到附近建筑。\n');
          } else {
            shc.searchResult.clear();
            nearBuilding.forEach((element) {
              double distance = juncLength;
              int choosedDoor = 0;
              if (element.doors.length > 1) {
                double minDistance = double.infinity;
                for (int j = 0; j < element.doors.length; ++j) {
                  double curDistance = AMapTools.distanceBetween(
                      hpc.userLocation.value.latLng, element.doors[j]);
                  if (curDistance < minDistance) {
                    minDistance = curDistance;
                    choosedDoor = j;
                  }
                }
              }
              LatLng juncLatLng = mapData.getVertexLatLng(
                  campusNum, element.juncpoint[choosedDoor]);
              distance += AMapTools.distanceBetween(
                  juncLatLng, element.doors[choosedDoor]);
              if (nearLatLng != juncLatLng) {
                ShortPath path = ShortPath(mapData.getAdjacentMatrix(campusNum),
                    nearVertex, element.juncpoint[choosedDoor], 0);
                distance += path.getRelativeLen();
              }
              shc.searchResult.add(SearchResult(
                  element, 'about'.tr + distance.toStringAsFixed(0) + 'm'.tr));
            });
          }
        } catch (_) {
          Get.dialog(AlertDialog(
            title: Text('tip'.tr),
            content: Text('mapdataerr'.tr),
            actions: <Widget>[
              TextButton(
                child: Text('cancel'.tr),
                onPressed: () => Get.back(),
              ),
            ],
          ));
          if (spc.logEnabled.value)
            logSink.write(DateTime.now().toString() + ': 未找到路线。停止搜索附近建筑。\n');
          return;
        }
        if (spc.logEnabled.value)
          logSink.write(DateTime.now().toString() + ': 附近建筑搜索完毕。\n');
      } else {
        Get.dialog(AlertDialog(
          title: Text('tip'.tr),
          content: Text('notincampus'.tr),
          actions: <Widget>[
            TextButton(
              child: Text('cancel'.tr),
              onPressed: () => Get.back(),
            ),
          ],
        ));
        if (spc.logEnabled.value)
          logSink.write(DateTime.now().toString() + ': 您不在任何校区内，停止搜索附近建筑。\n');
      }
    } else {
      if (spc.logEnabled.value)
        logSink.write(DateTime.now().toString() + ': 没有定位权限或定位不正常，停止搜索附近建筑。\n');
    }
  }

  ///食堂负载均衡函数，在当前校区的所有建筑的描述中匹配“食堂”关键字，将匹配到描述的建筑加入结果
  ///中，并附上使用CanteenArrange类随机生成的负载均衡指标信息和使用狄杰斯特拉算法得到的当前
  ///位置与其的最短路线的距离。
  void _onCanteenArrange() async {
    shc.textFocusNode.unfocus();
    if (NaviUtil.stateLocationReqiurement(spc, hpc)) {
      int campusNum = mapData.locationInCampus(hpc.userLocation.value.latLng);
      if (campusNum >= 0) {
        if (spc.logEnabled.value)
          logSink.write(DateTime.now().toString() + ': 开始食堂负载均衡。\n');
        try {
          mapData[campusNum].disableCrowding();
          List<Building> canteens = [];
          int nearVertex =
              mapData.nearestVertex(campusNum, hpc.userLocation.value.latLng);
          LatLng nearLatLng = mapData.getVertexLatLng(campusNum, nearVertex);
          double juncLength = AMapTools.distanceBetween(
              nearLatLng, hpc.userLocation.value.latLng);
          mapData[campusNum].listBuilding.forEach((element) {
            for (String des in element.description) {
              if (des.contains(CANTEEN_NAME)) {
                canteens.add(element);
                break;
              }
            }
          });
          if (canteens.isEmpty) {
            Get.dialog(AlertDialog(
              title: Text('tip'.tr),
              content: Text('nocanteenfoun'.tr),
              actions: <Widget>[
                TextButton(
                  child: Text('cancel'.tr),
                  onPressed: () => Get.back(),
                ),
              ],
            ));
            if (spc.logEnabled.value)
              logSink.write(DateTime.now().toString() + ': 未搜索到符合条件的食堂。\n');
          } else {
            shc.searchResult.clear();
            canteens.forEach((element) {
              double distance = juncLength;
              int choosedDoor = 0;
              if (element.doors.length > 1) {
                double minDistance = double.infinity;
                for (int j = 0; j < element.doors.length; ++j) {
                  double curDistance = AMapTools.distanceBetween(
                      hpc.userLocation.value.latLng, element.doors[j]);
                  if (curDistance < minDistance) {
                    minDistance = curDistance;
                    choosedDoor = j;
                  }
                }
              }
              LatLng juncLatLng = mapData.getVertexLatLng(
                  campusNum, element.juncpoint[choosedDoor]);
              distance += AMapTools.distanceBetween(
                  juncLatLng, element.doors[choosedDoor]);
              if (nearLatLng != juncLatLng) {
                ShortPath path = ShortPath(mapData.getAdjacentMatrix(campusNum),
                    nearVertex, element.juncpoint[choosedDoor], 0);
                distance += path.getRelativeLen();
              }
              CanteenArrange arrangeObject = CanteenArrange(distance);
              shc.searchResult.add(SearchResult(
                  element,
                  'about'.tr +
                      distance.toStringAsFixed(0) +
                      'm'.tr +
                      'canteen1'.tr +
                      arrangeObject.getPayload().toStringAsFixed(0) +
                      '%' +
                      'canteen2'.tr +
                      (arrangeObject.getTime() / 60).toStringAsFixed(0) +
                      'min'.tr));
            });
          }
        } catch (_) {
          Get.dialog(AlertDialog(
            title: Text('tip'.tr),
            content: Text('mapdataerr'.tr),
            actions: <Widget>[
              TextButton(
                child: Text('cancel'.tr),
                onPressed: () => Get.back(),
              ),
            ],
          ));
          if (spc.logEnabled.value)
            logSink.write(DateTime.now().toString() + ': 未找到路线。停止食堂负载均衡。\n');
          return;
        }
        if (spc.logEnabled.value)
          logSink.write(DateTime.now().toString() + ': 食堂负载均衡完毕。\n');
      } else {
        Get.dialog(AlertDialog(
          title: Text('tip'.tr),
          content: Text('notincampus'.tr),
          actions: <Widget>[
            TextButton(
              child: Text('cancel'.tr),
              onPressed: () => Get.back(),
            ),
          ],
        ));
        if (spc.logEnabled.value)
          logSink.write(DateTime.now().toString() + ': 您不在任何校区内，停止食堂负载均衡。\n');
      }
    } else {
      if (spc.logEnabled.value)
        logSink.write(DateTime.now().toString() + ': 没有定位权限或定位不正常，停止食堂负载均衡。\n');
    }
  }

  ///校区筛选函数，弹窗让用户选择/不选择搜索某些校区，使用一个布尔列表实现
  void _campusFilter() async {
    shc.textFocusNode.unfocus();
    await Get.dialog(AlertDialog(
      title: Text('campus'.tr),
      content: SingleChildScrollView(
        child: Obx(() {
          List<Widget> listCampusCheckBox = [];
          for (int index = 0; index < mapData.mapCampus.length; ++index) {
            listCampusCheckBox.add(Card(
              child: SwitchListTile(
                value: shc.campusFilter[index],
                title: Text(mapData[index].name),
                onChanged: (value) => shc.campusFilter[index] = value,
              ),
            ));
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: listCampusCheckBox,
          );
        }),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('back'.tr),
          onPressed: () => Get.back(),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //顶栏
      appBar: AppBar(
        title: Text('search'.tr),
      ),
      //中央内容区
      body: Column(
        children: <Widget>[
          SizedBox(
            width: 8,
            height: 8,
          ),
          TextField(
            controller: shc.textController,
            focusNode: shc.textFocusNode,
            decoration: InputDecoration(
              labelText: 'searchcampusbuilding'.tr,
              hintText: 'nameorfeature'.tr,
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0))),
            ),
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
            onEditingComplete: _onStartSearch,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                icon: Icon(Icons.filter_alt),
                label: Text('campus'.tr),
                onPressed: _campusFilter,
              ),
              TextButton.icon(
                icon: Icon(Icons.search),
                label: Text('search'.tr),
                onPressed: _onStartSearch,
              ),
              TextButton.icon(
                  icon: Icon(Icons.delete),
                  label: Text('reset'.tr),
                  onPressed: () {
                    shc.textController.clear();
                    shc.textFocusNode.unfocus();
                    shc.searchResult.clear();
                  }),
            ],
          ),
          Expanded(
            child: Obx(
              () => ListView.builder(
                itemCount: shc.searchResult.length,
                itemBuilder: (BuildContext context, int index) => Card(
                  child: ListTile(
                    title:
                        Text(shc.searchResult[index].result.description.first),
                    subtitle: Text(shc.searchResult[index].matched),
                    onTap: () => _onListTileTapped(index),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: UniqueKey(),
            onPressed: _onCanteenArrange,
            tooltip: 'recommendcanteen'.tr,
            child: Icon(Icons.food_bank),
          ),
          SizedBox(
            width: 8,
            height: 8,
          ),
          FloatingActionButton(
            heroTag: UniqueKey(),
            onPressed: _searchNearBuilding,
            tooltip: 'searchnearby'.tr,
            child: Icon(Icons.near_me),
          ),
        ],
      ),
    );
  }
}
