import 'dart:async';
import 'dart:convert';

import 'package:dispatch/repo.dart';
import 'package:dispatch/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_accessibility_service/accessibility_event.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:get/get.dart';
import 'package:root_access/root_access.dart';
import 'app_manager.dart';
import 'dao.dart';

class GlobalService extends GetxService {
  final isOpenAssistant = false.obs;
  final isOpenReport = false.obs;

  final reportData = <AccessibilityEvent>[].obs;
  AccessibilityEvent? tmpData;

  Timer? timer;

  GetSocket? socket;
  int? onTickAppUid;

  final isRoot = false.obs;

  final appDao = Get.find<AppDao>();
  final localRepo = Get.find<LocalRepo>();
  final appManager = Get.find<AppManager>();
  final appService = Get.find<ApiProvider>();
  final notifyPlugin = Get.find<FlutterLocalNotificationsPlugin>();

  StreamSubscription<AccessibilityEvent>? subHandler;

  @override
  void onInit() async {
    super.onInit();
    isRoot.value = await RootAccess.requestRootAccess;
  }

  Future<void> loadApp() async {
    final localApps = await appDao.syncFindAll();
    final remoteApps = await appService.getAppName();
    final installApps = await appManager.getInstalledApps();

    if (remoteApps == null) {
      return;
    }

    final apps = <AppEntity>[];
    for (var remoteApp in remoteApps) {
      final installApp = installApps
          .firstWhereOrNull((e) => e["package_name"] == remoteApp.packageName);

      if (installApp == null) {
        continue;
      }
      final localApp = localApps
          .firstWhereOrNull((e) => e.packageName == remoteApp.packageName);
      final isCut = await appManager.isAppInternetCut(installApp["uid"]);

      apps.add(AppEntity(
        uid: installApp["uid"],
        name: installApp["name"],
        packageName: installApp["package_name"],
        versionName: installApp["version_name"],
        versionCode: installApp["version_code"],
        promotionLink: remoteApp.promotionLink,
        icon: installApp["icon"],
        isCut: isCut,
        enable: localApp?.enable ?? false,
        waitingPageNode: remoteApp.node,
        waitingNode: remoteApp.node1,
        getNode: remoteApp.node2,
        descNode: remoteApp.node3,
      ));
    }
    logger.d("Insert apps: ${apps.map((app) => app.packageName).join(", ")}");
    await appDao.insertPerson(apps);
  }

  void loadInstalledApps() async {}

  void handlerOpenReport() async {
    if (isOpenAssistant.value) {
      Get.dialog(Text("请先关闭助手"));
      return;
    }

    Get.snackbar("提示", "每10s上报一次");

    timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (tmpData == null) {
        return;
      }
      await appService.addNode(tmpData!.toJson());
      notifyPlugin.show(0, "提示", "开始上报", comNotifiDetails);
      reportData.add(tmpData!);

      logger.d("开始上报");
    });

    subHandler = FlutterAccessibilityService.accessStream.listen((event) async {
      tmpData = event;
    });

    isOpenReport.value = true;
  }

  void handlerCloseReport() async {
    timer?.cancel();
    subHandler?.cancel();
    tmpData = null;
    isOpenReport.value = false;
  }

  void handlerOpenAssistant() async {
    if (isOpenReport.value) {
      Get.dialog(Text("请先停止上报!"));
      return;
    }

    final apps = await appDao.findAllEnable();

    socket = await appService.connect();
    socket?.onMessage((data) async {
      switch (data) {
        case "jiedan":
          {
            await closeAllAppNetwork(
                apps.where((app) => app.uid != onTickAppUid).toList());
            await handlerCloseAssistant();
            notifyPlugin.show(0, "提示", "接单成功", comNotifiDetails);
          }
      }
    });

    subHandler = FlutterAccessibilityService.accessStream.listen((event) async {
      final app =
          apps.firstWhereOrNull((app) => app.packageName == event.packageName);
      if (app == null) {
        return;
      }

      final jsonData = jsonEncode(event.toJson());
      if (app.getNode.isEmpty) {
        return;
      }

      final match = await appManager.match(jsonData, app.getNode);
      if (!match) {
        return;
      }
      logger.d("app: ${app.name} 触发了节点: ${app.getNode}");
      onTickAppUid = app.uid;
      socket?.send("jiedan");
    });

    logger.d("打开助手");
    isOpenAssistant.value = true;
  }

  Future<void> closeAppNetwork(AppEntity app) async {
    await appManager.cutAppInternet(app.uid);
    return appDao.updateIsCut(app.id!, true);
  }

  Future<void> enableAppNetwork(AppEntity app) async {
    await appManager.restoreAppInternet(app.uid);
    return appDao.updateIsCut(app.id!, false);
  }

  Future<void> handlerCloseAssistant() async {
    subHandler?.cancel();
    FlutterOverlayWindow.closeOverlay();
    logger.d("关闭助手");
    isOpenAssistant.value = false;
  }

  Future<void> closeAllAppNetwork(List<AppEntity> apps) async {
    await Future.forEach(apps, (app) async {
      appManager.cutAppInternet(app.uid);
      appDao.updateIsCut(app.id!, true);
    });
  }
}
