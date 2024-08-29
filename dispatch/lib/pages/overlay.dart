import 'package:android_intent_plus/android_intent.dart';
import 'package:dispatch/app_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:get/get.dart';

class OverlayCtr extends GetxController {
  final title = "关闭助手".obs;
}

class OverlayPage extends StatelessWidget {
  OverlayPage({super.key});

  final c = Get.put(OverlayCtr());

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).secondaryHeaderColor),
          onPressed: () {
            AndroidIntent(
                    action: "action_view", data: "dispatch://example.com")
                .launch();
          },
          child: Text(c.title.value),
        );
      },
    );
  }
}
