import 'package:campnavi/global/global.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:campnavi/controller/logpagecontroller.dart';

///日志内容展示界面，从文件中按行读出日志并放在列表中
class LogPage extends StatelessWidget {
  const LogPage({Key key = const Key('setting')}) : super(key: key);

  static List<String> noMore = <String>['nomore'.tr];

  static LogPageController c =
      Get.put<LogPageController>(LogPageController(), permanent: true);

  void _fillSearchReuslt() {
    c.searchResult.addAll(c.listLogString + noMore);
  }

  void _onStartSearch() {
    c.textFocusNode.unfocus();
    c.searchResult.clear();
    String toSearch = c.textController.text;
    if (toSearch == '') {
      _fillSearchReuslt();
      return;
    }
    for (String curString in c.listLogString) {
      if (curString.contains(toSearch)) {
        c.searchResult.add(curString);
      }
    }
    c.searchResult.add(noMore.first);
  }

  @override
  Widget build(BuildContext context) {
    c.listLogString = logFile.readAsLinesSync();
    c.searchResult.clear();
    _fillSearchReuslt();

    const SizedBox sizedBox = SizedBox(
      width: 16,
      height: 16,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('log'.tr),
      ),
      body: Column(
        children: [
          sizedBox,
          Row(
            children: <Widget>[
              sizedBox,
              Expanded(
                child: TextField(
                  controller: c.textController,
                  focusNode: c.textFocusNode,
                  decoration: InputDecoration(
                    labelText: 'searchkeyword'.tr,
                    hintText: 'inputkeyword'.tr,
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20.0))),
                  ),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.search,
                  onEditingComplete: _onStartSearch,
                ),
              ),
              sizedBox,
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // TextButton.icon(
              //   icon: const Icon(Icons.filter_alt),
              //   label: Text('campus'.tr),
              //   onPressed: _campusFilter,
              // ),
              TextButton.icon(
                icon: const Icon(Icons.search),
                label: Text('search'.tr),
                onPressed: _onStartSearch,
              ),
              TextButton.icon(
                  icon: const Icon(Icons.delete),
                  label: Text('reset'.tr),
                  onPressed: () {
                    c.textController.clear();
                    c.textFocusNode.unfocus();
                    c.searchResult.clear();
                    _fillSearchReuslt();
                  }),
            ],
          ),
          Expanded(
            child: Obx(
              () => ListView.builder(
                itemCount: c.searchResult.length,
                itemBuilder: (context, index) => Card(
                  child: ListTile(
                    title: Text(c.searchResult[index]),
                  ),
                ),
                controller: c.scrollController,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: UniqueKey(),
            onPressed: () => c.scrollController.animateTo(
              0.0,
              duration: const Duration(seconds: 1),
              curve: Curves.ease,
            ),
            tooltip: 'upward'.tr,
            child: const Icon(Icons.arrow_upward),
          ),
          const SizedBox(
            width: 8,
            height: 8,
          ),
          FloatingActionButton(
            heroTag: UniqueKey(),
            onPressed: () {
              c.listLogString = logFile.readAsLinesSync();
              c.searchResult.clear();
              _onStartSearch();
            },
            tooltip: 'refresh'.tr,
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
