import 'package:dispatch/global.dart';
import 'package:dispatch/repo.dart';
import 'package:dispatch/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';

class UserPageCtr extends GetxController {
  final _localRepo = Get.find<LocalRepo>();
  final _global = Get.find<GlobalService>();
  final _apiService = Get.find<ApiProvider>();
  final _formKey = GlobalKey<FormState>();

  final cdKey = "".obs;
  final account = "".obs;
  final isTest = false.obs;
  final notifyPlugin = Get.find<FlutterLocalNotificationsPlugin>();

  @override
  void onInit() async {
    super.onInit();
    account.value = await _localRepo.getAccount();
    cdKey.value = await _localRepo.getCdKey();
  }

  void cdkActivation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await _apiService.cdkActivation(account.value, cdKey.value);
    Get.snackbar("提示", "激活成功");
    cdKey.value = "";
  }
}

class UserPage extends StatelessWidget {
  UserPage({super.key});

  final c = Get.put(UserPageCtr());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 200,
            color: Colors.grey,
          ),
          SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "用户名: ${c._global.userInfo.value?.username ?? ""}",
                style: TextStyle(fontSize: 15),
              ),
              Text(
                "手机号: ${c._global.userInfo.value?.phone ?? ""}",
                style: TextStyle(fontSize: 15),
              ),
              Text(
                "在线数量: ${c._global.userInfo.value?.onlineNum ?? ""}",
                style: TextStyle(fontSize: 15),
              ),
              TimeDifferenceDisplay(
                  expiryTimestamp:
                      c._global.userInfo.value?.expirationTime ?? 0)
            ],
          ),
          SizedBox(height: 50),
          Container(
            width: 300,
            child: Form(
              key: c._formKey,
              child: TextFormField(
                validator: FormBuilderValidators.compose(
                    [FormBuilderValidators.required(errorText: "请输入激活码")]),
                onChanged: (v) => c.cdKey.value = v,
                decoration: InputDecoration(
                    labelText: "请输入激活码", fillColor: Colors.white),
              ),
            ),
          ),
          SizedBox(height: 5),
          Container(
            width: 300,
            height: 50,
            child: TextButton(
              onPressed: c.cdkActivation,
              child: Text("确认激活"),
            ),
          ),
        ],
      );
    });
  }
}

class TimeDifferenceDisplay extends StatelessWidget {
  final int expiryTimestamp;

  TimeDifferenceDisplay({required this.expiryTimestamp});

  String getTimeDifference() {
    final currentTime = DateTime.now();
    final expiryTime =
        DateTime.fromMillisecondsSinceEpoch(expiryTimestamp * 1000);
    final difference = expiryTime.difference(currentTime);

    print(currentTime);
    print(expiryTimestamp);
    if (difference.isNegative) {
      return '已过期';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    // final seconds = difference.inSeconds % 60;

    return '$days 天 $hours 小时 $minutes 分钟';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '剩余时间: ${getTimeDifference()}',
      style: TextStyle(fontSize: 15),
    );
  }
}
