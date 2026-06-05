package com.example.tws_project

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val BATTERY_CHANNEL = "com.tws_project/battery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestIgnoreBatteryOptimizations" -> {
                        requestBatteryOptimizationExemption()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Minta agar app dikecualikan dari battery optimization Android.
     * Ini memastikan alarm (notifikasi terjadwal) tetap terjadwal
     * meski user menutup / swipe app dari recent apps.
     */
    private fun requestBatteryOptimizationExemption() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = getSystemService(POWER_SERVICE) as PowerManager
            val packageName = packageName

            // Hanya minta kalau belum dikecualikan
            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                try {
                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                        data = Uri.parse("package:$packageName")
                    }
                    startActivity(intent)
                } catch (e: Exception) {
                    // Fallback: buka halaman battery settings umum
                    try {
                        val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        startActivity(intent)
                    } catch (e2: Exception) {
                        // Tidak fatal, abaikan
                    }
                }
            }
        }
    }
}
