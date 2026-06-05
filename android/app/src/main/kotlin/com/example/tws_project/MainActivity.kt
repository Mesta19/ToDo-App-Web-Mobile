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
                    "requestAutoStartPermission" -> {
                        requestAutoStart()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Membuka halaman pengaturan Autostart/Mulai Otomatis secara manual
     * untuk berbagai merek HP (Xiaomi, Oppo, Vivo, Asus, dll).
     */
    private fun requestAutoStart() {
        try {
            val intents = arrayOf(
                // Xiaomi / Poco
                Intent().setClassName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"),
                // Oppo / Realme
                Intent().setClassName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"),
                Intent().setClassName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity"),
                Intent().setClassName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity"),
                // Vivo
                Intent().setClassName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"),
                Intent().setClassName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity"),
                Intent().setClassName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager"),
                // Huawei / Honor
                Intent().setClassName("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity"),
                Intent().setClassName("com.huawei.systemmanager", "com.huawei.systemmanager.appcontrol.activity.StartupAppControlActivity"),
                // Asus
                Intent().setClassName("com.asus.mobilemanager", "com.asus.mobilemanager.entry.FunctionActivity"),
                Intent().setClassName("com.asus.mobilemanager", "com.asus.mobilemanager.autostart.AutoStartActivity"),
                // Letv
                Intent().setClassName("com.letv.android.letvsafe", "com.letv.android.letvsafe.AutobootManageActivity"),
                // Honor (Magic UI)
                Intent().setClassName("com.hihonor.systemmanager", "com.hihonor.systemmanager.optimize.process.ProtectActivity"),
                // Samsung
                Intent().setClassName("com.samsung.android.lool", "com.samsung.android.sm.ui.battery.BatteryActivity"),
                Intent().setClassName("com.samsung.android.sm", "com.samsung.android.sm.ui.battery.BatteryActivity"),
                Intent().setClassName("com.samsung.android.sm_cn", "com.samsung.android.sm.ui.battery.BatteryActivity")
            )

            var found = false
            for (intent in intents) {
                if (packageManager.resolveActivity(intent, android.content.pm.PackageManager.MATCH_DEFAULT_ONLY) != null) {
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    found = true
                    break
                }
            }

            // Jika tidak ada intent autostart khusus yang ditemukan, 
            // kita buka pengaturan aplikasi umum saja.
            if (!found) {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
            }
        } catch (e: Exception) {
            e.printStackTrace()
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
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                } catch (e: Exception) {
                    // Fallback: buka halaman battery settings umum
                    try {
                        val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                    } catch (e2: Exception) {
                        // Tidak fatal, abaikan
                    }
                }
            }
        }
    }
}
