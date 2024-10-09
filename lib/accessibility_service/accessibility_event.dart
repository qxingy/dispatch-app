import 'dart:convert';

class AccessibilityNodeInfo {
  final String? appName;
  final String? packageName;
  final String? className;
  final String? text;
  final String? contentDescription;
  final String? viewIdResourceName;
  final bool? isClickable;
  final bool? isFocusable;
  final bool? isEnabled;
  final bool? isScrollable;
  final List<AccessibilityNodeInfo>? children;

  AccessibilityNodeInfo({
    this.appName,
    this.packageName,
    this.className,
    this.text,
    this.contentDescription,
    this.viewIdResourceName,
    this.isClickable,
    this.isFocusable,
    this.isEnabled,
    this.isScrollable,
    this.children,
  });

  factory AccessibilityNodeInfo.fromJson(Map<String, dynamic> json) {
    return AccessibilityNodeInfo(
      appName: json["appName"],
      packageName: json["packageName"],
      className: json['className'],
      text: json['text'],
      contentDescription: json['contentDescription'],
      viewIdResourceName: json['viewIdResourceName'],
      isClickable: json['isClickable'],
      isFocusable: json['isFocusable'],
      isEnabled: json['isEnabled'],
      isScrollable: json['isScrollable'],
      children: json['children'] != null
          ? (json['children'] as List)
          .map((i) => AccessibilityNodeInfo.fromJson(i))
          .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "appName": appName,
      'packageName': packageName,
      'className': className,
      'text': text,
      'contentDescription': contentDescription,
      'viewIdResourceName': viewIdResourceName,
      'isClickable': isClickable,
      'isFocusable': isFocusable,
      'isEnabled': isEnabled,
      'isScrollable': isScrollable,
      'children': children?.map((child) => child.toJson()).toList(),
    };
  }
}
