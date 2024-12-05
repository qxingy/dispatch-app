package com.chediaodu.daju

import android.util.Log
import com.chediaodu.daju.flutter_accessibility_service.AccessibilityServicePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

const val TAG = "com.chediaodu.daju"

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        try {
            flutterEngine.plugins.add(AppManager())
            flutterEngine.plugins.add(AccessibilityServicePlugin())
        } catch (e: Exception) {
            Log.e("AppManager", "Error adding AppManager")
        }
    }
}
