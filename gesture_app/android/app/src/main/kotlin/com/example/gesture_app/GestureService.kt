package com.example.gesture_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import android.view.GestureDetector
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import androidx.core.app.NotificationCompat
import kotlin.math.sqrt

class GestureService : Service(), SensorEventListener {

    private lateinit var windowManager: WindowManager
    private lateinit var floatingView: ImageView
    private lateinit var params: WindowManager.LayoutParams
    private lateinit var gestureDetector: GestureDetector
    private lateinit var vibrator: Vibrator

    // Sensor for Shake
    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null
    private var lastShakeTime: Long = 0

    // Defaults
    private var currentSize = 150 // Medium
    private var currentOpacity = 1.0f
    private var currentColor = "#424242"
    private var currentIcon = "pen"

    // New States
    private var isLocked = false
    private var isShakeEnabled = false

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()
        startForegroundService()
        startForegroundService()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator

        // Init Sensors
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "UPDATE_BUBBLE") {
            handleUpdate(intent)
        } else if (intent?.action == "UPDATE_SHAKE") {
            handleShakeUpdate(intent)
        } else {
            // Initial Setup if not already done
            if (!::floatingView.isInitialized) {
                setupBubble()
            }
        }
        return START_STICKY
    }

    private fun handleUpdate(intent: Intent) {
        if (!::floatingView.isInitialized) return

        if (intent.hasExtra("opacity")) {
            currentOpacity = intent.getFloatExtra("opacity", 1.0f)
            floatingView.alpha = currentOpacity
        }

        if (intent.hasExtra("size")) {
            val sizeStr = intent.getStringExtra("size")
            currentSize =
                    when (sizeStr) {
                        "small" -> 100
                        "large" -> 200
                        else -> 150
                    }
            requestLayoutUpdate()
        }

        if (intent.hasExtra("color")) {
            val colorStr = intent.getStringExtra("color") ?: "#424242"
            currentColor = colorStr
            updateBackground()
        }

        if (intent.hasExtra("icon")) {
            val iconStr = intent.getStringExtra("icon") ?: "pen"
            currentIcon = iconStr
            updateIcon()
        }

        if (intent.hasExtra("locked")) {
            isLocked = intent.getBooleanExtra("locked", false)
        }
    }

    private fun handleShakeUpdate(intent: Intent) {
        if (intent.hasExtra("enabled")) {
            val enabled = intent.getBooleanExtra("enabled", false)
            if (isShakeEnabled != enabled) {
                isShakeEnabled = enabled
                if (isShakeEnabled) {
                    accelerometer?.let {
                        sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
                    }
                } else {
                    sensorManager.unregisterListener(this)
                }
            }
        }
    }

    // ... [Existing updateBackground, updateIcon, requestLayoutUpdate methods] ...
    private fun updateBackground() {
        val shape = GradientDrawable()
        shape.shape = GradientDrawable.OVAL
        try {
            shape.setColor(android.graphics.Color.parseColor(currentColor))
        } catch (e: Exception) {
            shape.setColor(android.graphics.Color.DKGRAY)
        }

        // Dynamic Border
        if (currentColor.length == 9 && currentColor.startsWith("#88")) {
            // Glass mode: Thin white border
            shape.setStroke(2, android.graphics.Color.WHITE)
        } else {
            // Normal mode: White border
            shape.setStroke(4, android.graphics.Color.WHITE)
        }

        floatingView.background = shape
    }

    private fun updateIcon() {
        val iconRes =
                when (currentIcon) {
                    "bolt" -> android.R.drawable.ic_lock_idle_charging // System bolt-like
                    "dot" -> 0 // No icon
                    else -> android.R.drawable.ic_menu_edit // Pen
                }

        if (iconRes != 0) {
            floatingView.setImageDrawable(
                    androidx.core.content.ContextCompat.getDrawable(this, iconRes)
            )
            floatingView.setColorFilter(android.graphics.Color.WHITE)
        } else {
            floatingView.setImageDrawable(null)
        }
    }

    private fun requestLayoutUpdate() {
        params.width = currentSize
        params.height = currentSize
        windowManager.updateViewLayout(floatingView, params)
    }

    private fun setupBubble() {
        floatingView =
                ImageView(this).apply {
                    setImageResource(R.mipmap.ic_launcher)

                    val p = 30
                    setPadding(p, p, p, p)
                    scaleType = ImageView.ScaleType.FIT_CENTER
                    alpha = currentOpacity
                }

        updateBackground()
        updateIcon()

        val layoutFlag =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    WindowManager.LayoutParams.TYPE_PHONE
                }

        params =
                WindowManager.LayoutParams(
                        currentSize,
                        currentSize,
                        layoutFlag,
                        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                        PixelFormat.TRANSLUCENT
                )

        params.gravity = Gravity.TOP or Gravity.START
        params.x = 0
        params.y = 100

        windowManager.addView(floatingView, params)

        setupTouchListener()
    }

    private fun startForegroundService() {
        val channelId = "gesture_service_channel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel =
                    NotificationChannel(
                            channelId,
                            "Gesture Service",
                            NotificationManager.IMPORTANCE_LOW
                    )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        val notification =
                NotificationCompat.Builder(this, channelId)
                        .setContentTitle("Gesture App Active")
                        .setContentText("Tap bubble to draw")
                        .setSmallIcon(R.mipmap.ic_launcher)
                        .setOngoing(true)
                        .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(1, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            startForeground(1, notification)
        }
    }

    private fun setupTouchListener() {
        gestureDetector =
                GestureDetector(
                        this,
                        object : GestureDetector.SimpleOnGestureListener() {
                            override fun onSingleTapConfirmed(e: MotionEvent): Boolean {
                                openGestureCanvas()
                                return true
                            }

                            override fun onDoubleTap(e: MotionEvent): Boolean {
                                openSettings()
                                return true
                            }
                        }
                )

        floatingView.setOnTouchListener(
                object : View.OnTouchListener {
                    private var initialX = 0
                    private var initialY = 0
                    private var initialTouchX = 0f
                    private var initialTouchY = 0f

                    override fun onTouch(v: View, event: MotionEvent): Boolean {
                        if (gestureDetector.onTouchEvent(event)) return true

                        // Prevent dragging if locked
                        if (isLocked) return false

                        when (event.action) {
                            MotionEvent.ACTION_DOWN -> {
                                initialX = params.x
                                initialY = params.y
                                initialTouchX = event.rawX
                                initialTouchY = event.rawY
                                return true
                            }
                            MotionEvent.ACTION_MOVE -> {
                                params.x = initialX + (event.rawX - initialTouchX).toInt()
                                params.y = initialY + (event.rawY - initialTouchY).toInt()
                                windowManager.updateViewLayout(floatingView, params)
                                return true
                            }
                        }
                        return false
                    }
                }
        )
    }

    // --- Sensor Logic ---
    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null || !isShakeEnabled) return

        if (event.sensor.type == Sensor.TYPE_ACCELEROMETER) {
            val x = event.values[0]
            val y = event.values[1]
            val z = event.values[2]

            val gForce = sqrt(x * x + y * y + z * z) / SensorManager.GRAVITY_EARTH

            // Shake threshold (approx 2.3g)
            if (gForce > 2.3) {
                val now = System.currentTimeMillis()
                if (now - lastShakeTime > 1000) { // Debounce 1s
                    lastShakeTime = now
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        vibrator.vibrate(
                                VibrationEffect.createOneShot(50, VibrationEffect.DEFAULT_AMPLITUDE)
                        )
                    } else {
                        vibrator.vibrate(50)
                    }
                    openGestureCanvas()
                }
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // No-op
    }

    private fun openGestureCanvas() {
        val intent = Intent(this, MainActivity::class.java)
        intent.action = "OPEN_CANVAS"
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        startActivity(intent)
    }

    private fun openSettings() {
        val intent = Intent(this, MainActivity::class.java)
        intent.action = "OPEN_SETTINGS"
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        startActivity(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::floatingView.isInitialized) windowManager.removeView(floatingView)
        sensorManager.unregisterListener(this)
    }
}
