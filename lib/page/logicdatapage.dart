import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:campnavi/global/global.dart';
import 'package:campnavi/model/logicloc.dart';
import 'package:campnavi/controller/maincontroller.dart';

///逻辑位置数据管理界面
class LogicDataPage extends StatelessWidget {
  const LogicDataPage({Key key = const Key('logicdata')}) : super(key: key);

  static MainController c = Get.find();

  static String customLogicLocPath =
      '${applicationDataDir.path}/CustomLogicLoc/';

  static Directory customLogicLocDir = Directory(customLogicLocPath);

  static int prefixLength = customLogicLocPath.length;

  ///导入逻辑位置文件函数调用Android系统的文件选择器选择文件，并对文件中的数据的有效性进行
  ///测试，不可用则提示用户，可用则存储在软件私有存储空间中并设为默认逻辑位置数据，立即应用

  void _setNewLogicLoc() {
    c.searchResult.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (!customLogicLocDir.existsSync()) {
      customLogicLocDir.createSync(recursive: true);
    }
    List<FileSystemEntity> listLogicLocFiles;
    List<Widget> listLogicLocFileChoose;
    return StatefulBuilder(builder: (context, setState) {
      listLogicLocFiles = customLogicLocDir.listSync();
      bool isDefault = prefs.read<String>('logicLocFile') == null;
      listLogicLocFileChoose = [
        Card(
          child: ListTile(
            title: Text('nologicloc'.tr),
            selected: isDefault,
            onTap: isDefault
                ? null
                : () => Get.dialog(
                      AlertDialog(
                        title: Text('tip'.tr),
                        content: Text('asknologicloc'.tr),
                        actions: <Widget>[
                          TextButton(
                            child: Text('cancel'.tr),
                            onPressed: () => Get.back(),
                          ),
                          TextButton(
                            child: Text('ok'.tr),
                            onPressed: () async {
                              Get.back();
                              await prefs.remove('logicLocFile');
                              setState(() {});
                              mapLogicLoc = LogicLoc();
                              _setNewLogicLoc();
                              logger.log('不使用逻辑位置');
                            },
                          ),
                        ],
                      ),
                    ),
          ),
        ),
      ];
      for (FileSystemEntity element in listLogicLocFiles) {
        String fileName = element.path.substring(prefixLength);
        bool isSelected = prefs.read<String>('logicLocFile') == fileName;
        listLogicLocFileChoose.add(Card(
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
                              await prefs.remove('logicLocFile');
                              mapLogicLoc = LogicLoc();
                              _setNewLogicLoc();
                            }
                            await element.delete();
                            setState(() {});
                            logger.log('删除逻辑位置 $fileName');
                          },
                        ),
                        TextButton(
                          child: Text('use'.tr),
                          onPressed: () async {
                            Get.back();
                            prefs.write('logicLocFile', fileName);
                            setState(() {});
                            File logicLocFile =
                                File(customLogicLocPath + fileName);
                            mapLogicLoc = LogicLoc.fromJson(
                                jsonDecode(await logicLocFile.readAsString()));
                            _setNewLogicLoc();
                            logger.log('应用逻辑位置 $fileName');
                          },
                        ),
                      ],
                    )),
          ),
        ));
      }
      return Scaffold(
        appBar: AppBar(
          title: Text('logicloc'.tr),
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
                  children: listLogicLocFileChoose,
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'logicloc',
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
              LogicLoc newData;
              try {
                newData =
                    LogicLoc.fromJson(jsonDecode(await iptFile.readAsString()));
                if (newData.logicLoc.isEmpty) throw '!';
              } catch (_) {
                Get.snackbar('tip'.tr, '逻辑位置数据格式不正确，请检查逻辑位置数据',
                    snackPosition: SnackPosition.BOTTOM);
                return;
              }
              File customLogicLocFile =
                  File(customLogicLocPath + pickedFile.files.single.name);
              if (!await customLogicLocFile.exists()) {
                customLogicLocFile =
                    await customLogicLocFile.create(recursive: true);
              }
              await customLogicLocFile.writeAsString(jsonEncode(newData));
              setState(() {});
              prefs.write('logicLocFile', pickedFile.files.single.name);
              mapLogicLoc = newData;
              _setNewLogicLoc();
              Get.snackbar('tip'.tr, '逻辑位置数据已成功应用',
                  snackPosition: SnackPosition.BOTTOM);
              logger.log('导入并应用新逻辑位置 ${pickedFile.files.single.name}');
            }
          },
          tooltip: '从文件导入',
          child: const Icon(Icons.add),
        ),
      );
    });
  }
}
