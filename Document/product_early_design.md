# 产品早期设计

1. 导航功能为从点到点的形式（p2p），导航模块的起点和终点都是GPS坐标点。
2. 对于导航来说建筑物只有出入口有意义。建筑物抽象为`建筑物出入口点`，同一个建筑可拥有多个出入口。（在不同位置导航时可以由导航策略决定导向的出入口）
3. 道路抽象为两个点之间的直线~~，或者道路用高德提供的api实现~~。
4. 为了适应道路实际的形状，添加一种`道路拐点`，在道路需要变向时使用。
5. 对于存储地图精细数据的`数据结构1`使用图的数据结构，~~有点集和边集~~有建筑集，点集和边集。~~其中的元素称为`地图成分`~~。
6. 建筑集中元素有`坐标集`，`校区标志`和`描述集`三个属性。`坐标集`中为`点集`中元素，`描述集`中为该建筑的描述。
7. 点集中 `建筑物出入口点`和`道路拐点`都视为`地图点`，`地图点`有`点编号`，`点坐标`两个属性。导入后由软件使用算法生成生成唯一标识符。
8. 边集中`地图边`只有`道路`一种边，`地图边`有`边定义点1`，`边定义点2`，`边长度`，`边适应性`四个属性。导入后由软件使用算法生成生成唯一标识符。
9. 用于导入逻辑位置的`数据结构2`中的项目则称为`规则`，有`规则名称`，`信息`两个属性。导入后由软件与`地图成分`匹配。
10. 由于这两个数据结构需要导入导出，文件应当具有易编辑的属性，所以用utf-8文本存储。
11. `道路`根据实际情况赋予`边适应性`属性，校区间也用`道路`抽象连接。导航功能检测途径`道路`的各种适应性，让用户进行选择。
12. 校车班次信息在`数据结构1`结尾导入，具体形式待定。公共交通方式仅提供大致距离和预期耗时信息。
13. 食堂负载待定。
---
v0.3 20210314  
last editor: ElemenTP