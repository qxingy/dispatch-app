import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dispatch/pages/login.dart';
import 'package:dispatch/repo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_accessibility_service/accessibility_event.dart';
import 'package:flutter_accessibility_service/accessibility_event.dart';
import 'package:flutter_accessibility_service/constants.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:get/get.dart';
import 'package:json_path/fun_sdk.dart';
import 'package:logger/logger.dart';
import 'package:json_path/json_path.dart';

var logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    // Number of method calls to be displayed
    errorMethodCount: 8,
    // Number of method calls if stacktrace is provided
    lineLength: 120,
    // Width of the output
    colors: true,
    // Colorful log messages
    printEmojis: true,
    // Print an emoji for each log message
    // Should each log print contain a timestamp
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

final comNotifiDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    "弹窗id",
    "测试弹窗",
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  ),
);

String generateMd5(String input) {
  var bytes = utf8.encode(input); // 将字符串编码为 UTF-8 字节
  var digest = md5.convert(bytes); // 计算 MD5 哈希
  return digest.toString(); // 返回哈希值的字符串表示
}

class AuthPageMiddleware extends GetMiddleware {
  final localRepo = Get.find<LocalRepo>();

  @override
  RouteSettings? redirect(String? route) {
    localRepo.getToken().then((token) async {
      if (token == null) {
        return LoginPage();
      }
      return null;
    });
    return null;
  }
}

Future<void> requestAccessibilityPermission() async {
  if (!await FlutterAccessibilityService.isAccessibilityPermissionEnabled()) {
    await FlutterAccessibilityService.requestAccessibilityPermission();
  }

  if (!await FlutterOverlayWindow.isPermissionGranted()) {
    await FlutterOverlayWindow.requestPermission();
  }

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.initialize(InitializationSettings(
    android: AndroidInitializationSettings('log'),
  ));

  Get.put(flutterLocalNotificationsPlugin);
}

//递归查找特定子组件是否存在
bool findChild(String id, AccessibilityEvent event) {
  if (event.nodeId == id) {
    return true;
  }

  if (event.subNodes != null) {
    for (var child in event.subNodes!) {
      if (findChild(id, child)) {
        return true;
      }
    }
  }
  return false;
}

extension NodeActionPlugin on ScreenBounds {
  Map<String, dynamic> toJson() {
    return {
      "right": right,
      "top": top,
      "left": left,
      "bottom": bottom,
      "width": width,
      "height": height,
    };
  }
}

extension AccessibilityEventPlugin on AccessibilityEvent {
  Map<String, dynamic> toJson() {
    return {
      "mapId": mapId,
      "nodeId": nodeId,
      "actionType": actionType?.toString(),
      "eventTime": eventTime?.toString(),
      "packageName": packageName,
      "eventType": eventType?.toString(),
      "text": text,
      "contentChangeTypes": contentChangeTypes?.toString(),
      "movementGranularity": movementGranularity,
      "windowType": windowType?.toString(),
      "isActive": isActive,
      "isFocused": isFocused,
      "isClickable": isClickable,
      "isScrollable": isScrollable,
      "isFocusable": isFocusable,
      "isCheckable": isCheckable,
      "isLongClickable": isLongClickable,
      "isEditable": isEditable,
      "isPip": isPip,
      "screenBounds": screenBounds?.toJson(),
      "actions": actions?.map((action) => action.toString()).toList(),
      "subNodes": subNodes?.map((node) => node.toJson()).toList(),
    };
  }
}
