package ir.psdkjoon.tasian

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import java.io.File
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

object EngineHolder {
    private const val NOTIFICATION_CHANNEL = "general"

    private lateinit var appContext: Context

    private var engine: FlutterEngine? = null
    private var tileChannel: MethodChannel? = null
    private var pendingToggle = false
    private var pendingInstall: File? = null
    private var notificationId = 100

    @Volatile
    var activity: MainActivity? = null

    fun ensure(context: Context): FlutterEngine {
        engine?.let { return it }
        appContext = context.applicationContext
        val created = FlutterEngine(appContext)
        setUpChannels(created)
        created.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault(),
        )
        engine = created
        return created
    }

    fun toggleFromTile(context: Context) {
        if (engine != null) {
            tileChannel?.invokeMethod("toggleRequested", null)
            return
        }
        pendingToggle = true
        ensure(context)
    }

    private fun setUpChannels(e: FlutterEngine) {
        val messenger = e.dartExecutor.binaryMessenger

        MethodChannel(messenger, "tasian/paths").setMethodCallHandler { call, result ->
            when (call.method) {
                "resolve" -> result.success(
                    mapOf(
                        "nativeLibraryDir" to appContext.applicationInfo.nativeLibraryDir,
                        "filesDir" to appContext.filesDir.absolutePath,
                    ),
                )
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "tasian/launcher_icon").setMethodCallHandler { call, result ->
            when (call.method) {
                "set" -> {
                    setLauncherIcon(call.argument<Boolean>("dark") ?: true)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "tasian/system").setMethodCallHandler { call, result ->
            when (call.method) {
                "openUrl" -> openUrl(call.argument<String>("url"), result)
                "installApk" -> installApk(call.argument<String>("path"), result)
                "abi" -> result.success(Build.SUPPORTED_ABIS.firstOrNull())
                "requestNotifications" -> {
                    requestNotifications()
                    result.success(null)
                }
                "notify" -> {
                    notify(
                        call.argument<String>("title") ?: "",
                        call.argument<String>("body") ?: "",
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "tasian/day_notification").setMethodCallHandler { call, result ->
            when (call.method) {
                "sync" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    val entries = call.argument<List<Map<String, String>>>("entries") ?: emptyList()
                    DayNotifier.sync(appContext, enabled, entries)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "tasian/reminders").setMethodCallHandler { call, result ->
            when (call.method) {
                "sync" -> {
                    val reminders = call.argument<List<Map<String, Any>>>("reminders") ?: emptyList()
                    Reminders.sync(appContext, reminders)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        val tile = MethodChannel(messenger, "tasian/tile")
        tileChannel = tile
        tile.setMethodCallHandler { call, result ->
            when (call.method) {
                "enable" -> {
                    setTileEnabled(true)
                    result.success(null)
                }
                "setState" -> {
                    QuickTileService.setState(
                        appContext,
                        call.argument<String>("state") ?: "off",
                    )
                    result.success(null)
                }
                "consumeToggle" -> {
                    val value = pendingToggle
                    pendingToggle = false
                    result.success(value)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openUrl(url: String?, result: MethodChannel.Result) {
        if (url == null) {
            result.error("bad_url", "No URL.", null)
            return
        }
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            appContext.startActivity(intent)
            result.success(null)
        } catch (e: Exception) {
            result.error("no_browser", "No app can open this link.", null)
        }
    }

    private fun canInstall(): Boolean =
        Build.VERSION.SDK_INT < 26 ||
            appContext.packageManager.canRequestPackageInstalls()

    private fun installApk(path: String?, result: MethodChannel.Result) {
        val file = path?.let { File(it) }
        if (file == null || !file.isFile) {
            result.error("no_file", "The update file is missing.", null)
            return
        }
        try {
            if (canInstall()) {
                pendingInstall = null
                launchInstaller(file)
                result.success("installing")
            } else {
                pendingInstall = file
                appContext.startActivity(
                    Intent(
                        Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                        Uri.parse("package:${appContext.packageName}"),
                    ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                )
                result.success("needs_permission")
            }
        } catch (e: Exception) {
            pendingInstall = null
            result.error("install_failed", e.message ?: "Could not start the installer.", null)
        }
    }

    fun installIfWaiting() {
        val file = pendingInstall ?: return
        pendingInstall = null
        if (!canInstall()) return
        try {
            launchInstaller(file)
        } catch (_: Exception) {
        }
    }

    private fun launchInstaller(file: File) {
        val uri = FileProvider.getUriForFile(appContext, "${appContext.packageName}.updates", file)
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, "application/vnd.android.package-archive")
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        appContext.startActivity(intent)
    }

    private fun requestNotifications() {
        if (Build.VERSION.SDK_INT < 33) return
        val host = activity ?: return
        if (host.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        host.requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 0)
    }

    private fun notify(title: String, body: String) {
        val manager = appContext.getSystemService(NotificationManager::class.java) ?: return
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(
                NotificationChannel(
                    NOTIFICATION_CHANNEL,
                    appContext.getString(R.string.notification_channel),
                    NotificationManager.IMPORTANCE_DEFAULT,
                ),
            )
        }
        val open = PendingIntent.getActivity(
            appContext,
            0,
            Intent(appContext, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val builder = if (Build.VERSION.SDK_INT >= 26) {
            Notification.Builder(appContext, NOTIFICATION_CHANNEL)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(appContext)
        }
        val notification = builder
            .setSmallIcon(R.drawable.ic_tile)
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(open)
            .setAutoCancel(true)
            .build()
        try {
            manager.notify(notificationId++, notification)
        } catch (_: SecurityException) {
        }
    }

    private fun setTileEnabled(enabled: Boolean) {
        appContext.packageManager.setComponentEnabledSetting(
            ComponentName(appContext, "ir.psdkjoon.tasian.QuickTileService"),
            if (enabled) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            },
            PackageManager.DONT_KILL_APP,
        )
    }

    private fun setLauncherIcon(dark: Boolean) {
        val pm = appContext.packageManager
        val mocha = ComponentName(appContext, "ir.psdkjoon.tasian.IconMocha")
        val latte = ComponentName(appContext, "ir.psdkjoon.tasian.IconLatte")
        val enable = if (dark) mocha else latte
        val disable = if (dark) latte else mocha
        pm.setComponentEnabledSetting(
            enable,
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP,
        )
        pm.setComponentEnabledSetting(
            disable,
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.DONT_KILL_APP,
        )
    }
}
