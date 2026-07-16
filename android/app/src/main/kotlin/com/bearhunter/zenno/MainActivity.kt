package com.bearhunter.zenno

import android.view.MotionEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val STYLUS_PROXIMITY_CHANNEL =
            "com.bearhunter.zenno/stylus_proximity"
    }

    private var stylusInProximity = false
    private var stylusProximityChannel: MethodChannel? = null

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

    override fun dispatchGenericMotionEvent(event: MotionEvent): Boolean {
        if (event.pointerCount > 0 && event.isStylusEvent()) {
            when (event.actionMasked) {
                MotionEvent.ACTION_HOVER_ENTER,
                MotionEvent.ACTION_HOVER_MOVE,
                -> setStylusInProximity(true)

                MotionEvent.ACTION_HOVER_EXIT -> setStylusInProximity(false)
            }
        }
        return super.dispatchGenericMotionEvent(event)
    }

    override fun onPause() {
        setStylusInProximity(false)
        super.onPause()
    }

    private fun MotionEvent.isStylusEvent(): Boolean {
        return when (getToolType(actionIndex.coerceIn(0, pointerCount - 1))) {
            MotionEvent.TOOL_TYPE_STYLUS,
            MotionEvent.TOOL_TYPE_ERASER,
            -> true

            else -> false
        }
    }

    private fun setStylusInProximity(value: Boolean) {
        if (stylusInProximity == value) return
        stylusInProximity = value
        stylusProximityChannel?.invokeMethod("stylusProximityChanged", value)
    }
}
