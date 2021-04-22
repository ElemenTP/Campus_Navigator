# Shortpath 最短路径类
改类代表着计算好了的最短路径，其构造函数就算最短路径的计算算法，在构造时需要输入起点ID，终点ID，运动方式，边矩阵。该类具象化的一个对象代表着给定的起点到终点的一条最短路径
## 成员
***
### maxnum（final）
路径能够到达的最大值，它被赋值为`double.indifinity`，且不可以被更改；
***
### onBike（final）
如果运动方式为骑自行车，道路会打折的倍率。例如，当onBike=0.3时，道路长度在计算时会变为之前的`70%`。
***
### int endvertexID
终点ID
***
### int transmethod
运动方式
***
### List<int> route
路径集
***
### double relativelen
路径的相对长度
***
## 方法
***
### pathlength
给出一个边，计算它的相对长度，受拥挤度和出行方式的影响
#### 参数
Edge edge 要计算的边
int transmethod 用户的运动方式
#### 返回值
double 该路径的相对长度
***
### getroute
获得该路径的路径集
***
### getrelativelen
获得该路径的相对长度