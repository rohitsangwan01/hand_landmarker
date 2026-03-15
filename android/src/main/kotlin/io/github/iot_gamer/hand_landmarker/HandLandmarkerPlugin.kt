package io.github.iot_gamer.hand_landmarker

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** HandLandmarkerPlugin */
class HandLandmarkerPlugin : FlutterPlugin, MethodCallHandler,
    HandLandmarkerEventStreamStreamHandler() {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "hand_landmarker")
        channel.setMethodCallHandler(this)
        HandLandmarkerEventStreamStreamHandler.register(flutterPluginBinding.binaryMessenger, this)
    }

    override fun onListen(p0: Any?, sink: PigeonEventSink<HandLandmarkerEventResult>) {
        HandLandmarkerResultBridge.setSink(sink)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        HandLandmarkerResultBridge.setSink(null)
    }
}
