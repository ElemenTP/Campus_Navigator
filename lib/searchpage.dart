import 'package:flutter/material.dart';

class MySearchPage extends StatefulWidget {
  MySearchPage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MySearchPageState();
}

class _MySearchPageState extends State<MySearchPage> {
  //文字风格
  static const TextStyle _optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //顶栏
        appBar: AppBar(
          title: Text('搜索'),
        ),
        //中央内容区
        body: Center(
          child: Text(
            '施工中',
            style: _optionStyle,
          ),
        ));
  }
}
