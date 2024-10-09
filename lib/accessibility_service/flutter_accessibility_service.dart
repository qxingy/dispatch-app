import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dispatch/accessibility_service/accessibility_event.dart';
import 'package:dispatch/global.dart';
import 'package:flutter/services.dart';

class FlutterAccessibilityService {
  FlutterAccessibilityService._();

  static const MethodChannel _methodChannel =
      MethodChannel('accessibility_channel');
  static const EventChannel _eventChannel = EventChannel('accessibility_event');
  static Stream<AccessibilityNodeInfo>? _stream;

  static Stream<AccessibilityNodeInfo> get accessStream {
    _stream ??=
        _eventChannel.receiveBroadcastStream().map<AccessibilityNodeInfo>(
              (event) => AccessibilityNodeInfo.fromJson(jsonDecode(event)),
            );
    return _stream!;
  }

  static Future<bool> requestAccessibilityPermission() async {
    try {
      return await _methodChannel
          .invokeMethod('requestAccessibilityPermission');
    } on PlatformException catch (error) {
      log("$error");
      return Future.value(false);
    }
  }

  static Future<bool> isAccessibilityPermissionEnabled() async {
    try {
      return await _methodChannel
          .invokeMethod('isAccessibilityPermissionEnabled');
    } on PlatformException catch (error) {
      log("$error");
      return false;
    }
  }

  static Future<AccessibilityNodeInfo?> getCurrNode() async {
    try {
      final result = await _methodChannel.invokeMethod("getCurrNode");

      if (result == null) {
        log("无障碍数据获取为空1");
        return null;
      }

      final data = jsonDecode(result);
      if (data == null) {
        log("无障碍数据获取为空2");
        return null;
      }

      return AccessibilityNodeInfo.fromJson(jsonDecode(result));
    } on PlatformException catch (error) {
      log("$error");
      return null;
    }
  }

  static Future<void> bringAppToForeground(String packageName) async {
    try {
      await _methodChannel
          .invokeMethod("bringAppToForeground", {"packageName": packageName});
    } on PlatformException catch (error) {
      log("$error");
    }
  }

  static Future<bool> performAction({String? id, String? text}) async {
    try {
      return await _methodChannel
          .invokeMethod("performAction", {"id": id, "text": text});
    } on PlatformException catch (error) {
      log("$error");
      return false;
    }
  }
}
