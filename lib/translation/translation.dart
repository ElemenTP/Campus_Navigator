import 'package:get/get.dart';
import 'package:flutter/material.dart';

const List<Locale> supporedLocales = <Locale>[
  Locale('en'),
  Locale('zh'),
];

const Map<String, String> languagecode2Str = <String, String>{
  'en': 'English',
  'zh': '中文'
};

class Translation extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en': {
          'title': 'Campus Navigator',
          'search': 'Search',
          'setting': 'Setting',
          'ok': 'OK',
          'cancel': 'Cancel',
          'back': 'Go back',
          'tip': 'Tip',
          'theme': 'Theme',
          'language': 'Language',
          'themefollowsystem': 'Theme follow system',
          'usedarktheme': 'Use dark theme',
          'start': 'Start',
          'stop': 'Stop',
        },
        'zh': {
          'title': '校园导航',
          'search': '搜索',
          'setting': '设置',
          'ok': '确定',
          'cancel': '取消',
          'back': '返回',
          'tip': '提示',
          'theme': '主题',
          'language': '语言',
          'themefollowsystem': '主题跟随系统',
          'usedarktheme': '使用暗色主题',
          'start': '开始',
          'stop': '停止',
        }
      };
}
