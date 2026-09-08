package ru.shray77.vetos

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

/**
 * VetOS: нативный мост для лаунчера (вместо устаревших плагинов).
 *
 * Методы канала "vetos/apps":
 *  - listApps {includeSystem}  → список запускаемых приложений с иконками (PNG bytes)
 *  - isInstalled {package}     → установлен ли пакет
 *  - launch {package}          → запуск по package name (launch intent)
 */
class MainActivity : FlutterActivity() {

    private val channelName = "vetos/apps"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "listApps" -> {
                            val includeSystem =
                                call.argument<Boolean>("includeSystem") ?: true
                            result.success(listApps(includeSystem))
                        }
                        "isInstalled" -> {
                            val pkg = call.argument<String>("package") ?: ""
                            result.success(isInstalled(pkg))
                        }
                        "launch" -> {
                            val pkg = call.argument<String>("package") ?: ""
                            result.success(launchApp(pkg))
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("NATIVE_ERR", e.message, null)
                }
            }
    }

    private fun isInstalled(pkg: String): Boolean = try {
        packageManager.getPackageInfo(pkg, 0)
        true
    } catch (_: Exception) {
        false
    }

    private fun launchApp(pkg: String): Boolean = try {
        val intent = packageManager.getLaunchIntentForPackage(pkg)
        if (intent != null) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            true
        } else {
            false
        }
    } catch (_: Exception) {
        false
    }

    private fun listApps(includeSystem: Boolean): List<Map<String, Any?>> {
        val launcherIntent = Intent(Intent.ACTION_MAIN, null)
            .addCategory(Intent.CATEGORY_LAUNCHER)
        val infos = if (Build.VERSION.SDK_INT >= 33) {
            packageManager.queryIntentActivities(
                launcherIntent,
                PackageManager.ResolveInfoFlags.of(0)
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.queryIntentActivities(launcherIntent, 0)
        }

        val seen = HashSet<String>()
        val out = ArrayList<Map<String, Any?>>(infos.size)
        val pm = packageManager
        for (info in infos) {
            val pkg = info.activityInfo?.packageName ?: continue
            if (!seen.add(pkg)) continue
            try {
                val appInfo = pm.getApplicationInfo(pkg, 0)
                val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                if (isSystem && !includeSystem) continue
                val name = pm.getApplicationLabel(appInfo).toString()
                val iconBytes = drawableToPng(pm.getApplicationIcon(appInfo))
                out.add(
                    mapOf(
                        "package" to pkg,
                        "name" to name,
                        "system" to isSystem,
                        "icon" to iconBytes
                    )
                )
            } catch (_: Exception) {
                // приложение недоступно — пропускаем
            }
        }
        return out
    }

    private fun drawableToPng(d: Drawable?): ByteArray? {
        if (d == null) return null
        val bmp = if (d is BitmapDrawable && d.bitmap != null) {
            d.bitmap
        } else {
            val w = if (d.intrinsicWidth > 0) d.intrinsicWidth else 96
            val h = if (d.intrinsicHeight > 0) d.intrinsicHeight else 96
            val b = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            d.draw(Canvas(b))
            b
        }
        return try {
            val stream = ByteArrayOutputStream()
            bmp.compress(Bitmap.CompressFormat.PNG, 90, stream)
            stream.toByteArray()
        } catch (_: OutOfMemoryError) {
            null
        }
    }
}
