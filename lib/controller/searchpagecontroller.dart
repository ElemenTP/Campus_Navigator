import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:campnavi/global/global.dart';
import 'package:campnavi/model/searchresult.dart';

class SearchPageController extends GetxController {
  ///输入框控制器
  TextEditingController textController = TextEditingController();

  ///搜索结果列表
  RxList<SearchResult> searchResult = <SearchResult>[].obs;

  ///筛选校区用布尔列表
  RxList<bool> campusFilter =
      List<bool>.filled(mapData.mapCampus.length, true).obs;

  ///输入框焦点控制器
  FocusNode textFocusNode = FocusNode();
}
