///逻辑位置类
class LogicLoc {
  ///逻辑位置：建筑名与建筑别名列表的字典
  Map<String, List<String>> logicLoc = {};

  ///默认构建函数，构造空逻辑位置表
  LogicLoc();

  ///从json对象中读取
  LogicLoc.fromJson(Map<String, dynamic> json) {
    Map logicLocJson = json['logicLoc'] as Map;
    logicLocJson.forEach((key, value) {
      logicLoc[key] = List<String>.from(value);
    });
  }

  ///生成json对象
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'logicLoc': logicLoc,
    };
  }
}
