package com.example.gesture_app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.gesture_app/permissions"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermissions" -> {
                    val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                    val isIgnoringBatteryOptimizations =
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                pm.isIgnoringBatteryOptimizations(packageName)
                            } else {
                                true
                            }

                    val perms =
                            mapOf(
                                    "overlay" to Settings.canDrawOverlays(context),
                                    "battery_optimization" to isIgnoringBatteryOptimizations,
                                    "notification" to
                                            NotificationManagerCompat.from(context)
                                                    .areNotificationsEnabled()
                            )
                    result.success(perms)
                }
                "requestOverlay" -> {
                    if (!Settings.canDrawOverlays(context)) {
                        val intent =
                                Intent(
                                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                        Uri.parse("package:$packageName")
                                )
                        startActivity(intent)
                    }
                    result.success(true)
                }
                "requestBatteryOptimization" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                        if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                            val intent =
                                    Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                            intent.data = Uri.parse("package:$packageName")
                            startActivity(intent)
                        }
                    }
                    result.success(true)
                }
                "openNotificationSettings" -> {
                    val intent = Intent()
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        intent.action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
                        intent.putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                    } else {
                        intent.action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                        intent.data = Uri.parse("package:$packageName")
                    }
                    startActivity(intent)
                    result.success(true)
                }
                "startService" -> {
                    val intent = Intent(context, GestureService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }
                "getInitialAction" -> {
                    result.success(intent.action)
                }
                "moveTaskToBack" -> {
                    moveTaskToBack(true)
                    result.success(true)
                }
                "updateBubbleOpacity" -> {
                    val opacity = call.argument<Double>("opacity")?.toFloat() ?: 1.0f
                    val intent = Intent(context, GestureService::class.java)
                    intent.action = "UPDATE_BUBBLE"
                    intent.putExtra("opacity", opacity)
                    startService(intent)
                    result.success(true)
                }
                "updateBubbleSize" -> {
                    val size = call.argument<String>("size")
                    val intent = Intent(context, GestureService::class.java)
                    intent.action = "UPDATE_BUBBLE"
                    intent.putExtra("size", size)
                    startService(intent)
                    result.success(true)
                }
                "updateBubbleColor" -> {
                    val color = call.argument<String>("color")
                    val intent = Intent(context, GestureService::class.java)
                    intent.action = "UPDATE_BUBBLE"
                    intent.putExtra("color", color)
                    startService(intent)
                    result.success(true)
                }
                "updateBubbleIcon" -> {
                    val icon = call.argument<String>("icon")
                    val intent = Intent(context, GestureService::class.java)
                    intent.action = "UPDATE_BUBBLE"
                    intent.putExtra("icon", icon)
                    startService(intent)
                    result.success(true)
                }
                "updateBubbleLock" -> {
                    val locked = call.argument<Boolean>("locked") ?: false
                    val intent = Intent(context, GestureService::class.java)
                    intent.action = "UPDATE_BUBBLE"
                    intent.putExtra("locked", locked)
                    startService(intent)
                    result.success(true)
                }
                "updateShakeToWake" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    val intent = Intent(context, GestureService::class.java)
                    intent.action = "UPDATE_SHAKE"
                    intent.putExtra("enabled", enabled)
                    startService(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.action == "OPEN_CANVAS" || intent.action == "OPEN_SETTINGS") {
            methodChannel?.invokeMethod("onActionReceived", intent.action)
        }
    }
}
