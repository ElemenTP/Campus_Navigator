import 'package:flutter/material.dart';

class MySettingPage extends StatefulWidget {
  MySettingPage({Key key, @required this.satelliteImageApprovalNumber})
      : super(key: key);

  final String satelliteImageApprovalNumber;

  @override
  State<StatefulWidget> createState() => _MySettingPageState();
}

class _MySettingPageState extends State<MySettingPage> {
  //文字风格
  static const TextStyle _optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //顶栏
        appBar: AppBar(
          title: Text('Setting'),
        ),
        //中央内容区
        body: Center(
          child: Text(
            '卫星地图审图号：${widget.satelliteImageApprovalNumber}',
            style: _optionStyle,
          ),
        ));
  }
}
