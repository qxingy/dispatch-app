package com.example.dispatch

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.os.Build.VERSION.SDK_INT
import android.os.Build.VERSION_CODES.P
import android.util.Log
import com.example.dispatch.Handler.Companion.cutAppInternet
import com.example.dispatch.Handler.Companion.getInstalledApps
import com.example.dispatch.Handler.Companion.isAppInternetCut
import com.example.dispatch.Handler.Companion.restoreAppInternet
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import java.io.ByteArrayInputStream
import android.graphics.drawable.BitmapDrawable
import com.example.dispatch.Handler.Companion.bringToForeground
import com.example.dispatch.Handler.Companion.match
import com.jayway.jsonpath.JsonPath
import java.io.ByteArrayOutputStream

class AppManager : FlutterPlugin, ActivityAware, MethodCallHandler {

    companion object {
        @SuppressLint("StaticFieldLeak")
        private lateinit var context: Context
        private lateinit var channel: MethodChannel
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInstalledApps" -> result.success(getInstalledApps(context))
            "cutAppInternet" -> result.success(cutAppInternet(call.argument<Int>("uid")!!))
            "restoreAppInternet" -> result.success(restoreAppInternet(call.argument<Int>("uid")!!))
            "isAppInternetCut" -> result.success(isAppInternetCut(call.argument<Int>("uid")!!))
            "match" -> result.success(
                match(
                    call.argument<String>("json")!!,
                    call.argument<String>("data")!!
                )
            )

            "bringToForeground" -> result.success(bringToForeground(context))
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "app_manager")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        context = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        context = binding.activity
    }

    override fun onDetachedFromActivity() {}

}

class Handler() {
    companion object {
        fun bringToForeground(context: Context): Boolean {
            context.startActivity(
                Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    .addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT),
            )

            return true;
        }

        fun getInstalledApps(context: Context): List<Map<String, Any?>> {
            val apps = context.packageManager.getInstalledApplications(0);
            return apps.map { app ->
                val pkgInfo = context.packageManager.getPackageInfo(app.packageName, 0)
                mapOf(
                    "uid" to app.uid,
                    "name" to app.loadLabel(context.packageManager).toString(),
                    "package_name" to app.packageName,
                    "icon" to drawableToByteArray(app.loadIcon(context.packageManager)),
                    "version_name" to context.packageManager.getPackageInfo(
                        app.packageName, 0
                    ).packageName,
                    "version_code" to if (SDK_INT < P) pkgInfo.versionCode.toLong() else pkgInfo.longVersionCode,
                )
            }
        }

        fun match(json: String, match: String): Boolean {
            try {
                val result: List<String> = JsonPath.read(json, match)
                return result.isNotEmpty()
            } catch (e: Exception) {
                Log.e(TAG, e.message, e)
                return false;
            }
        }

        fun cutAppInternet(uid: Int): Boolean {
            Log.i(TAG, "cut app internet $uid")
            val result = Runtime.getRuntime()
                .exec("su -c iptables -A OUTPUT -m owner --uid-owner $uid -j DROP").waitFor();
            Log.d(TAG, "result: $result")
            return true;
        }

        fun restoreAppInternet(uid: Int): Boolean {
            Log.i(TAG, "restore app internet $uid")
            val result = Runtime.getRuntime()
                .exec("su -c iptables -D OUTPUT -m owner --uid-owner $uid -j DROP").waitFor();
            Log.d(TAG, "result: $result")
            return true;
        }

        fun isAppInternetCut(uid: Int): Boolean {
            try {
                val process =
                    Runtime.getRuntime()
                        .exec("su -c iptables -L OUTPUT -v -n -t filter | grep $uid")
                val output = process.inputStream.bufferedReader().readText()
                return output.contains("$uid")
            } catch (e: Exception) {
                e.printStackTrace()
                return false;
            }
        }

        private fun drawableToByteArray(drawable: Drawable): ByteArray {
            val bitmap = drawableToBitmap(drawable)
            ByteArrayOutputStream().use { stream ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                return stream.toByteArray()
            }
        }

        private fun drawableToBitmap(drawable: Drawable): Bitmap {
            if (drawable is BitmapDrawable) {
                return drawable.bitmap
            }
            val bitmap = Bitmap.createBitmap(
                drawable.intrinsicWidth,
                drawable.intrinsicHeight,
                Bitmap.Config.ARGB_8888
            )
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            return bitmap
        }
    }
}