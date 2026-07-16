package com.bearhunter.zenno

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.InputDevice
import android.view.MotionEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val STYLUS_PROXIMITY_CHANNEL =
            "com.bearhunter.zenno/stylus_proximity"
        private const val STYLUS_HOVER_LEASE_MS = 300L
    }

    private val proximityHandler = Handler(Looper.getMainLooper())
    private var stylusInProximity = false
    private var stylusContactActive = false
    private var stylusDeviceId: Int? = null
    private var lastStylusHoverUptimeMs = 0L
    private var proximityExpiryScheduled = false
    private var stylusProximityChannel: MethodChannel? = null
    private val expireStylusProximity = Runnable {
        proximityExpiryScheduled = false
        if (!stylusInProximity || stylusContactActive) return@Runnable
        val remainingMs = STYLUS_HOVER_LEASE_MS -
            (SystemClock.uptimeMillis() - lastStylusHoverUptimeMs)
        if (remainingMs > 0) {
            scheduleProximityExpiry(remainingMs)
        } else {
            setStylusInProximity(false)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        stylusProximityChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            STYLUS_PROXIMITY_CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method == "getStylusProximity") {
                    result.success(stylusInProximity)
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        findViewById<FlutterView>(FLUTTER_VIEW_ID).setOnHoverListener { _, event ->
            handleHoverEvent(event)
            false
        }
    }

    private fun handleHoverEvent(event: MotionEvent) {
        when (event.actionMasked) {
            MotionEvent.ACTION_HOVER_ENTER,
            MotionEvent.ACTION_HOVER_MOVE,
            -> if (event.isStylusEvent()) {
                renewStylusProximity(event)
            }

            MotionEvent.ACTION_HOVER_EXIT -> if (
                stylusInProximity &&
                (event.deviceId == stylusDeviceId || event.isStylusEvent())
            ) {
                setStylusInProximity(false)
            }
        }
    }

    override fun dispatchTouchEvent(event: MotionEvent): Boolean {
        if (event.isStylusEvent()) {
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    stylusContactActive = true
                    cancelProximityExpiry()
                    stylusDeviceId = event.deviceId
                    setStylusInProximity(true)
                }
                MotionEvent.ACTION_UP,
                MotionEvent.ACTION_CANCEL,
                -> {
                    stylusContactActive = false
                    setStylusInProximity(false)
                }
            }
        }
        return super.dispatchTouchEvent(event)
    }

    override fun onPause() {
        stylusContactActive = false
        setStylusInProximity(false)
        super.onPause()
    }

    private fun renewStylusProximity(event: MotionEvent) {
        stylusDeviceId = event.deviceId
        lastStylusHoverUptimeMs = SystemClock.uptimeMillis()
        setStylusInProximity(true)
        scheduleProximityExpiry(STYLUS_HOVER_LEASE_MS)
    }

    private fun scheduleProximityExpiry(delayMs: Long) {
        if (proximityExpiryScheduled || stylusContactActive) return
        proximityExpiryScheduled = true
        proximityHandler.postDelayed(expireStylusProximity, delayMs)
    }

    private fun cancelProximityExpiry() {
        proximityExpiryScheduled = false
        proximityHandler.removeCallbacks(expireStylusProximity)
    }

    private fun MotionEvent.isStylusEvent(): Boolean {
        if (isFromSource(InputDevice.SOURCE_STYLUS)) return true
        if (pointerCount == 0) return false
        return when (getToolType(actionIndex.coerceIn(0, pointerCount - 1))) {
            MotionEvent.TOOL_TYPE_STYLUS,
            MotionEvent.TOOL_TYPE_ERASER,
            -> true

            else -> false
        }
    }

    private fun setStylusInProximity(value: Boolean) {
        if (!value) {
            cancelProximityExpiry()
            stylusDeviceId = null
        }
        if (stylusInProximity == value) return
        stylusInProximity = value
        stylusProximityChannel?.invokeMethod("stylusProximityChanged", value)
    }
}
