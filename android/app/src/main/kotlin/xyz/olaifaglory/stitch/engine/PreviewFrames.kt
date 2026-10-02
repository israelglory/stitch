package xyz.gloryolaifa.stitch.engine

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.os.Build
import java.io.ByteArrayOutputStream
import java.io.File
import kotlin.math.max
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Single frames of a file, for the preview while a trim handle is dragged:
 * the frame at the handle. Mirrors PreviewFrames in MediaTools.swift.
 *
 * Opening a file costs more than reading a frame, so the last one stays
 * open between calls and closes after [IDLE_MS] without one. Quick frames
 * are the nearest key frame, which decodes at once; exact ones decode up
 * to the time asked.
 */
@OptIn(ExperimentalCoroutinesApi::class)
object PreviewFrames {
  // A retriever is not thread-safe: one thread uses it.
  private val thread = Dispatchers.IO.limitedParallelism(1)
  private val scope = CoroutineScope(SupervisorJob() + thread)
  private var retriever: MediaMetadataRetriever? = null
  private var openPath: String? = null
  private var closer: Job? = null

  suspend fun frame(path: String, timeUs: Long, maxSize: Int, exact: Boolean): ByteArray? =
    withContext(thread) {
      closer?.cancel()
      closer = scope.launch {
        delay(IDLE_MS)
        close()
      }
      if (!File(path).exists()) return@withContext null
      val r = open(path) ?: return@withContext null
      val option = if (exact) {
        MediaMetadataRetriever.OPTION_CLOSEST
      } else {
        MediaMetadataRetriever.OPTION_CLOSEST_SYNC
      }
      val bitmap = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
          r.getScaledFrameAtTime(timeUs, option, maxSize, maxSize)
        } else {
          r.getFrameAtTime(timeUs, option)?.let { scaleDown(it, maxSize) }
        }
      } catch (_: Exception) {
        null
      } ?: return@withContext null
      try {
        ByteArrayOutputStream().use {
          bitmap.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, it)
          it.toByteArray()
        }
      } finally {
        bitmap.recycle()
      }
    }

  private fun open(path: String): MediaMetadataRetriever? {
    if (path == openPath) retriever?.let { return it }
    close()
    val r = MediaMetadataRetriever()
    return try {
      r.setDataSource(path)
      retriever = r
      openPath = path
      r
    } catch (_: Exception) {
      r.release()
      null
    }
  }

  private fun close() {
    runCatching { retriever?.release() }
    retriever = null
    openPath = null
  }

  private fun scaleDown(bitmap: Bitmap, maxSize: Int): Bitmap {
    val long = max(bitmap.width, bitmap.height)
    if (long <= maxSize) return bitmap
    val s = maxSize.toFloat() / long
    val scaled = Bitmap.createScaledBitmap(
      bitmap,
      max(1, (bitmap.width * s).toInt()),
      max(1, (bitmap.height * s).toInt()),
      true,
    )
    if (scaled !== bitmap) bitmap.recycle()
    return scaled
  }

  private const val IDLE_MS = 10_000L
  private const val JPEG_QUALITY = 85
}
