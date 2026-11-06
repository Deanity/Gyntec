package com.example.gyntec

import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.gyntec/device_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getDeviceName") {
                val deviceName = getDeviceName()
                result.success(deviceName)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getDeviceName(): String {
        // 1. Coba baca Settings.Global.DEVICE_NAME (nama kustom HP jika ada)
        try {
            val customName = Settings.Global.getString(contentResolver, "device_name")
            if (!customName.isNullOrBlank()) {
                return customName
            }
        } catch (_: Exception) {}

        // 2. Coba bluetooth_name
        try {
            val btName = Settings.Secure.getString(contentResolver, "bluetooth_name")
            if (!btName.isNullOrBlank()) {
                return btName
            }
        } catch (_: Exception) {}

        // 3. Fallback Manufacturer + Model
        val manufacturer = Build.MANUFACTURER.replaceFirstChar { if (it.isLowerCase()) it.titlecase() else it.toString() }
        val model = Build.MODEL
        return if (model.startsWith(manufacturer, ignoreCase = true)) {
            model
        } else {
            "$manufacturer $model"
        }
    }
}

