package xyz.gloryolaifa.stitch.engine

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import xyz.gloryolaifa.stitch.R

/**
 * Keeps the app running while it exports, with a progress notification,
 * so an export carries on when the user leaves the app. The export itself
 * runs in [Exporter]; this service only holds the process in the
 * foreground. Started and stopped by [EngineHost].
 */
class ExportService : Service() {
  override fun onBind(intent: Intent?): IBinder? = null

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    val notification = notification(this, 0)
    when {
      Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM ->
        startForeground(ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROCESSING)
      Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q ->
        startForeground(ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
      else -> startForeground(ID, notification)
    }
    started = true
    // Every export ended before the service got here (one failed at
    // once): it has shown itself as the system requires, and goes.
    if (exports == 0) stopSelf()
    return START_NOT_STICKY
  }

  /** Android 15's daily limit for media processing ran out. */
  override fun onTimeout(startId: Int, fgsType: Int) {
    stopSelf()
  }

  override fun onDestroy() {
    started = false
    super.onDestroy()
  }

  companion object {
    private const val TAG = "StitchExportService"
    private const val ID = 0x5174
    private const val CHANNEL = "export"
    private var title = ""
    private var lastPercent = -1

    /** Exports running; the service stays while there is one. */
    private var exports = 0

    /** Whether [onStartCommand] has run (only then may it be stopped). */
    private var started = false

    fun start(context: Context, progressTitle: String) {
      title = progressTitle
      lastPercent = -1
      exports += 1
      if (exports > 1) return
      try {
        ContextCompat.startForegroundService(context, Intent(context, ExportService::class.java))
      } catch (e: IllegalStateException) {
        // Started from the background (Android 12 and later refuse that):
        // the export still runs, without the notification.
        Log.w(TAG, "Export runs without its notification", e)
      }
    }

    /** Updates the notification, at most once per percent. */
    fun update(context: Context, fraction: Double) {
      val percent = (fraction * 100).toInt()
      if (percent == lastPercent || !canNotify(context)) return
      lastPercent = percent
      NotificationManagerCompat.from(context).notify(ID, notification(context, percent))
    }

    /**
     * One export ended. The service goes with the last one, but never
     * before it has started: stopping it earlier crashes the app.
     */
    fun stop(context: Context) {
      exports = maxOf(0, exports - 1)
      if (exports == 0 && started) {
        context.stopService(Intent(context, ExportService::class.java))
      }
    }

    private fun canNotify(context: Context): Boolean =
      Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
        ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) ==
        PackageManager.PERMISSION_GRANTED

    private fun notification(context: Context, percent: Int): Notification {
      // Created or renamed each time, so its name in the system settings
      // follows the app's language.
      context.getSystemService(NotificationManager::class.java).createNotificationChannel(
        NotificationChannel(CHANNEL, title, NotificationManager.IMPORTANCE_LOW),
      )
      val open = context.packageManager.getLaunchIntentForPackage(context.packageName)
      val tap = PendingIntent.getActivity(context, 0, open, PendingIntent.FLAG_IMMUTABLE)
      return NotificationCompat.Builder(context, CHANNEL)
        .setSmallIcon(R.drawable.ic_stat_export)
        .setContentTitle(title)
        .setContentText("$percent%")
        .setProgress(100, percent, false)
        .setOngoing(true)
        .setOnlyAlertOnce(true)
        .setContentIntent(tap)
        .build()
    }
  }
}
