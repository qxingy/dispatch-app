import 'package:dispatch/app_manager.dart';
import 'package:dispatch/global.dart';
import 'package:dispatch/pages/report.dart';
import 'package:dispatch/pages/assistant.dart';
import 'package:dispatch/pages/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:get/get.dart';

final routes = [
  {
    "label": "助手",
    "icon": Icons.assistant,
    "page": AssistantPage(),
  },
  {
    "label": "上报",
    "icon": Icons.upload_file_outlined,
    "page": ReportPage(),
  },
  {
    "label": "我的",
    "icon": Icons.account_box_outlined,
    "page": UserPage(),
  },
];

class HomePageCtr extends FullLifeCycleController with FullLifeCycleMixin {
  final _pageController = Get.put(PageController());
  final _currentIndex = 0.obs;

  final globalCtr = Get.find<GlobalService>();
  final appManager = Get.find<AppManager>();

  final items = routes
      .map(
        (e) => BottomNavigationBarItem(
            label: e["label"] as String,
            icon: Icon(e["icon"] as IconData) as Widget),
      )
      .toList();
  final widgets = routes.map((e) => e["page"] as Widget).toList();

  Widget? buildFloatingButton(BuildContext context) {
    switch (_currentIndex.value) {
      case 0:
        if (globalCtr.isOpenAssistant.value) {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).secondaryHeaderColor),
            onPressed: () {
              globalCtr.handlerCloseAssistant();
            },
            child: Text("关闭助手"),
          );
        } else {
          return ElevatedButton(
            onPressed: () {
              globalCtr.handlerOpenAssistant();
            },
            child: Text("开启助手"),
          );
        }
      case 1:
        if (!globalCtr.isOpenReport.value) {
          return ElevatedButton(
            onPressed: () {
              globalCtr.handlerOpenReport();
            },
            child: Text("开始上报"),
          );
        } else {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).secondaryHeaderColor),
            onPressed: () {
              globalCtr.handlerCloseReport();
            },
            child: Text("停止上报"),
          );
        }
    }
    return null;
  }

  @override
  void onDetached() {}

  @override
  void onHidden() {}

  @override
  void onInactive() {}

  @override
  void onPaused() {}

  @override
  void onResumed() {}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        FlutterOverlayWindow.closeOverlay();
      case AppLifecycleState.paused:
        FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          height: 200,
          width: 200,
          startPosition: OverlayPosition(180, 100),
        );
        FlutterOverlayWindow.overlayListener.listen((data) {
          print(data);
          print("====================");
          appManager.bringToForeground();
        });
      default:
        return;
    }
  }
}

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final ctr = Get.put(HomePageCtr());

  @override
  Widget build(BuildContext context) => Obx(
        () => Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: Text("车调度"),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: ctr.buildFloatingButton(context),
            bottomNavigationBar: BottomNavigationBar(
              items: ctr.items,
              currentIndex: ctr._currentIndex.value,
              // enableFeedback: ,
              onTap: (value) {
                ctr._pageController.jumpToPage(value);
                ctr._currentIndex.value = value;
              },
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: PageView(
                controller: ctr._pageController,
                onPageChanged: (i) => ctr._currentIndex.value = i,
                children: ctr.widgets,
              ),
            )),
      );
}
