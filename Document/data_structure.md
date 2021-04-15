# 数据结构

class Building  
List<int> doors  
入口集，坐标  
List<String> description  
描述集，字符串  
int incampus  
校区标志  
***
map mapvertex  
int : LatLng  
编号对应坐标
***
class edge  
double length  
边长度  
int availmthod  
边适应性  
0是仅步行  
1可骑车  
double crowding  
边拥挤度
***
map mapbuilding  
int:String  
编号对应名称