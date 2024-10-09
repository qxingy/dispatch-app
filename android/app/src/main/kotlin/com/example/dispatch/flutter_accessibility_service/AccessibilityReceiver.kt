package com.example.dispatch.flutter_accessibility_service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.example.dispatch.TAG
import io.flutter.plugin.common.EventChannel.EventSink

class AccessibilityReceiver(private val eventSink: EventSink) : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val sharedPreferences =
            context.getSharedPreferences(Constants.SHARED_PREFS_TAG, Context.MODE_PRIVATE)
        val json = sharedPreferences.getString(Constants.ACCESSIBILITY_NODE, "")


        eventSink.success(json)
    }
}
