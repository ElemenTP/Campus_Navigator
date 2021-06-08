import 'package:amap_flutter_base/amap_flutter_base.dart'; //LatLng 类型在这里面
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:campnavi/shortpath.dart';
import 'package:flutter/material.dart';

import 'header.dart';

//输入框控制器
TextEditingController textcontroller = TextEditingController();

//搜索结果列表
List<SearchResult> searchResult = [];

class MySearchPage extends StatefulWidget {
  MySearchPage({Key key = const Key('search')}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MySearchPageState();
}

class _MySearchPageState extends State<MySearchPage> {
  //输入框风格
  static const InputDecoration _decoration = InputDecoration(
    icon: Icon(Icons.school),
    labelText: '搜索校园建筑',
  );

  late FocusNode textFocusNode;

  ///搜索函数
  void _onStartSearch() {
    if (logEnabled)
      logSink.write(
          DateTime.now().toString() + ': 搜索开始，关键字${textcontroller.text}。\n');
    setState(() {
      textFocusNode.unfocus();
      searchResult.clear();
      mapData.mapBuilding.forEach((element1) {
        element1.listBuilding.forEach((element2) {
          for (String item in element2.description) {
            if (item.contains(textcontroller.text)) {
              searchResult.add(SearchResult(element2, '匹配字符串: ' + item));
              break;
            }
          }
        });
      });
    });
    if (logEnabled) logSink.write(DateTime.now().toString() + ': 搜索结束。\n');
  }

  ///列表元素点击回调函数
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
                    onPressed: () => Navigator.of(context).pop(), //关闭对话框
                  ),
                  TextButton(
                    child: Text('删除该起点'),
                    onPressed: () {
                      naviState.start = null;
                      mapMarkers.remove('start');
                      Navigator.of(context).pop();
                    }, //关闭对话框
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
                    onPressed: () => Navigator.of(context).pop(), //关闭对话框
                  ),
                  TextButton(
                    child: Text('删除该终点'),
                    onPressed: () {
                      naviState.end.remove(searchResult[index].result);
                      mapMarkers.remove('end' +
                          searchResult[index].result.hashCode.toString());
                      Navigator.of(context).pop();
                    }, //关闭对话框
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
                    onPressed: () => Navigator.of(context).pop(), //关闭对话框
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
                                      .description[0]),
                            );
                            Navigator.of(context).pop();
                          }, //关闭对话框
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
                            title: searchResult[index].result.description[0]),
                      );
                      Navigator.of(context).pop();
                    }, //关闭对话框
                  ),
                ],
              ));
    }
    setState(() {});
  }

  ///搜索附近建筑函数
  void _searchNearBuilding() async {
    textFocusNode.unfocus();
    if (NaviTools.stateLocationReqiurement(context)) {
      int campusNum = mapData.locationInCampus(userLocation.latLng);
      if (campusNum >= 0) {
        if (logEnabled)
          logSink.write(DateTime.now().toString() + ': 开始搜索附近建筑。\n');
        try {
          mapData.mapEdge[campusNum].disableCrowding();
          List<LatLng> circlePolygon =
              NaviTools.circleAround(userLocation.latLng);
          List<Building> nearBuilding = [];
          int nearVertex =
              mapData.nearestVertex(campusNum, userLocation.latLng);
          LatLng nearLatLng = mapData.getVertexLatLng(campusNum, nearVertex);
          double juncLength =
              AMapTools.distanceBetween(nearLatLng, userLocation.latLng);
          mapData.mapBuilding[campusNum].listBuilding.forEach((element) {
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
                          onPressed: () => Navigator.of(context).pop(), //关闭对话框
                        ),
                      ],
                    ));
            if (logEnabled)
              logSink.write(DateTime.now().toString() + ': 未搜索到附近建筑。\n');
            return;
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
                Shortpath path = Shortpath(mapData.getAdjacentMatrix(campusNum),
                    nearVertex, element.juncpoint[choosedDoor], 0);
                distance += path.getrelativelen();
              }
              searchResult.add(SearchResult(
                  element, '约' + distance.toStringAsFixed(0) + '米'));
            });
            if (logEnabled)
              logSink.write(DateTime.now().toString() + ': 附近建筑搜索完毕。\n');
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
                        onPressed: () => Navigator.of(context).pop(), //关闭对话框
                      ),
                    ],
                  ));
          if (logEnabled)
            logSink.write(DateTime.now().toString() + ': 未找到路线。请检查地图数据。\n');
        }
      } else {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text('提示'),
                  content: Text('您不在任何校区内。'),
                  actions: <Widget>[
                    TextButton(
                      child: Text('取消'),
                      onPressed: () => Navigator.of(context).pop(), //关闭对话框
                    ),
                  ],
                ));
        return;
      }
    }
  }

  @override
  void initState() {
    //创建FocusNode
    textFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
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
          TextField(
            controller: textcontroller,
            focusNode: textFocusNode,
            decoration: _decoration,
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
                onPressed: _onStartSearch,
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
                      textcontroller.clear();
                      textFocusNode.unfocus();
                      searchResult.clear();
                    });
                  }),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: searchResult.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  child: ListTile(
                    title: Text(searchResult[index].result.description[0]),
                    subtitle: Text(searchResult[index].matched),
                    selected: searchResult[index].result == naviState.start ||
                        naviState.end.contains(searchResult[index].result),
                    onTap: () {
                      _onListTileTapped(index);
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'nearBuilding',
        onPressed: _searchNearBuilding,
        tooltip: '搜索附近建筑',
        child: Icon(Icons.near_me),
      ),
    );
  }
}

class SearchResult {
  late Building result;
  late String matched;

  SearchResult(this.result, this.matched);
}
