import 'package:campnavi/model/building.dart';

///搜索结果类
class SearchResult {
  ///搜索到的建筑
  late Building result;

  ///对结果的附加描述
  late String matched;

  ///构造函数
  SearchResult(this.result, this.matched);
}
