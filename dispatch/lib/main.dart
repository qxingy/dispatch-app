import 'package:dispatch/app_manager.dart';
import 'package:dispatch/global.dart';
import 'package:dispatch/pages/home.dart';
import 'package:dispatch/pages/login.dart';
import 'package:dispatch/pages/overlay.dart';
import 'package:dispatch/repo.dart';
import 'package:dispatch/utils.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:get/get.dart';

import 'dao.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestAccessibilityPermission();

  final database =
      await $FloorAppDatabase.databaseBuilder("app_database.db").build();

  final localRepo = LocalRepo();
  final appManager = AppManager();
  Get.put(database.appDao);
  Get.put(localRepo);
  Get.put(appManager);
  Get.put(ApiProvider());
  Get.put(GlobalService());

  final isLogin = await localRepo.getToken() != null;

  return runApp(
    GetMaterialApp(
      theme: FlexThemeData.light(scheme: FlexScheme.deepBlue),
      initialRoute: isLogin ? "/home" : "/login",
      getPages: [
        GetPage(
            name: "/home",
            page: () => HomePage(),
            middlewares: [AuthPageMiddleware()]),
        GetPage(
          name: "/login",
          page: () => LoginPage(),
        ),
      ],
    ),
  );
}

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: FlexThemeData.light(scheme: FlexScheme.deepBlue),
      home: OverlayPage(),
    ),
  );
}

