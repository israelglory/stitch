package xyz.gloryolaifa.stitch.engine

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.annotation.OptIn
import androidx.exifinterface.media.ExifInterface
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.Presentation
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import java.io.File
import java.io.FileOutputStream
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.math.max
import kotlin.math.roundToInt
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull

/**
 * Reads what a file contains: exact duration, display size after rotation,
 * frame rate, and whether it has sound or HDR video. Mirrors MediaProbe in
 * MediaTools.swift.
 */
object MediaProbe {
  suspend fun probe(path: String): MediaInfoMessage = withContext(Dispatchers.IO) {
    if (!File(path).exists()) throw EngineException.missingFile(path)
    probeImage(path)?.let { return@withContext it }

    val extractor = MediaExtractor()
    try {
      try {
        extractor.setDataSource(path)
      } catch (e: Exception) {
        throw EngineException.unsupported(path)
      }
      val formats = (0 until extractor.trackCount).map { extractor.getTrackFormat(it) }
      val video = formats.firstOrNull { it.mime().startsWith("video/") }
      val hasAudio = formats.any { it.mime().startsWith("audio/") }
      if (video == null && !hasAudio) throw EngineException.unsupported(path)

      val durationUs = formats.maxOf { it.longOr(MediaFormat.KEY_DURATION, 0) }
      var width = 0
      var height = 0
      var rotation = 0
      var fps = 0.0
      var hdr = false
      if (video != null) {
        rotation = video.intOr(MediaFormat.KEY_ROTATION, 0).let { ((it % 360) + 360) % 360 }
        val w = video.getInteger(MediaFormat.KEY_WIDTH)
        val h = video.getInteger(MediaFormat.KEY_HEIGHT)
        val swap = rotation == 90 || rotation == 270
        width = if (swap) h else w
        height = if (swap) w else h
        fps = frameRate(path, video, durationUs)
        val transfer = video.intOr(MediaFormat.KEY_COLOR_TRANSFER, 0)
        hdr = transfer == MediaFormat.COLOR_TRANSFER_ST2084 ||
          transfer == MediaFormat.COLOR_TRANSFER_HLG
      }
      MediaInfoMessage(
        durationUs = durationUs,
        width = width.toLong(),
        height = height.toLong(),
        rotationDeg = rotation.toLong(),
        frameRate = fps,
        hasVideo = video != null,
        hasAudio = hasAudio,
        isHdr = hdr,
      )
    } finally {
      extractor.release()
    }
  }

  /** The container's rate if stated, else the average over the file. */
  private fun frameRate(path: String, video: MediaFormat, durationUs: Long): Double {
    if (video.containsKey(MediaFormat.KEY_FRAME_RATE)) {
      runCatching { return video.getInteger(MediaFormat.KEY_FRAME_RATE).toDouble() }
      runCatching { return video.getFloat(MediaFormat.KEY_FRAME_RATE).toDouble() }
    }
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && durationUs > 0) {
      val retriever = MediaMetadataRetriever()
      try {
        retriever.setDataSource(path)
        val frames = retriever
          .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_FRAME_COUNT)
          ?.toLongOrNull()
        if (frames != null && frames > 0) return frames * 1_000_000.0 / durationUs
      } catch (_: Exception) {
      } finally {
        retriever.release()
      }
    }
    return 0.0
  }

  private fun probeImage(path: String): MediaInfoMessage? {
    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeFile(path, bounds)
    if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
    val swap = exifRotation(path) % 180 != 0
    return MediaInfoMessage(
      durationUs = null,
      width = (if (swap) bounds.outHeight else bounds.outWidth).toLong(),
      height = (if (swap) bounds.outWidth else bounds.outHeight).toLong(),
      rotationDeg = 0,
      frameRate = 0.0,
      hasVideo = true,
      hasAudio = false,
      isHdr = false,
    )
  }

  fun exifRotation(path: String): Int =
    runCatching { ExifInterface(path).rotationDegrees }.getOrDefault(0)

  private fun MediaFormat.mime(): String = getString(MediaFormat.KEY_MIME) ?: ""

  private fun MediaFormat.longOr(key: String, default: Long): Long =
    if (containsKey(key)) getLong(key) else default

  private fun MediaFormat.intOr(key: String, default: Int): Int =
    if (containsKey(key)) getInteger(key) else default
}

/** Frames for the timeline filmstrip, written as small JPEGs. */
object Thumbnailer {
  suspend fun thumbnails(
    path: String,
    timesUs: List<Long>,
    maxSize: Int,
    outDir: String,
  ): List<String?> = withContext(Dispatchers.IO) {
    File(outDir).mkdirs()
    val key = stableKey(path)

    // Stills: one frame for every requested time.
    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeFile(path, bounds)
    if (bounds.outWidth > 0) {
      val out = "$outDir/${key}_still_$maxSize.jpg"
      if (!File(out).exists()) {
        val image = decodeStill(path, bounds, maxSize) ?: return@withContext timesUs.map { null }
        if (!writeJpeg(image, out)) return@withContext timesUs.map { null }
      }
      return@withContext timesUs.map { out }
    }

    val retriever = MediaMetadataRetriever()
    try {
      retriever.setDataSource(path)
    } catch (_: Exception) {
      retriever.release()
      return@withContext timesUs.map { null }
    }
    try {
      timesUs.map { t ->
        val out = "$outDir/${key}_${t}_$maxSize.jpg"
        if (File(out).exists()) return@map out
        val frame = frameAt(retriever, t, maxSize) ?: return@map null
        if (writeJpeg(frame, out)) out else null
      }
    } finally {
      retriever.release()
    }
  }

  private fun frameAt(retriever: MediaMetadataRetriever, timeUs: Long, maxSize: Int): Bitmap? =
    try {
      val option = MediaMetadataRetriever.OPTION_CLOSEST
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
        retriever.getScaledFrameAtTime(timeUs, option, maxSize, maxSize)
      } else {
        retriever.getFrameAtTime(timeUs, option)?.let { scaleDown(it, maxSize) }
      }
    } catch (_: Exception) {
      null
    }

  private fun decodeStill(path: String, bounds: BitmapFactory.Options, maxSize: Int): Bitmap? {
    var sample = 1
    while (max(bounds.outWidth, bounds.outHeight) / (sample * 2) >= maxSize) sample *= 2
    val bitmap = BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })
      ?: return null
    val scaled = scaleDown(bitmap, maxSize)
    val rotation = MediaProbe.exifRotation(path)
    if (rotation == 0) return scaled
    val m = Matrix().apply { postRotate(rotation.toFloat()) }
    return Bitmap.createBitmap(scaled, 0, 0, scaled.width, scaled.height, m, true)
  }

  private fun scaleDown(bitmap: Bitmap, maxSize: Int): Bitmap {
    val long = max(bitmap.width, bitmap.height)
    if (long <= maxSize) return bitmap
    val s = maxSize.toFloat() / long
    return Bitmap.createScaledBitmap(
      bitmap,
      max(1, (bitmap.width * s).roundToInt()),
      max(1, (bitmap.height * s).roundToInt()),
      true,
    )
  }

  /** FNV-1a of the path, as on iOS, so cached frames are found again. */
  fun stableKey(s: String): String {
    var hash = 0xcbf29ce484222325uL
    for (byte in s.toByteArray(Charsets.UTF_8)) {
      hash = hash xor (byte.toUByte().toULong())
      hash *= 0x100000001b3uL
    }
    return hash.toString(36)
  }

  private fun writeJpeg(image: Bitmap, path: String): Boolean {
    val temp = File("$path.part")
    return try {
      FileOutputStream(temp).use { image.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, it) } &&
        temp.renameTo(File(path))
    } catch (_: Exception) {
      temp.delete()
      false
    }
  }

  private const val JPEG_QUALITY = 70
}

/**
 * A 720p copy for smooth preview of large or long-GOP sources. Export always
 * reads the original.
 */
@OptIn(UnstableApi::class)
object ProxyMaker {
  suspend fun createProxy(context: Context, path: String, outPath: String) {
    if (!File(path).exists()) throw EngineException.missingFile(path)
    val temp = File("$outPath.part.mp4")
    temp.delete()
    val item = EditedMediaItem.Builder(MediaItem.fromUri(Uri.fromFile(File(path))))
      .setEffects(Effects(listOf(), listOf(Presentation.createForShortSide(PROXY_SHORT_SIDE))))
      .build()
    // A proxy only speeds up preview, so import never waits on a stuck
    // encoder: past the limit it gives up and preview reads the original.
    val durationUs = MediaProbe.probe(path).durationUs ?: 0
    val limitMs = max(MIN_PROXY_TIMEOUT_MS, durationUs / 1000 * PROXY_TIMEOUT_FACTOR)
    val finished = withTimeoutOrNull(limitMs) { transform(context, item, temp) }
    if (finished == null) {
      temp.delete()
      throw EngineException.exportFailed("Proxy timed out after $limitMs ms")
    }
    val out = File(outPath)
    out.delete()
    if (!temp.renameTo(out)) {
      temp.delete()
      throw EngineException.exportFailed("Could not write proxy")
    }
  }

  private suspend fun transform(context: Context, item: EditedMediaItem, temp: File) {
    withContext(Dispatchers.Main) {
      suspendCancellableCoroutine { cont ->
        val transformer = Transformer.Builder(context)
          .setVideoMimeType(MimeTypes.VIDEO_H264)
          .setAudioMimeType(MimeTypes.AUDIO_AAC)
          .addListener(object : Transformer.Listener {
            override fun onCompleted(composition: Composition, exportResult: ExportResult) {
              cont.resume(Unit)
            }

            override fun onError(
              composition: Composition,
              exportResult: ExportResult,
              exportException: ExportException,
            ) {
              cont.resumeWithException(
                EngineException.exportFailed(exportException.message ?: "Proxy failed"),
              )
            }
          })
          .build()
        // Transformer must be used on the thread that built it.
        cont.invokeOnCancellation { Handler(Looper.getMainLooper()).post { transformer.cancel() } }
        transformer.start(item, temp.path)
      }
    }
  }

  private const val PROXY_SHORT_SIDE = 720
  private const val MIN_PROXY_TIMEOUT_MS = 30_000L
  private const val PROXY_TIMEOUT_FACTOR = 3
}
