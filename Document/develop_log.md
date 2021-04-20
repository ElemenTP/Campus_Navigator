# 开发日志

20210317 ElemenTP  

1. 使用的flutter wiget从amap_map_fluttify切换到Amap官方flutter wiget。
2. 实现Amap_SDK的导入。
3. 创建了发行版证书。
4. 申请了AMap_SDK_Key（仅Android）。
5. 修改flutter_demo_app尝试显示地图，web调试与制作发行版apk均未成功。
***

20200411 ElemenTP

1. 小组见面讨论，确定功能函数的功能和数量。
***

20210412 ElemenTP

1. 按照说明将地图widget的下层widget改为Container，成功显示出地图。  
2. 由于暂时只开发Android版，将高德SDK key导入方式从flutter改为Android native。
3. 成功按高德api要求获取了地图审图号。
4. 导入底部导航栏，初步构建了GUI逻辑。
***

20210412 ElemenTP

1. 高德api key的导入或发行版app的密钥有问题，发行版无法显示地图。
***

20210415 ElemenTP

1. 再次讨论算法，详细定义了数据结构，定义了函数的参数和返回值。
2. 团队分工。
***

20210419

1. 尝试重新配置key来解决发行版无法显示地图的bug，未果
2. 借机优化build.gradle配置，更改了amapapikey的导入方式。
***

20210420

1. 将有关发行版app无法显示地图的问题，咨询了高德技术人员，得知flutter构建发行版应用包时默认开启混淆和压缩，我没有配置混淆参数所以导致功能错误。
2. 由于代码开源无需混淆保护，决定取消默认的代码混淆。
3. 引入高德地图定位功能，实现创建地图时中心点为用户位置功能。
4. 引入自动获取定位权限功能。
5. 引入toast功能。
6. 优化了UI界面的代码。
***