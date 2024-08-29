import 'package:dispatch/dao.dart';
import 'package:flutter/services.dart';

class AppManager {
  static const MethodChannel _channel = MethodChannel('app_manager');

  Future<List<dynamic>> getInstalledApps() async {
    return await _channel.invokeMethod("getInstalledApps") as List<dynamic>;
  }

  Future<void> cutAppInternet(int uid) async {
    return await _channel.invokeMethod("cutAppInternet", {"uid": uid});
  }

  Future<void> restoreAppInternet(int uid) async {
    return await _channel.invokeMethod("restoreAppInternet", {"uid": uid});
  }

  Future<bool> isAppInternetCut(int uid) async {
    return await _channel.invokeMethod("isAppInternetCut", {"uid": uid});
  }

  Future<bool> match(String json, String data) async {
    return await _channel.invokeMethod("match", {"json": json, "data": data});
  }

  Future<bool> bringToForeground() async {
    return await _channel.invokeMethod("getInstalledApps");
  }
}
