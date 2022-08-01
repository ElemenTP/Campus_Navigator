import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:campnavi/global/global.dart';
import 'package:campnavi/model/mapdata.dart';
import 'package:campnavi/controller/maincontroller.dart';

///地图数据管理界面
class MapDataPage extends StatelessWidget {
  const MapDataPage({Key key = const Key('mapdata')}) : super(key: key);

  static MainController c = Get.find();

  static String customMapDataPath = '${applicationDataDir.path}/CustomMapData/';

  static Directory customMapDataDir = Directory(customMapDataPath);

  static int prefixLength = customMapDataPath.length;

  ///导入地图文件函数，调用Android系统的文件选择器选择文件，并对文件中的数据的有效性进行测试，
  ///不可用则提示用户，可用则存储在软件私有存储空间中并设为默认地图数据

  void _setNewMapData() {
    c.naviStatus.value = false;
    c.start.clear();
    c.end.clear();
    c.routeLength.value = 0;
    c.mapMarkers.clear();
    c.mapPolylines.clear();
    c.searchResult.clear();
    c.campusFilter = List<bool>.filled(mapData.mapCampus.length, true).obs;
  }

  @override
  Widget build(BuildContext context) {
    if (!customMapDataDir.existsSync()) {
      customMapDataDir.createSync(recursive: true);
    }
    List<FileSystemEntity> listMapDataFiles;
    List<Widget> listMapDataFileChoose;
    return StatefulBuilder(builder: (context, setState) {
      listMapDataFiles = customMapDataDir.listSync();
      bool isDefault = prefs.read<String>('dataFile') == null;
      listMapDataFileChoose = [
        Card(
          child: ListTile(
            title: Text('defaultmapdata'.tr),
            selected: isDefault,
            onTap: isDefault
                ? null
                : () => Get.dialog(
                      AlertDialog(
                        title: Text('tip'.tr),
                        content: Text('asksettodefault'.tr),
                        actions: <Widget>[
                          TextButton(
                            child: Text('cancel'.tr),
                            onPressed: () => Get.back(),
                          ),
                          TextButton(
                            child: Text('ok'.tr),
                            onPressed: () async {
                              Get.back();
                              await prefs.remove('dataFile');
                              setState(() {});
                              mapData = MapData.fromJson(jsonDecode(
                                  await rootBundle
                                      .loadString('mapdata/default.json')));
                              _setNewMapData();
                              logger.log('应用默认地图数据');
                            },
                          ),
                        ],
                      ),
                    ),
          ),
        )
      ];
      for (FileSystemEntity element in listMapDataFiles) {
        String fileName = element.path.substring(prefixLength);
        bool isSelected = prefs.read<String>('dataFile') == fileName;
        listMapDataFileChoose.add(Card(
          child: ListTile(
            title: Text(fileName),
            selected: isSelected,
            onTap: isSelected
                ? null
                : () => Get.dialog(AlertDialog(
                      title: Text('tip'.tr),
                      content: Text('whattodo'.tr),
                      actions: <Widget>[
                        TextButton(
                          child: Text('cancel'.tr),
                          onPressed: () => Get.back(),
                        ),
                        TextButton(
                          child: Text('delete'.tr),
                          onPressed: () async {
                            Get.back();
                            if (isSelected) {
                              await prefs.remove('dataFile');
                              mapData = MapData.fromJson(jsonDecode(
                                  await rootBundle
                                      .loadString('mapdata/default.json')));
                              _setNewMapData();
                            }
                            await element.delete();
                            setState(() {});
                            logger.log('删除地图数据');
                          },
                        ),
                        TextButton(
                          child: Text('use'.tr),
                          onPressed: () async {
                            Get.back();
                            prefs.write('dataFile', fileName);
                            setState(() {});
                            File mapDataFile =
                                File(customMapDataPath + fileName);
                            mapData = MapData.fromJson(
                                jsonDecode(await mapDataFile.readAsString()));
                            _setNewMapData();
                            logger.log('应用地图数据 $fileName');
                          },
                        ),
                      ],
                    )),
          ),
        ));
      }
      return Scaffold(
        appBar: AppBar(
          title: Text('mapdata'.tr),
        ),
        body: Column(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: listMapDataFileChoose,
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'mapdata',
          onPressed: () async {
            FilePickerResult? pickedFile;
            try {
              pickedFile = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowMultiple: false,
                  allowedExtensions: ['json']);
            } catch (_) {
              Get.snackbar('tip'.tr, '导入文件功能需要存储权限',
                  snackPosition: SnackPosition.BOTTOM);
            }
            if (pickedFile != null) {
              File iptFile = File(pickedFile.paths.first!);
              MapData newData;
              try {
                newData =
                    MapData.fromJson(jsonDecode(await iptFile.readAsString()));
                if (newData.mapCampus.isEmpty) throw '!';
              } catch (_) {
                Get.snackbar('tip'.tr, '地图数据格式不正确，请检查地图数据',
                    snackPosition: SnackPosition.BOTTOM);
                return;
              }
              File customMapDataFile =
                  File(customMapDataPath + pickedFile.files.single.name);
              if (!await customMapDataFile.exists()) {
                customMapDataFile =
                    await customMapDataFile.create(recursive: true);
              }
              await customMapDataFile.writeAsString(jsonEncode(newData));
              setState(() {});
              prefs.write('dataFile', pickedFile.files.single.name);
              mapData = newData;
              _setNewMapData();
              Get.snackbar('tip'.tr, '地图数据已成功应用',
                  snackPosition: SnackPosition.BOTTOM);
              logger.log('导入并应用新地图数据 ${pickedFile.files.single.name}');
            }
          },
          tooltip: '从文件导入',
          child: const Icon(Icons.add),
        ),
      );
    });
  }
}
