import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:android_intent_plus/android_intent.dart';
import 'package:dispatch/constans.dart';
import 'package:dispatch/repo.dart';
import 'package:dispatch/utils.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_overlay_window2/flutter_overlay_window2.dart';
import 'package:get/get.dart';
import 'accessibility_service/accessibility_event.dart';
import 'accessibility_service/flutter_accessibility_service.dart';
import 'app_manager.dart';
import 'dao.dart';
import "package:root_access/root_access.dart";

class GlobalService extends GetxService {
  final isOpenAssistant = false.obs;
  final isOpenReport = false.obs;

  final deviceId = Rxn<String?>(null);

  final reportData = <AccessibilityNodeInfo>[].obs;
  Timer? timer;

  GetSocket? socket;

  final isRoot = false.obs;

  final appDao = Get.find<AppDao>();
  final localRepo = Get.find<LocalRepo>();
  final appManager = Get.find<AppManager>();
  final appService = Get.find<ApiProvider>();
  final notifyPlugin = Get.find<FlutterLocalNotificationsPlugin>();

  final userInfo = Rxn<UserInfo?>(null);

  StreamSubscription<AccessibilityNodeInfo>? subHandler;
  StreamSubscription<dynamic>? overlayHandler;
  final stream = FlutterOverlayWindow2.overlayListener.asBroadcastStream();

  @override
  void onInit() async {
    super.onInit();

    isRoot.value = await RootAccess.requestRootAccess;
    logger.d("Root permission: $isRoot");

    deviceId.value = await appManager.getDeviceId();

    syncUserInfo();
    //每5分钟执行一次
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      await syncUserInfo();
    });
  }

  Future<void> syncUserInfo() async {
    userInfo.value = await appService.userInfo();
  }

  Future<void> loadApp() async {
    final remoteApps = await appService.getAppName();
    final localApps = await appDao.syncFindAll();
    final installApps = await appManager.getInstalledApps();

    if (remoteApps == null) {
      return;
    }

    await appDao.deleteAllApp();
    final apps = <AppEntity>[];
    for (var remoteApp in remoteApps) {
      final installApp = installApps
          .firstWhereOrNull((e) => e["package_name"] == remoteApp.packageName);

      if (installApp == null) {
        continue;
      }
      final localApp = localApps
          .firstWhereOrNull((e) => e.packageName == remoteApp.packageName);
      bool isCut;
      if (isRoot.value) {
        isCut = await appManager.isAppInternetCut(installApp["uid"]);
      } else {
        isCut = false;
      }

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
    FlutterOverlayWindow2.showOverlay(
      enableDrag: true,
      height: 150,
      width: 350,
      overlayTitle: "数据上报中",
      startPosition: OverlayPosition2(100, -200),
    );

    reportData.clear();
    if (isOpenAssistant.value) {
      appManager.toast("请先关闭助手");
      return;
    }

    appManager.toast("每10s上报一次");

    timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      final nodeInfo = await FlutterAccessibilityService.getCurrNode();
      if (nodeInfo == null) {
        appManager.toast("未检测到任何应用");
        return;
      }

      appManager.toast("上报当前页面:${nodeInfo.appName}");
      logger.d("开始上报页面组件信息");
      reportData.add(nodeInfo);
      await appService.addNode(nodeInfo);
    });

    subHandler =
        FlutterAccessibilityService.accessStream.listen((event) async {});

    overlayHandler = stream.listen((data) {
      handlerCloseReport();
    });

    isOpenReport.value = true;
  }

  void handlerCloseReport() async {
    FlutterOverlayWindow2.closeOverlay();

    final nodeInfo = await FlutterAccessibilityService.getCurrNode();
    if (nodeInfo != null) {
      appManager.toast("上报当前页面:${nodeInfo.appName}");
      logger.d("开始上报页面组件信息");
      reportData.add(nodeInfo);
      await appService.addNode(nodeInfo);
    }

    timer?.cancel();

    subHandler?.cancel();
    overlayHandler?.cancel();

    isOpenReport.value = false;
  }

  void handlerOpenAssistant() async {
    if (userInfo.value?.isExpire() ?? true) {
      appManager.toast("请先激活");
      return;
    }
    if (isOpenReport.value) {
      appManager.toast("请先停止上报");
      return;
    }

    final apps = await appDao.findAllEnable();
    if (apps.isEmpty) {
      appManager.toast("请先选择App");
      return;
    }

    //先开启关闭的app的网络
    for (var app in apps) {
      if (app.isCut) {
        await enableAppNetwork(app);
      }
    }

    FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      height: 200,
      width: 250,
      overlayTitle: "助手开启中",
      startPosition: OverlayPosition(100, -200),
    );

    socket = await appService.connect();
    socket!.onError((err) async {
      notifyPlugin.show(0, "错误", "网络异常,助手关闭", comNotifiDetails);

      await handlerCloseAssistant();
    });
    socket!.onClose((data) async {
      logger.d("websocket close: $data");
      await handlerCloseAssistant();
    });

    socket?.onMessage((data) async {
      logger.d("收到消息: $data");

      switch (data) {
        case "3":
          {
            notifyPlugin.show(0, "提示", "接单成功", comNotifiDetails);
              await handlerCloseAssistant();
              await closeAllApp(apps, null);
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

      try {
        final match = await appManager.match(jsonData, app.getNode);
        if (!match) {
          logger.d("事件匹配失败");
          return;
        }
        logger.d("app: ${app.name} 触发了节点: ${app.getNode}");
        final uris = await appService.getUserIpList();

        final token = await localRepo.getToken();
        for (final uri in uris) {
          if (uri == token) {
            continue;
          }
          socket!.send(jsonEncode({"from": token, "message": "3", "to": uri}));
        }
        notifyPlugin.show(0, "提示", "接单成功", comNotifiDetails);
          await handlerCloseAssistant();
          await closeAllApp(apps.where((a) => a.uid != app.uid).toList(), app);
      } catch (e) {
        logger.e("事件匹配异常, $e");
      } finally {}
    });

    logger.d("打开助手");
    isOpenAssistant.value = true;
  }

  Future<void> handlerCloseAssistant() async {
    FlutterOverlayWindow.closeOverlay();
    subHandler?.cancel();
    socket?.close();
    socket = null;
    logger.d("关闭助手");
    isOpenAssistant.value = false;
  }

  Future<void> closeAppNetwork(AppEntity app) async {
    if (isRoot.value) {
      await appManager.cutAppInternet(app.uid);
      return appDao.updateIsCut(app.id!, true);
    } else {
      appManager.toast("该功能需要root权限");
    }
  }

  Future<void> enableAppNetwork(AppEntity app) async {
    if (isRoot.value) {
      await appManager.restoreAppInternet(app.uid);
      return appDao.updateIsCut(app.id!, false);
    } else {
      appManager.toast("该功能需要root权限");
    }
  }

  Future<void> closeAllApp(List<AppEntity> apps, AppEntity? localApp) async {
    if (isRoot.value) {
      await Future.forEach(apps, (app) async {
        await closeAppNetwork(app);
      });
    } else {
      for (var app in apps) {
        appManager.toast("正在停止APP: ${app.name}");
        logger.d("正在停止APP: ${app.name}");
        FlutterAccessibilityService.bringAppToForeground(app.packageName);

        final List<dynamic> actions = jsonDecode(app.waitingNode);
        await Future.delayed(Duration(milliseconds: 500));

        app:
        for (final action in actions) {
          final name = action["name"];
          final type = action["type"];
          final value = action["value"];
          logger.d("开始执行第一步: name: $name, type: $type, value: $value");
          action:
          try {
            for (var i = 0;; i++) {
              try {
                logger.d("点击开始");
                if (type == "id") {
                  if (await FlutterAccessibilityService.performAction(
                      id: value)) {
                    logger.d("点击结束");
                    break action;
                  }
                } else {
                  if (await FlutterAccessibilityService.performAction(
                      text: value)) {
                    logger.d("点击结束");
                    break action;
                  }
                }
              } on Exception catch (error) {
                logger.d("点击错误,err: ${error.toString()}");
              }

              appManager.toast("APP停止失败,请切换到接单页面: ${app.name}");

              if (i == 3) {
                appManager.toast("APP停止失败: ${app.name}");
                break app;
              }

              await Future.delayed(Duration(seconds: 3));
            }
          } finally {
            await Future.delayed(Duration(milliseconds: 500));
          }
        }
      }
    }

    appManager.toast("所有APP停止完成,跳回接单APP");

    if (localApp != null) {
      FlutterAccessibilityService.bringAppToForeground(localApp.packageName);
    } else {
      FlutterAccessibilityService.bringAppToForeground(packageName);
    }
  }
}
