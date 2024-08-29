package com.example.dispatch

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

const val TAG = "com.example.dispatch"

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        try {
            flutterEngine.plugins.add(AppManager())
        } catch (e: Exception) {
            Log.e("AppManager", "Error adding AppManager")
        }
    }
}
