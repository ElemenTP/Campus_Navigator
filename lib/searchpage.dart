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
    setState(() {});
  }

  void _onListTileTapped(int index) {}

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
          TextButton.icon(
            icon: Icon(Icons.search),
            label: Text('搜索'),
            onPressed: _onStartSearch,
          ),
          Expanded(
            child: ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  child: ListTile(
                    title: Text(searchresult[index].description[1]),
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
