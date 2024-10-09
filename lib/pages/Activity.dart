import 'package:dispatch/constans.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewState extends GetxController {
  late WebViewController _controller;

  @override
  void onInit() {
    super.onInit();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Color(0x0000000))
      ..loadRequest(Uri.parse(activityUrl));
  }
}

class WebViewPage extends StatelessWidget {
  WebViewPage({super.key});

  final ctr = Get.put(WebViewState());

  @override
  Widget build(BuildContext context) {
    // return Text("hello world");
    return WebViewWidget(controller: ctr._controller);
  }
}
