import 'package:flutter/material.dart';

import 'header.dart';

//输入框控制器
TextEditingController textcontroller = TextEditingController();

//搜索结果列表
List<Building> searchresult = [];

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

  void _onStartSearch() {
    setState(() {
      searchresult.clear();
      mapData.mapBuilding.forEach((element1) {
        element1.listBuilding.forEach((element2) {
          for (String item in element2.description) {
            if (item.contains(textcontroller.text)) {
              searchresult.add(element2);
              break;
            }
          }
        });
      });
    });
  }

  void _onListTileTapped(int index) async {
    if (navistate.startBuilding == searchresult[index]) {
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
                      navistate.startBuilding = null;
                      Navigator.of(context).pop();
                    }, //关闭对话框
                  ),
                ],
              ));
    } else if (navistate.endBuilding.contains(searchresult[index])) {
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
                      navistate.endBuilding.remove(searchresult[index]);
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
                    onPressed: () {
                      navistate.startLocation = null;
                      navistate.startBuilding = searchresult[index];
                      Navigator.of(context).pop();
                    }, //关闭对话框
                  ),
                  TextButton(
                    child: Text('终点'),
                    onPressed: () {
                      navistate.endBuilding.add(searchresult[index]);
                      Navigator.of(context).pop();
                    }, //关闭对话框
                  ),
                ],
              ));
    }
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
                label: Text('筛选'),
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
                      searchresult.clear();
                    });
                  }),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  child: ListTile(
                    title: Text(searchresult[index].description[0]),
                    subtitle: Text('Matched String'),
                    onTap: () {
                      _onListTileTapped(index);
                    },
                  ),
                );
              },
              itemCount: searchresult.length,
            ),
          )
        ],
      ),
    );
  }
}
