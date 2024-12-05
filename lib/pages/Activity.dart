import 'package:dispatch/constans.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

class WebViewState extends GetxController {
  late InAppWebViewController _controller;

  @override
  void onInit() {
    super.onInit();
  }
}

class WebViewPage extends StatelessWidget {
  WebViewPage({super.key});

  final ctr = Get.put(WebViewState());

  @override
  Widget build(BuildContext context) {
    return Container(
        child: InAppWebView(
      pullToRefreshController: PullToRefreshController(
        settings: PullToRefreshSettings()
      ),
      gestureRecognizers: Set()
        ..add(Factory<VerticalDragGestureRecognizer>(
            () => VerticalDragGestureRecognizer())),
      initialUrlRequest: URLRequest(url: WebUri(activityUrl)),
      initialSettings: InAppWebViewSettings(
        useHybridComposition: true,
        verticalScrollBarEnabled: false,
        disallowOverScroll: false,
        alwaysBounceVertical: true,
      ),
    ));
  }
}
