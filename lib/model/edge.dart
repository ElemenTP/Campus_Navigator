///边类,道路上两点构成的边，存储两点在点集中的角标
class Edge {
  ///道路两点
  int pointa = -1;
  int pointb = -1;

  ///边长度，建造函数自动生成
  double length = double.infinity;

  ///边适应性，默认不通（<0），仅可步行(0)，可使用自行车(1)
  int availmthod = -1;

  ///边拥挤度，需要时调用随机方法生成
  double crowding = 1;

  ///默认构造函数，将生成不通的边
  Edge();

  ///从json中创建对象
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'pointa': pointa,
      'pointb': pointb,
      'length': length,
      'availmthod': availmthod,
    };
  }

  ///由对象生成json
  Edge.fromJson(Map<String, dynamic> json) {
    pointa = json['pointa'] as int? ?? -1;
    pointb = json['pointb'] as int? ?? -1;
    length = json['length'] as double? ?? double.infinity;
    availmthod = json['availmthod'] as int? ?? -1;
  }
}
