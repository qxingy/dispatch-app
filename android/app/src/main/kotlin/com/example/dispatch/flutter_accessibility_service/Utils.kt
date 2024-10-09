package com.example.dispatch.flutter_accessibility_service

import android.content.Context
import android.provider.Settings
import android.provider.Settings.SettingNotFoundException
import android.text.TextUtils.SimpleStringSplitter
import android.view.accessibility.AccessibilityNodeInfo


object Utils {
    fun isAccessibilitySettingsOn(mContext: Context?): Boolean {
        var accessibilityEnabled = 0
        val service = mContext!!.packageName + "/" + AccessibilityListener::class.java.canonicalName
        try {
            accessibilityEnabled = Settings.Secure.getInt(
                mContext.applicationContext.contentResolver,
                Settings.Secure.ACCESSIBILITY_ENABLED
            )
        } catch (e: SettingNotFoundException) {
            return false
        }
        val mStringColonSplitter = SimpleStringSplitter(':')
        if (accessibilityEnabled == 1) {
            val settingValue = Settings.Secure.getString(
                mContext.applicationContext.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            if (settingValue != null) {
                mStringColonSplitter.setString(settingValue)
                while (mStringColonSplitter.hasNext()) {
                    val accessibilityService = mStringColonSplitter.next()
                    if (accessibilityService.equals(service, ignoreCase = true)) {
                        return true
                    }
                }
            }
        }
        return false
    }
}

fun AccessibilityNodeInfo.toMap(context: Context): Map<String, Any?> {
    val map = mutableMapOf<String, Any?>()

    map["packageName"] = packageName?.toString() ?: ""
    map["appName"] = if (packageName != null) {
        val info = context.packageManager.getApplicationInfo(packageName.toString(), 0)
        context.packageManager.getApplicationLabel(info).toString()
    } else {
        ""
    }

    map["className"] = className?.toString() ?: ""
    map["text"] = text?.toString() ?: ""
    map["contentDescription"] = contentDescription?.toString() ?: ""
    map["viewIdResourceName"] = viewIdResourceName ?: ""
    map["isClickable"] = isClickable
    map["isFocusable"] = isFocusable
    map["isEnabled"] = isEnabled
    map["isScrollable"] = isScrollable

    // 处理子节点
    val children = mutableListOf<Map<String, Any?>>()
    for (i in 0 until childCount) {
        val child = getChild(i)
        if (child != null) {
            children.add(child.toMap(context))
            child.recycle()  // 回收子节点对象
        }
    }
    map["children"] = children

    return map
}



