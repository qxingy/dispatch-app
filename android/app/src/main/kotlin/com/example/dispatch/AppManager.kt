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
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import android.graphics.drawable.BitmapDrawable
import android.provider.Settings
import android.widget.Toast
import com.jayway.jsonpath.JsonPath
import java.io.ByteArrayOutputStream

class AppManager : FlutterPlugin, ActivityAware, MethodCallHandler {

    companion object {
        @SuppressLint("StaticFieldLeak")
        private lateinit var context: Context
        private lateinit var channel: MethodChannel

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

    @SuppressLint("HardwareIds")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInstalledApps" -> {
                val apps = context.packageManager.getInstalledApplications(0);
                result.success(apps.map { app ->
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
                })
            }

            "cutAppInternet" -> {
                val uid = call.argument<Int>("uid")
                Log.i(TAG, "cut app internet $uid")
                val msg = Runtime.getRuntime()
                    .exec("su -c iptables -A OUTPUT -m owner --uid-owner $uid -j DROP").waitFor();
                Log.d(TAG, "result: $msg")
                result.success(null)
            }

            "restoreAppInternet" -> {
                val uid = call.argument<Int>("uid")
                Log.i(TAG, "restore app internet $uid")
                val msg = Runtime.getRuntime()
                    .exec("su -c iptables -D OUTPUT -m owner --uid-owner $uid -j DROP").waitFor();
                Log.d(TAG, "result: $msg")
                result.success(null)
            }

            "isAppInternetCut" -> {
                val uid = call.argument<Int>("uid");
                try {
                    val process =
                        Runtime.getRuntime()
                            .exec("su -c iptables -L OUTPUT -v -n -t filter | grep $uid")
                    val output = process.inputStream.bufferedReader().readText()
                    result.success(output.contains("$uid"))
                } catch (e: Exception) {
                    e.printStackTrace()
                    result.success(false);
                }
            }

            "match" -> {
                try {
                    val data: List<String> =
                        JsonPath.read(call.argument<String>("json"), call.argument("data"))
                    Log.e(TAG, data.toString());
                    result.success(data.isNotEmpty())
                } catch (e: Exception) {
                    Log.e(TAG, e.message, e)
                    result.success(false);
                }
            }


            "bringToForeground" -> {
                context.startActivity(
                    Intent(
                        context,
                        MainActivity::class.java
                    ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        .addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                )
                result.success(null)
            }

            "toast" -> {
                Toast.makeText(context, call.argument<String>("message"), Toast.LENGTH_SHORT)
                    .show()
                result.success(null)
            }

            "getDeviceId" -> result.success(
                Settings.Secure.getString(
                    context.contentResolver,
                    Settings.Secure.ANDROID_ID,
                )
            )
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
