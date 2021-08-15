///校车时间表类
class BusTimeTable {
  ///是否是校车
  bool isSchoolBus = false;

  ///始发校区编号
  int campusFrom = 0;

  ///目的校区编号
  int campusTo = 0;

  ///出发时间的时，0-23，违例视为任何时间
  int setOutHour = -1;

  ///出发时间的分，0-59，违例视为任何时间
  int setOutMinute = -1;

  ///星期几？1-7，7是周日，违例视为任何时间
  int dayOfWeek = 0;

  ///时间表描述
  String description = '公共交通';

  ///预计乘坐时间，单位分钟
  int takeTime = 3600;

  BusTimeTable();

  ///通过json创建对象
  BusTimeTable.fromJson(Map<String, dynamic> json) {
    isSchoolBus = json['isSchoolBus'] as bool? ?? false;
    campusFrom = json['campusFrom'] as int? ?? 0;
    campusTo = json['campusTo'] as int? ?? 0;
    setOutHour = json['setOutHour'] as int? ?? -1;
    setOutMinute = json['setOutMinute'] as int? ?? -1;
    dayOfWeek = json['dayOfWeek'] as int? ?? 0;
    description = json['description'] as String? ?? '公共交通';
    takeTime = json['takeTime'] as int? ?? 3600;
  }

  ///通过对象创建json
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'isSchoolBus': isSchoolBus,
      'campusFrom': campusFrom,
      'campusTo': campusTo,
      'setOutHour': setOutHour,
      'setOutMinute': setOutMinute,
      'dayOfWeek': dayOfWeek,
      'description': description,
      'takeTime': takeTime,
    };
  }
}
