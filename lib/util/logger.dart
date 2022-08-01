import 'dart:io';

import 'package:get_storage/get_storage.dart';

class Logger {
  bool _logEnabled = false;
  late File _logFile;
  late IOSink _logSink;

  Logger(GetStorage prefs, String logfiledir) {
    _logEnabled = prefs.read<bool>('logEnabled') ?? false;
    _logFile = File(logfiledir);
    if (_logEnabled) _logSink = _logFile.openWrite(mode: FileMode.append);
  }

  void setLogState(bool newState, GetStorage prefs) {
    if (newState == _logEnabled) return;
    _logEnabled = newState;
    prefs.write('logEnabled', newState);
    if (newState) {
      _logSink = _logFile.openWrite(mode: FileMode.append);
    } else {
      _logSink.flush();
      _logSink.close();
    }
  }

  bool getLogState() {
    return _logEnabled;
  }

  bool fileExists() {
    return _logFile.existsSync();
  }

  List<String> getLogContentLines() {
    return _logFile.readAsLinesSync();
  }

  String getLogContentString() {
    return _logFile.readAsStringSync();
  }

  void cleanLogFile() {
    if (_logEnabled) {
      _logFile.writeAsBytes(<int>[], flush: true);
    } else {
      _logFile.deleteSync();
    }
  }

  void log(String content) {
    if (_logEnabled) {
      _logSink.writeln('${DateTime.now().toString()}: $content');
    }
  }

  void rawlog(String content) {
    if (_logEnabled) {
      _logSink.writeln(content);
    }
  }
}
