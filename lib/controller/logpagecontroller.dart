import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LogPageController extends GetxController {
  late List<String> listLogString;

  ///输入框控制器
  TextEditingController textController = TextEditingController();

  ///搜索结果列表
  RxList<String> searchResult = <String>[].obs;

  ///输入框焦点控制器
  FocusNode textFocusNode = FocusNode();

  ///列表滚动控制器
  ScrollController scrollController = ScrollController();
}
