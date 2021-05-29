import 'package:flutter/material.dart';

//import 'header.dart';

//输入框控制器
TextEditingController textcontroller = TextEditingController();

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

  void _onTextButtonPressed() {
    print('search!');
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
        children: [
          TextField(
            controller: textcontroller,
            decoration: _decoration,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
            onEditingComplete: _onTextButtonPressed,
          ),
          TextButton.icon(
            icon: Icon(Icons.search),
            label: Text('搜索'),
            onPressed: _onTextButtonPressed,
          )
        ],
      ),
    );
  }
}
