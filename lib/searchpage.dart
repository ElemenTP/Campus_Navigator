import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'header.dart';
import 'shortpath.dart';

///输入框控制器
TextEditingController textController = TextEditingController();

///搜索结果列表
List<SearchResult> searchResult = [];

///筛选校区用布尔列表
List<bool> campusFilter = List.filled(mapData.mapCampus.length, true);

class MySearchPage extends StatefulWidget {
  MySearchPage({Key key = const Key('search')}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MySearchPageState();
}

///搜索界面，用于搜索功能，逻辑位置功能，提供附近建筑和食堂负载均衡的按钮
class _MySearchPageState extends State<MySearchPage> {
  ///输入框风格
  static const InputDecoration _textDecoration = InputDecoration(
    labelText: '搜索校园建筑',
    hintText: '名称或功能',
    border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(20.0))),
  );

  ///输入框焦点控制器
  late FocusNode textFocusNode;

  ///建筑搜索函数，基本逻辑是字符串匹配，将用户输入的字符串在用户筛选出来的所有校区的所有建筑
  ///的描述信息和逻辑位置信息中进行匹配，匹配到的建筑加入搜索结果
  void _onStartSearch() {
    textFocusNode.unfocus();
    searchResult.clear();
    String toSearch = textController.text;
    if (logEnabled)
      logSink.write(DateTime.now().toString() + ': 搜索开始，关键字"$toSearch"。\n');
    for (int i = 0; i < mapData.mapCampus.length; ++i) {
      String curCampusName = mapData[i].name;
      if (campusFilter[i]) {
        //在已选的校区中搜索
        mapData[i].listBuilding.forEach((element) {
          if (toSearch.isEmpty) {
            searchResult.add(SearchResult(element, curCampusName));
          } else {
            //匹配逻辑位置关键字
            List<String> listLogicLoc = [];
            mapLogicLoc.logicLoc[element.description.first]
                ?.forEach((element1) {
              if (element1.contains(toSearch)) listLogicLoc.add(element1);
            });
            if (listLogicLoc.isNotEmpty) {
              searchResult.add(SearchResult(element,
                  curCampusName + ' 逻辑位置: ' + listLogicLoc.join(', ')));
              return;
            }
            //匹配建筑描述关键字
            List<String> listMatched = [];
            element.description.forEach((element1) {
              if (element1.contains(toSearch)) listMatched.add(element1);
            });
            if (listMatched.isNotEmpty)
              searchResult.add(SearchResult(
                  element, curCampusName + ' 建筑描述: ' + listMatched.join(', ')));
          }
        });
      }
    }
    setState(() {});
    if (logEnabled) logSink.write(DateTime.now().toString() + ': 搜索结束。\n');
  }

  ///列表元素点击回调函数，弹窗询问用户将该建筑设为起点或终点
  void _onListTileTapped(int index) async {
    textFocusNode.unfocus();
    if (naviState.start == searchResult[index].result) {
      await showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('提示'),
                content: Text('该建筑已是起点。'),
                actions: <Widget>[
                  TextButton(
                    child: Text('取消'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                    child: Text('删除该起点'),
                    onPressed: () {
                      naviState.start = null;
                      mapMarkers.remove('start');
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ));
    } else if (naviState.end.contains(searchResult[index].result)) {
      await showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('提示'),
                content: Text('该建筑已是终点之一。'),
                actions: <Widget>[
                  TextButton(
                    child: Text('取消'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                    child: Text('删除该终点'),
                    onPressed: () {
                      naviState.end.remove(searchResult[index].result);
                      mapMarkers.remove('end' +
                          searchResult[index].result.hashCode.toString());
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ));
    } else {
      await showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('提示'),
                content: Text('要将它作为？'),
                actions: <Widget>[
                  TextButton(
                    child: Text('取消'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                    child: Text('起点'),
                    onPressed: naviState.startOnUserLoc
                        ? null
                        : () {
                            naviState.start = searchResult[index].result;
                            mapMarkers['start'] = Marker(
                              position: searchResult[index]
                                  .result
                                  .getApproxLocation(),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueOrange),
                              infoWindow: InfoWindow(
                                  title: searchResult[index]
                                      .result
                                      .description
                                      .first),
                            );
                            Navigator.of(context).pop();
                          },
                  ),
                  TextButton(
                    child: Text('终点'),
                    onPressed: () {
                      naviState.end.add(searchResult[index].result);
                      mapMarkers['end' +
                              searchResult[index].result.hashCode.toString()] =
                          Marker(
                        position:
                            searchResult[index].result.getApproxLocation(),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen),
                        infoWindow: InfoWindow(
                            title:
                                searchResult[index].result.description.first),
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ));
    }
    setState(() {});
  }

  ///搜索附近建筑函数，让用户输入搜索半径，使用NaviTools中的绘制圆形功能绘制一个该半径的圆，
  ///在当前校区的所有建筑的所有门中寻找在圆内的，并将有门在圆内的建筑添加到结果列表中，并附加
  ///上使用狄杰斯特拉算法得到的当前位置到该建筑的最短路线长度。
  void _searchNearBuilding() async {
    textFocusNode.unfocus();
    if (NaviTools.stateLocationReqiurement(context)) {
      int campusNum = mapData.locationInCampus(userLocation.latLng);
      if (campusNum >= 0) {
        int circleRad = 100;
        if (await showDialog(
                context: context,
                builder: (context) {
                  const InputDecoration _numDecoration = InputDecoration(
                    labelText: '输入搜索半径，单位为米',
                    hintText: '仅限正整数，默认100米',
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20.0))),
                  );
                  int inputRadix = -1;
                  void onInputEnd() {
                    circleRad = inputRadix;
                    Navigator.of(context).pop(false);
                  }

                  return StatefulBuilder(
                      builder: (context, _setState) => AlertDialog(
                            title: Text('搜索半径'),
                            content: TextFormField(
                              decoration: _numDecoration,
                              autofocus: true,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              keyboardType: TextInputType.number,
                              validator: (_) =>
                                  inputRadix > 0 ? null : '请输入正整数',
                              onChanged: (value) => _setState(
                                  () => inputRadix = int.tryParse(value) ?? -1),
                              onEditingComplete:
                                  inputRadix > 0 ? onInputEnd : null,
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: Text('取消'),
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                              ),
                              TextButton(
                                child: Text('默认'),
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                },
                              ),
                              TextButton(
                                child: Text('确定'),
                                onPressed: inputRadix > 0 ? onInputEnd : null,
                              ),
                            ],
                          ));
                }) ??
            true) {
          return;
        }
        if (logEnabled)
          logSink.write(DateTime.now().toString() + ': 开始搜索附近建筑。\n');
        try {
          mapData[campusNum].disableCrowding();
          List<LatLng> circlePolygon =
              NaviTools.circleAround(userLocation.latLng, circleRad);
          List<Building> nearBuilding = [];
          int nearVertex =
              mapData.nearestVertex(campusNum, userLocation.latLng);
          LatLng nearLatLng = mapData.getVertexLatLng(campusNum, nearVertex);
          double juncLength =
              AMapTools.distanceBetween(nearLatLng, userLocation.latLng);
          mapData[campusNum].listBuilding.forEach((element) {
            for (LatLng doors in element.doors) {
              if (AMapTools.latLngIsInPolygon(doors, circlePolygon)) {
                nearBuilding.add(element);
                break;
              }
            }
          });
          if (nearBuilding.isEmpty) {
            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                      title: Text('提示'),
                      content: Text('未搜索到任何建筑。'),
                      actions: <Widget>[
                        TextButton(
                          child: Text('取消'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ));
            if (logEnabled)
              logSink.write(DateTime.now().toString() + ': 未搜索到附近建筑。\n');
          } else {
            searchResult.clear();
            nearBuilding.forEach((element) {
              double distance = juncLength;
              int choosedDoor = 0;
              if (element.doors.length > 1) {
                double minDistance = double.infinity;
                for (int j = 0; j < element.doors.length; ++j) {
                  double curDistance = AMapTools.distanceBetween(
                      userLocation.latLng, element.doors[j]);
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
              searchResult.add(SearchResult(
                  element, '约' + distance.toStringAsFixed(0) + '米'));
            });
            setState(() {});
          }
        } catch (_) {
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: Text('提示'),
                    content: Text('未找到路线。请检查地图数据。'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('取消'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ));
          if (logEnabled)
            logSink.write(DateTime.now().toString() + ': 未找到路线。停止搜索附近建筑。\n');
          return;
        }
        if (logEnabled)
          logSink.write(DateTime.now().toString() + ': 附近建筑搜索完毕。\n');
      } else {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text('提示'),
                  content: Text('您不在任何校区内。'),
                  actions: <Widget>[
                    TextButton(
                      child: Text('取消'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ));
        if (logEnabled)
          logSink.write(DateTime.now().toString() + ': 您不在任何校区内，停止搜索附近建筑。\n');
      }
    } else {
      if (logEnabled)
        logSink.write(DateTime.now().toString() + ': 没有定位权限或定位不正常，停止搜索附近建筑。\n');
    }
  }

  ///食堂负载均衡函数，在当前校区的所有建筑的描述中匹配“食堂”关键字，将匹配到描述的建筑加入结果
  ///中，并附上使用CanteenArrange类随机生成的负载均衡指标信息和使用狄杰斯特拉算法得到的当前
  ///位置与其的最短路线的距离。
  void _onCanteenArrange() async {
    textFocusNode.unfocus();
    if (NaviTools.stateLocationReqiurement(context)) {
      int campusNum = mapData.locationInCampus(userLocation.latLng);
      if (campusNum >= 0) {
        if (logEnabled)
          logSink.write(DateTime.now().toString() + ': 开始食堂负载均衡。\n');
        try {
          mapData[campusNum].disableCrowding();
          List<Building> canteens = [];
          int nearVertex =
              mapData.nearestVertex(campusNum, userLocation.latLng);
          LatLng nearLatLng = mapData.getVertexLatLng(campusNum, nearVertex);
          double juncLength =
              AMapTools.distanceBetween(nearLatLng, userLocation.latLng);
          mapData[campusNum].listBuilding.forEach((element) {
            for (String des in element.description) {
              if (des.contains(CANTEEN_NAME)) {
                canteens.add(element);
                break;
              }
            }
          });
          if (canteens.isEmpty) {
            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                      title: Text('提示'),
                      content: Text('未搜索到符合条件的食堂。'),
                      actions: <Widget>[
                        TextButton(
                          child: Text('取消'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ));
            if (logEnabled)
              logSink.write(DateTime.now().toString() + ': 未搜索到符合条件的食堂。\n');
          } else {
            searchResult.clear();
            canteens.forEach((element) {
              double distance = juncLength;
              int choosedDoor = 0;
              if (element.doors.length > 1) {
                double minDistance = double.infinity;
                for (int j = 0; j < element.doors.length; ++j) {
                  double curDistance = AMapTools.distanceBetween(
                      userLocation.latLng, element.doors[j]);
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
              searchResult.add(SearchResult(
                  element,
                  '约' +
                      distance.toStringAsFixed(0) +
                      '米，预计到达时负载' +
                      arrangeObject.getPayload().toStringAsFixed(0) +
                      '%，用餐耗时' +
                      (arrangeObject.getTime() / 60).toStringAsFixed(0) +
                      '分钟。'));
            });
            setState(() {});
          }
        } catch (_) {
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: Text('提示'),
                    content: Text('未找到路线。请检查地图数据。'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('取消'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ));
          if (logEnabled)
            logSink.write(DateTime.now().toString() + ': 未找到路线。停止食堂负载均衡。\n');
          return;
        }
        if (logEnabled)
          logSink.write(DateTime.now().toString() + ': 食堂负载均衡完毕。\n');
      } else {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text('提示'),
                  content: Text('您不在任何校区内。'),
                  actions: <Widget>[
                    TextButton(
                      child: Text('取消'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ));
        if (logEnabled)
          logSink.write(DateTime.now().toString() + ': 您不在任何校区内，停止食堂负载均衡。\n');
      }
    } else {
      if (logEnabled)
        logSink.write(DateTime.now().toString() + ': 没有定位权限或定位不正常，停止食堂负载均衡。\n');
    }
  }

  ///校区筛选函数，弹窗让用户选择/不选择搜索某些校区，使用一个布尔列表实现
  void _campusFilter() async {
    textFocusNode.unfocus();
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, _setState) {
          List<Widget> listCampusCheckBox = [];
          for (int index = 0; index < mapData.mapCampus.length; ++index) {
            listCampusCheckBox.add(Card(
              child: ListTile(
                title: Text(mapData[index].name),
                selected: campusFilter[index],
                onTap: () =>
                    _setState(() => campusFilter[index] = !campusFilter[index]),
              ),
            ));
          }
          return AlertDialog(
            title: Text('校区'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: listCampusCheckBox,
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text("返回"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void initState() {
    //创建FocusNode
    textFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    //移除FocusNode
    textFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //顶栏
      appBar: AppBar(
        title: Text('搜索'),
      ),
      //中央内容区
      body: Column(
        children: <Widget>[
          SizedBox(
            width: 8,
            height: 8,
          ),
          TextField(
            controller: textController,
            focusNode: textFocusNode,
            decoration: _textDecoration,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
            onEditingComplete: _onStartSearch,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                icon: Icon(Icons.filter_alt),
                label: Text('校区'),
                onPressed: _campusFilter,
              ),
              TextButton.icon(
                icon: Icon(Icons.search),
                label: Text('搜索'),
                onPressed: _onStartSearch,
              ),
              TextButton.icon(
                  icon: Icon(Icons.delete),
                  label: Text('重置'),
                  onPressed: () {
                    setState(() {
                      textController.clear();
                      textFocusNode.unfocus();
                      searchResult.clear();
                    });
                  }),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: searchResult.length,
              itemBuilder: (BuildContext context, int index) => Card(
                child: ListTile(
                  title: Text(searchResult[index].result.description.first),
                  subtitle: Text(searchResult[index].matched),
                  selected: searchResult[index].result == naviState.start ||
                      naviState.end.contains(searchResult[index].result),
                  onTap: () => _onListTileTapped(index),
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
            heroTag: 'arrangeCanteen',
            onPressed: _onCanteenArrange,
            tooltip: '推荐食堂',
            child: Icon(Icons.food_bank),
          ),
          SizedBox(
            width: 8,
            height: 8,
          ),
          FloatingActionButton(
            heroTag: 'nearBuilding',
            onPressed: _searchNearBuilding,
            tooltip: '搜索附近建筑',
            child: Icon(Icons.near_me),
          ),
        ],
      ),
    );
  }
}

///搜索结果类
class SearchResult {
  ///搜索到的建筑
  late Building result;

  ///对结果的附加描述
  late String matched;

  ///构造函数
  SearchResult(this.result, this.matched);
}
