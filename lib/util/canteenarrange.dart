import 'dart:math';

///食堂负载均衡类
class CanteenArrange {
  ///到食堂的时间
  late double pathtime;

  ///到食堂时的人数
  late int result;

  ///食堂最大人数
  static const int capacity = 150;

  ///食堂负载与每30秒进入人数的字典
  static const Map<int, int> ntovin = {1: 1, 2: 3, 3: 2};

  ///食堂负载与每30秒离开人数的字典
  static const Map<int, int> ntovout = {1: 0, 2: 1, 3: 2};

  ///负载均衡构建函数，将随机一个当前食堂人数，计算预计到达时的食堂人数
  CanteenArrange(this.pathtime) {
    int flowin, flowout;
    int number = Random().nextInt(150);
    for (double i = 0; i <= pathtime; i += 30) {
      int tmp = 0;

      if (number / capacity <= 0.25) {
        tmp = 1;
      } else if (number / capacity <= 0.75) {
        tmp = 2;
      } else {
        tmp = 3;
      }
      var fin = ntovin[tmp] ?? 0;
      flowin = fin;
      var fout = ntovout[tmp] ?? 0;
      flowout = fout;
      number = number + flowin - flowout;
    }
    result = number;
  }

  ///获取预计用餐时间
  double getTime() {
    if (result > capacity) {
      return double.infinity;
    } else {
      return 12 * result + pathtime;
    }
  }

  ///获取到达时食堂负载百分比
  double getPayload() {
    return (result / capacity) * 100;
  }
}
