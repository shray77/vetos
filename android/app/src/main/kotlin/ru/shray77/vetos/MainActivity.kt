package ru.shray77.vetos

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.LinkedHashMap
import kotlin.concurrent.thread

/**
 * VetOS: нативный мост для лаунчера (вместо устаревших плагинов).
 *
 * Методы канала "vetos/apps":
 *  - listApps {includeSystem}  → список запускаемых приложений с иконками (PNG bytes)
 *  - isInstalled {package}     → установлен ли пакет
 *  - launch {package}          → запуск по package name (launch intent)
 *
 * ВАЖНО (v0.2.0): listApps — тяжёлая работа (query + binder + PNG-сжатие каждой
 * иконки). Раньше выполнялась в главном потоке → ANR при открытии дровера.
 * Теперь: рабочий поток + кэш иконок по пакету + даунскейл до 72px.
 */
class MainActivity : FlutterActivity() {

    private val channelName = "vetos/apps"
    private val mainHandler = Handler(Looper.getMainLooper())

    /**
     * PNG-иконки по пакету: повторное открытие дровера — мгновенное.
     *
     * LRU-семантика: после MAX_CACHE_ENTRIES новых пакетов старые
     * вытесняются — память не течёт на телефонах с кучей установленных
     * приложений (на 4 ГБ ОЗУ критично).
     */
    private val iconCache = object : LinkedHashMap<String, ByteArray>(64, 0.75f, true) {
        override fun removeEldestEntry(eldest: Map.Entry<String, ByteArray>?): Boolean {
            return size > MAX_CACHE_ENTRIES
        }
    }

    /**
     * Доступ к LRU-кэшу из разных потоков (listApps в рабочем потоке,
     * isInstalled может прийти из главного). Синхронизируем на самом кэше.
     */
    private val iconCacheLock = Any()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "listApps" -> {
                        val includeSystem =
                            call.argument<Boolean>("includeSystem") ?: true
                        // Главный поток не трогаем — только постим ответ.
                        thread(name = "vetos-list-apps") {
                            val apps = try {
                                listApps(includeSystem)
                            } catch (e: Exception) {
                                mainHandler.post {
                                    result.error("NATIVE_ERR", e.message, null)
                                }
                                return@thread
                            }
                            mainHandler.post { result.success(apps) }
                        }
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
                out.add(
                    mapOf(
                        "package" to pkg,
                        "name" to name,
                        "system" to isSystem,
                        "icon" to iconFor(pkg, appInfo)
                    )
                )
            } catch (_: Exception) {
                // приложение недоступно — пропускаем
            }
        }
        return out
    }

    /**
     * Иконка приложения WebP lossy с LRU-кэшем. null в кэше храним пустым
     * массивом (LinkedHashMap не принимает null-значения).
     *
     * WebP lossy q=80 вместо PNG: размер иконки ~2-4 КБ вместо ~6-10 КБ
     * (PNG без альфа-прозрачности и так большой), Flutter-сторона декодит
     * WebP быстрее — меньше GC-пауз на Helio G35.
     */
    private fun iconFor(pkg: String, appInfo: ApplicationInfo): ByteArray? {
        synchronized(iconCacheLock) {
            val cached = iconCache[pkg]
            if (cached != null) return if (cached.isNotEmpty()) cached else null
        }
        val bytes = try {
            drawableToWebp(packageManager.getApplicationIcon(appInfo))
        } catch (_: Exception) {
            null
        }
        synchronized(iconCacheLock) {
            iconCache[pkg] = bytes ?: ByteArray(0)
        }
        return bytes
    }

    private fun drawableToWebp(d: Drawable?): ByteArray? {
        if (d == null) return null
        val src = if (d is BitmapDrawable && d.bitmap != null) {
            d.bitmap
        } else {
            val w = if (d.intrinsicWidth > 0) d.intrinsicWidth else 96
            val h = if (d.intrinsicHeight > 0) d.intrinsicHeight else 96
            val b = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            d.draw(Canvas(b))
            b
        }
        if (src.width <= 0 || src.height <= 0) return null
        val bmp = downscale(src, ICON_PX)
        return try {
            val stream = ByteArrayOutputStream()
            // WebP lossy q=80: -50..70% размера относительно PNG,
            // декодируется Flutter-стороне быстрее.
            if (Build.VERSION.SDK_INT >= 30) {
                bmp.compress(Bitmap.CompressFormat.WEBP_LOSSY, 80, stream)
            } else {
                @Suppress("DEPRECATION")
                bmp.compress(Bitmap.CompressFormat.WEBP, 80, stream)
            }
            stream.toByteArray()
        } catch (_: OutOfMemoryError) {
            null
        }
    }

    /**
     * Дроверу хватает 44dp — иконки 72px: PNG-сжатие и канал в разы легче,
     * адаптивные иконки (до 432px) не убивают рабочий поток.
     */
    private fun downscale(b: Bitmap, maxPx: Int): Bitmap {
        val m = maxOf(b.width, b.height)
        if (m <= maxPx) return b
        val k = maxPx.toFloat() / m
        return Bitmap.createScaledBitmap(
            b,
            (b.width * k).toInt().coerceAtLeast(1),
            (b.height * k).toInt().coerceAtLeast(1),
            true
        )
    }

    companion object {
        private const val ICON_PX = 72
        /** LRU-лимит: на телефоне с 200+ приложениями не держим все иконки. */
        private const val MAX_CACHE_ENTRIES = 96
    }
}
