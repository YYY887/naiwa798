package com.example.super798_flutter

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "奶娃喝水/桌面组件").setMethodCallHandler { call, result ->
            if (call.method != "设置快捷设备") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val name = call.argument<String>("名称")
            if (name.isNullOrBlank()) {
                result.error("参数错误", "缺少设备名称", null)
                return@setMethodCallHandler
            }
            WaterShortcutWidgetProvider.saveDevice(this, name)
            result.success(null)
        }
    }
}
