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
    return START_NOT_STICKY
  }

  companion object {
    private const val ID = 0x5174
    private const val CHANNEL = "export"
    private var title = ""
    private var lastPercent = -1

    fun start(context: Context, progressTitle: String) {
      title = progressTitle
      lastPercent = -1
      ContextCompat.startForegroundService(context, Intent(context, ExportService::class.java))
    }

    /** Updates the notification, at most once per percent. */
    fun update(context: Context, fraction: Double) {
      val percent = (fraction * 100).toInt()
      if (percent == lastPercent || !canNotify(context)) return
      lastPercent = percent
      NotificationManagerCompat.from(context).notify(ID, notification(context, percent))
    }

    fun stop(context: Context) {
      context.stopService(Intent(context, ExportService::class.java))
    }

    private fun canNotify(context: Context): Boolean =
      Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
        ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) ==
        PackageManager.PERMISSION_GRANTED

    private fun notification(context: Context, percent: Int): Notification {
      val manager = context.getSystemService(NotificationManager::class.java)
      if (manager.getNotificationChannel(CHANNEL) == null) {
        manager.createNotificationChannel(
          NotificationChannel(CHANNEL, title, NotificationManager.IMPORTANCE_LOW),
        )
      }
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
