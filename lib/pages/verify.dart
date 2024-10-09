import 'package:dispatch/global.dart';
import 'package:dispatch/pages/homeAdmin.dart';
import 'package:dispatch/pages/homeNormal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class HomePageCtr extends GetxController {
  final global = Get.find<GlobalService>();
}

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final ctr = Get.put(HomePageCtr());

  @override
  Widget build(BuildContext context) {
    return Obx(
          () {
        if (ctr.global.userInfo.value?.roleId == 2 ?? true) {
          return HomeNormalPage();
        } else {
          return HomeAdminPage();
        }
      },
    );
  }
}

