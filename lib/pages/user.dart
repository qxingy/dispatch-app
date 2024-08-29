import 'package:dispatch/repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class UserPageCtr extends GetxController {
  final _localRepo = Get.find<LocalRepo>();

  final isTest = false.obs;
  final _flutterLocalNotificationsPlugin =
      Get.find<FlutterLocalNotificationsPlugin>();

  void logout(BuildContext context) async {
    await _localRepo.removeToken();
    Get.snackbar("", "退出登录成功");
    Navigator.pushNamedAndRemoveUntil(context, "/login", (r) => false);
  }
}

class UserPage extends StatelessWidget {
  UserPage({super.key});

  final c = Get.put(UserPageCtr());

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          //退出登录
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
            onPressed: () {
              c.isTest.value = !c.isTest.value;
            },
            child: (c.isTest.value ? Text("网络正常") : Text("接单成功")),
          ),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.red),
            ),
            onPressed: () async {
              c._flutterLocalNotificationsPlugin.show(
                0,
                "测试",
                "这是一个测试弹窗",
                NotificationDetails(
                  android: AndroidNotificationDetails(
                    "弹窗id",
                    "测试弹窗",
                    importance: Importance.max,
                    priority: Priority.high,
                    showWhen: false,
                  ),
                ),
              );
            },
            child: Text("测试弹窗"),
          ),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.red),
            ),
            onPressed: () => c.logout(context),
            child: Text("退出登录"),
          )
        ],
      ),
    );
  }
}
