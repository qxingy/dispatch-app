import 'dart:convert';

import 'package:dispatch/utils.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRemoteInfo {
  final String appName;
  final String packageName;
  final String promotionLink;
  final int sortId;
  final String node;
  final String node1;
  final String node2;
  final String node3;

  AppRemoteInfo({
    required this.appName,
    required this.packageName,
    required this.promotionLink,
    required this.sortId,
    required this.node,
    required this.node1,
    required this.node2,
    required this.node3,
  });

  factory AppRemoteInfo.fromJson(Map<String, dynamic> json) {
    return AppRemoteInfo(
      appName: json['app_name'],
      packageName: json['package_name'],
      promotionLink: json['promotion_link'],
      sortId: json['sort_id'],
      node: json['node'],
      node1: json['node1'],
      node2: json['node2'],
      node3: json['node3'],
    );
  }
}

class UserInfo {
  final String username;
  final int expirationTime;
  final int onlineNum;
  final String phone;

  UserInfo({
    required this.username,
    required this.expirationTime,
    required this.onlineNum,
    required this.phone,
  });

  bool isExpire() {
    return DateTime.now().millisecondsSinceEpoch > expirationTime * 1000;
  }
}

class ApiProvider extends GetConnect {
  final repo = Get.find<LocalRepo>();
  final List<String> authWhiteList = [
    "/user/login",
    "/user/sendEmail",
    "/user/emailLogin"
        "/business/ws"
  ];

  @override
  void onInit() {
    // httpClient.baseUrl = 'http://49.233.252.12/api';
    httpClient.baseUrl = 'http://192.168.0.65:5586/api';

    httpClient.addRequestModifier<dynamic>((req) async {
      if (!authWhiteList.any((url) => req.url.toString().contains(url))) {
        final token = await repo.getToken();
        if (token == null) {
          Get.offAllNamed("/login");
          throw Exception("请先登录");
        }

        req.headers["auth-sign"] = token;
      }
      return req;
    });

    httpClient.addResponseModifier<dynamic>((req, resp) async {
      if (resp.body["code"] != 200) {
        Get.snackbar("错误", resp.body["message"]);
        throw Exception(resp.body["message"]);
      }
      return resp;
    });
  }

  Future<String> userLogin(String username, String password) async {
    final result = await post("/user/login",
        {"username": username, "password": generateMd5(password)});
    return result.body["auth-sign"];
  }

  Future<void> sendEmail(String username) async {
    await post("/user/sendEmail", {"username": username});
  }

  Future<String> codeLogin(String username, String code) async {
    final result =
        await post("/user/emailLogin", {"username": username, "code": code});
    return result.body["token"];
  }

  Future<List<AppRemoteInfo>?> getAppName() async {
    final result = await get("/business/getAppName");
    return (result.body["data"] as List<dynamic>)
        .map((v) => AppRemoteInfo.fromJson(v))
        .toList();
  }

  Future<void> addNode(dynamic data) async {
    await post("/business/addNode", jsonEncode({"node": jsonEncode(data)}));
  }

  Future<List<dynamic>> getUserIpList() async {
    final result = await get("/business/getUserIpList");
    return result.body["data"];
  }

  Future<GetSocket> connect() async {
    final conn = socket(
        "${httpClient.baseUrl}/business/ws?key=${await repo.getToken()}");
    conn.onOpen(() {
      logger.d("websocket open");
    });
    conn.onClose((data) {
      logger.d("websocket close: $data");
    });
    conn.onError((data) {
      logger.d("websocket error: $data");
    });
    await conn.connect();
    return conn;
  }

  Future<void> cdkActivation(String username, String cdk) async {
    await post("/business/cdkActivation", {
      "username": username,
      "cdk": cdk,
    });
  }

  Future<UserInfo> userInfo() async {
    final result = await get("/user/getUsers");
    return UserInfo(
      username: result.body["data"][0]["username"],
      expirationTime: result.body["data"][0]["expiration_time"],
      onlineNum: result.body["data"][0]["onlinenum"],
      phone: result.body["data"][0]["phone"],
    );
  }
}

class LocalRepo {
  static const String tokenKey = "token";

  Future<String?> getToken() async =>
      (await SharedPreferences.getInstance()).getString(tokenKey);

  Future<void> setToken(String token) async =>
      (await SharedPreferences.getInstance()).setString(tokenKey, token);

  Future<void> removeToken() async =>
      (await SharedPreferences.getInstance()).remove(tokenKey);

  Future<bool> isInit() async =>
      (await SharedPreferences.getInstance()).getBool("init") ?? false;

  Future<void> setInit() async =>
      (await SharedPreferences.getInstance()).setBool("init", true);

  Future<void> setUnInit() async =>
      (await SharedPreferences.getInstance()).setBool("init", false);

  Future<void> setCdKey(String cdKey) async =>
      (await SharedPreferences.getInstance()).setString("cd_key", cdKey);

  Future<String> getCdKey() async =>
      (await SharedPreferences.getInstance()).getString("cd_key") ?? "";

  Future<void> setAccount(String account) async =>
      (await SharedPreferences.getInstance()).setString("account", account);

  Future<String> getAccount() async =>
      (await SharedPreferences.getInstance()).getString("account") ?? "";
}
