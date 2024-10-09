import 'dart:convert';

import 'package:dispatch/global.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../accessibility_service/accessibility_event.dart';

class ReportCtr extends GetxController {
  final global = Get.find<GlobalService>();
}

class ReportPage extends StatelessWidget {
  ReportPage({super.key});

  final ctr = Get.put(ReportCtr());

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        if (ctr.global.reportData.isEmpty) {
          return Center(
            child: Text("暂无上报数据"),
          );
        } else {
          return ListView.builder(
            itemCount: ctr.global.reportData.length,
            itemBuilder: (context, index) {
              final report = ctr.global.reportData[index];
              return ListTile(
                title: Text(report.appName ?? ""),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return JsonView(
                        data: (report),
                      );
                    },
                  );
                },
              );
            },
          );
        }
      },
    );
  }
}

class JsonView extends StatelessWidget {
  JsonView({super.key, required this.data});

  final AccessibilityNodeInfo data;

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Text(JsonEncoder.withIndent("    ").convert(data.toJson())),
      ),
    );
  }
}
