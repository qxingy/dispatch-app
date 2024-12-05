package com.chediaodu.daju.flutter_accessibility_service

import android.annotation.SuppressLint
import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.provider.Settings
import android.util.Log
import android.widget.Toast
import androidx.annotation.RequiresApi
import com.google.gson.Gson
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import io.flutter.plugins.sharedpreferences.TAG


class AccessibilityServicePlugin : FlutterPlugin, ActivityAware, MethodCallHandler,
    ActivityResultListener, EventChannel.StreamHandler {
    private var channel: MethodChannel? = null
    private var accessibilityReceiver: AccessibilityReceiver? = null
    private var eventChannel: EventChannel? = null
    private var context: Context? = null
    private var mActivity: Activity? = null

    private var pendingResult: MethodChannel.Result? = null
    private val REQUEST_CODE_FOR_ACCESSIBILITY: Int = 167

    companion object {
        private const val CHANNEL_TAG = "accessibility_channel"
        private const val EVENT_TAG = "accessibility_event"
        const val CACHED_TAG: String = "cashedAccessibilityEngine"

    }

    private fun bringAppToForeground(packageName: String) {
        val intent = context?.packageManager?.getLaunchIntentForPackage(packageName)
        if (intent != null) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context?.startActivity(intent)
        } else {
            Toast.makeText(context, "无法找到应用", Toast.LENGTH_LONG).show()
            return
        }

    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_TAG)
        channel!!.setMethodCallHandler(this)
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_TAG)
        eventChannel!!.setStreamHandler(this)
    }

    private val actionsReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val actions: List<Int>? = intent.getIntegerArrayListExtra("actions")
            pendingResult!!.success(actions)
        }
    }

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        pendingResult = result

        when (call.method) {
            "isAccessibilityPermissionEnabled" -> {
                result.success(Utils.isAccessibilitySettingsOn(context))
            }

            "requestAccessibilityPermission" -> {
                val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                mActivity!!.startActivityForResult(intent, REQUEST_CODE_FOR_ACCESSIBILITY)
            }

            "getCurrNode" -> {
                val nodeInfo = AccessibilityListener.instance?.getCurrNode()
                val gson = Gson()
                val json = gson.toJson(nodeInfo)
                result.success(json)
            }

            "bringAppToForeground" -> {
                val packageName = call.argument<String>("packageName")!!;
                bringAppToForeground(packageName);
            }

            "performAction" -> {
                val id = call.argument<String?>("id");
                val text = call.argument<String?>("text");
                result.success(AccessibilityListener.instance?.clickRoot(id, text));
            }


            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        channel!!.setMethodCallHandler(null)
        eventChannel!!.setStreamHandler(null)
        context!!.unregisterReceiver(actionsReceiver)
    }

    @SuppressLint("WrongConstant")
    override fun onListen(arguments: Any?, events: EventSink) {
        if (Utils.isAccessibilitySettingsOn(context)) {
            val intentFilter = IntentFilter()
            intentFilter.addAction(Constants.ACCESSIBILITY_INTENT)

            accessibilityReceiver = AccessibilityReceiver(events)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                context!!.registerReceiver(
                    accessibilityReceiver,
                    intentFilter,
                    Context.RECEIVER_EXPORTED
                )
            } else {
                context!!.registerReceiver(accessibilityReceiver, intentFilter)
            }

            /// Set up listener intent
            val listenerIntent = Intent(context, AccessibilityListener::class.java)
            context!!.startService(listenerIntent)
            Log.i("AccessibilityPlugin", "Started the accessibility tracking service.")
        }
    }

    override fun onCancel(arguments: Any?) {
        context!!.unregisterReceiver(accessibilityReceiver)
        accessibilityReceiver = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_FOR_ACCESSIBILITY) {
            if (resultCode == Activity.RESULT_OK) {
                pendingResult!!.success(true)
            } else if (resultCode == Activity.RESULT_CANCELED) {
                pendingResult!!.success(Utils.isAccessibilitySettingsOn(context))
            } else {
                pendingResult!!.success(false)
            }
            return true
        }
        return false
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.mActivity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        this.mActivity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        this.mActivity = null
    }
}
