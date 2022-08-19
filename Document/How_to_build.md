# 构建说明
1. 生成apk签名，并用该签名注册高德地图Android接口服务。
2. 在android目录下新建文件key.properties，内容如下
```
storePassword={签名文件密码}
keyPassword={签名密码}
keyAlias=key
storeFile={签名文件目录，绝对路径}
```
3. 在lib/apikey文件夹中新建amapapikey.dart文件，内容如下
```dart
import 'package:amap_flutter_base/amap_flutter_base.dart';

const AMapApiKey amapApiKeys =
    AMapApiKey(androidKey: '高德地图接口密钥');
```
4. 在项目目录中运行flutter pub get
5. 运行flutter build apk，编译Android apk。
