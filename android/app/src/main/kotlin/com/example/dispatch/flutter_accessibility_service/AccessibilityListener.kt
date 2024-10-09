package com.example.dispatch.flutter_accessibility_service

import android.accessibilityservice.AccessibilityService
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo
import android.widget.Toast
import com.example.dispatch.TAG
import com.example.dispatch.flutter_accessibility_service.Constants.ACCESSIBILITY_INTENT
import com.example.dispatch.flutter_accessibility_service.Constants.SEND_BROADCAST
import com.google.gson.Gson

class AccessibilityListener : AccessibilityService() {

    companion object {
        var instance: AccessibilityListener? = null
    }

    fun getCurrNode(): Map<String, Any?>? {
        var nodeInfo: AccessibilityNodeInfo? = null

        for (window in windows) {
            if (window.type == AccessibilityWindowInfo.TYPE_APPLICATION) {
                nodeInfo = window.root
            }
        }

        if (nodeInfo == null) {
            return null
        }

        return nodeInfo.toMap(applicationContext)
    }

    fun clickRoot(id: String?, text: String?): Boolean {
        var nodeInfo: AccessibilityNodeInfo? = null

        println("点击开始2");
        windows.sortBy { it.layer }

        for (window in windows) {
            Log.d(TAG, window.toString())
            if (window.type == AccessibilityWindowInfo.TYPE_APPLICATION) {
                nodeInfo = window.root
            }
        }
        println("点击结束2");
        Log.d(TAG, "click id: $id, text: $text")
        Log.d(TAG, nodeInfo.toString())

        if (nodeInfo == null) {
            Toast.makeText(applicationContext, "未找到页面信息!", Toast.LENGTH_SHORT).show()
            return false
        }

        val targets = if (id != null) {
            nodeInfo.findAccessibilityNodeInfosByViewId(id)
        } else {
            nodeInfo.findAccessibilityNodeInfosByText(text)
        }

        if (targets.isEmpty()) {
            Toast.makeText(applicationContext, "未找到组件信息", Toast.LENGTH_SHORT).show()
            return false
        }


        println(targets);
        var target = targets[0]

        for (i in 0..3) {

            if (!target.isClickable) {
                target = target.parent
            }

            if (i == 3) {
                if (!target.isClickable) {
                    Toast.makeText(applicationContext, "未找到可点击组件信息", Toast.LENGTH_SHORT)
                        .show();
                    return false;
                }
            }
        }

        println("=====================")
        if (!target.performAction(AccessibilityNodeInfo.ACTION_CLICK)) {
            Toast.makeText(applicationContext, "操作失败", Toast.LENGTH_SHORT).show()
            return false
        }
        return true
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onInterrupt() {
    }

    override fun onAccessibilityEvent(accessibilityEvent: AccessibilityEvent) {
        val nodeInfo: AccessibilityNodeInfo = accessibilityEvent.source ?: return
        storeToSharedPrefs(nodeInfo.toMap(applicationContext))

        val intent = Intent(ACCESSIBILITY_INTENT)
        intent.putExtra(SEND_BROADCAST, true);
        sendBroadcast(intent);
    }

    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        val globalAction: Boolean = intent.getBooleanExtra(Constants.INTENT_GLOBAL_ACTION, false)
        val systemActions: Boolean =
            intent.getBooleanExtra(Constants.INTENT_SYSTEM_GLOBAL_ACTIONS, false)
        if (systemActions && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val actions: List<Int> = getSystemActions().map { it.id }
            val broadcastIntent = Intent(Constants.BROD_SYSTEM_GLOBAL_ACTIONS)
            broadcastIntent.putIntegerArrayListExtra("actions", ArrayList(actions))
            sendBroadcast(broadcastIntent)
        }
        if (globalAction) {
            val actionId: Int = intent.getIntExtra(Constants.INTENT_GLOBAL_ACTION_ID, 8)
            performGlobalAction(actionId)
        }
        Log.d("CMD_STARTED", "onStartCommand: $startId")
        return Service.START_STICKY
    }


    override fun onDestroy() {
        super.onDestroy()
        val sharedPreferences: SharedPreferences =
            getSharedPreferences(Constants.SHARED_PREFS_TAG, Context.MODE_PRIVATE)
        val editor: SharedPreferences.Editor = sharedPreferences.edit()
        editor.remove(Constants.ACCESSIBILITY_NODE).apply()
    }


    private fun storeToSharedPrefs(data: Map<String, Any?>) {
        val sharedPreferences: SharedPreferences =
            getSharedPreferences(Constants.SHARED_PREFS_TAG, Context.MODE_PRIVATE)
        val editor: SharedPreferences.Editor = sharedPreferences.edit()
        val gson = Gson()
        val json = gson.toJson(data)
        editor.putString(Constants.ACCESSIBILITY_NODE, json)
        editor.apply()
    }
}

