import 'package:dispatch/app_manager.dart';
import 'package:dispatch/global.dart';
import 'package:dispatch/pages/Activity.dart';
import 'package:dispatch/pages/report.dart';
import 'package:dispatch/pages/assistant.dart';
import 'package:dispatch/pages/user.dart';
import 'package:dispatch/repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:get/get.dart';

import '../constans.dart';

final routes = [
  {
    "label": "助手",
    "icon": Icons.assistant,
    "page": AssistantPage(),
  },
  {
    "label": "公告",
    "icon": Icons.local_activity,
    "page": WebViewPage(),
  },
  {
    "label": "我的",
    "icon": Icons.account_box_outlined,
    "page": UserPage(),
  },
];

class HomeNormalPageCtr extends GetxController {
  final _pageController = Get.put(PageController());
  final _currentIndex = 0.obs;

  final globalCtr = Get.find<GlobalService>();
  final appManager = Get.find<AppManager>();
  final localRepo = Get.find<LocalRepo>();

  final items = routes
      .map(
        (e) => BottomNavigationBarItem(
            label: e["label"] as String,
            icon: Icon(e["icon"] as IconData) as Widget),
      )
      .toList();
  final widgets = routes.map((e) => e["page"] as Widget).toList();

  @override
  void onInit() async {
    super.onInit();
    await globalCtr.syncUserInfo();
  }

  void logout(BuildContext context) async {
    await localRepo.removeToken();
    appManager.toast("退出登录成功");
    Get.offAllNamed("/login");
  }

  Widget? buildFloatingButton(BuildContext context) {
    switch (_currentIndex.value) {
      case 0:
        if (globalCtr.isOpenAssistant.value) {
          return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).secondaryHeaderColor),
                  onPressed: () {
                    globalCtr.handlerCloseAssistant();
                  },
                  child: Text("关闭助手"),
                ),
              ]);
        } else {
          return ElevatedButton(
            onPressed: () {
              globalCtr.handlerOpenAssistant();
            },
            child: Text("开启助手"),
          );
        }
      case 2:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.red),
              ),
              onPressed: () => logout(context),
              child: Text("退出登录"),
            ),
            ElevatedButton(
              onPressed: () => globalCtr.syncUserInfo(),
              child: Text("同步信息"),
            ),
          ],
        );
    }
    return null;
  }
}

class HomeNormalPage extends StatelessWidget {
  HomeNormalPage({super.key});

  final ctr = Get.put(HomeNormalPageCtr());

  @override
  Widget build(BuildContext context) => Obx(
        () => Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: Text(appName),
            ),
            resizeToAvoidBottomInset: false,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: ctr.buildFloatingButton(context),
            bottomNavigationBar: BottomNavigationBar(
              items: ctr.items,
              type: BottomNavigationBarType.fixed,
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
