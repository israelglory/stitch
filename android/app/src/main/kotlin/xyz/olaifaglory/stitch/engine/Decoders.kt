package xyz.olaifaglory.stitch.engine

import android.content.Context
import android.graphics.BitmapFactory
import android.graphics.ColorSpace
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.media.MediaFormat
import android.os.Build
import androidx.annotation.OptIn
import androidx.media3.common.util.Clock
import androidx.media3.common.util.GlUtil
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSourceBitmapLoader
import androidx.media3.transformer.AssetLoader
import androidx.media3.transformer.DefaultAssetLoaderFactory
import androidx.media3.transformer.DefaultDecoderFactory
import com.google.common.util.concurrent.MoreExecutors
import java.util.concurrent.Executors

/**
 * Decoding for the jobs that read whole source files: export and preview
 * copies.
 *
 * Phones cannot decode everything in hardware. A mid-range phone refuses
 * 4K at 60 fps, for example. Android also ships software decoders, which
 * are slow but handle those files, so these jobs fall back to the next
 * decoder when one fails to start instead of failing the whole job.
 */
@OptIn(UnstableApi::class)
object Decoders {
  /** Media3's default asset loading, with decoder fallback on. */
  fun assetLoaderFactory(context: Context): AssetLoader.Factory {
    val decoders = DefaultDecoderFactory.Builder(context)
      .setEnableDecoderFallback(true)
      .build()
    // As Media3 builds its default: photos decoded in sRGB, capped in size.
    val options = BitmapFactory.Options().apply {
      inPreferredColorSpace = ColorSpace.get(ColorSpace.Named.SRGB)
    }
    val bitmaps = DataSourceBitmapLoader.Builder(context)
      .setExecutorService(MoreExecutors.listeningDecorator(Executors.newSingleThreadExecutor()))
      .setBitmapFactoryOptions(options)
      .setMaximumOutputDimension(GlUtil.MAX_BITMAP_DECODING_SIZE)
      .build()
    // A null media source factory keeps Media3's default one. (The
    // constructor taking a LogSessionId is avoided: that type is missing
    // before Android 12.)
    return DefaultAssetLoaderFactory(context, decoders, Clock.DEFAULT, null, bitmaps)
  }

  /**
   * Whether a hardware decoder can play [video] (a track format, before
   * rotation) at its size and frame rate. False means only a software
   * decoder can, much slower than real time.
   */
  fun hardwareCanDecode(video: MediaFormat, frameRate: Double): Boolean {
    val mime = video.getString(MediaFormat.KEY_MIME) ?: return true
    val width = video.getInteger(MediaFormat.KEY_WIDTH)
    val height = video.getInteger(MediaFormat.KEY_HEIGHT)
    val fps = if (frameRate > 0) frameRate else DEFAULT_FRAME_RATE
    return MediaCodecList(MediaCodecList.REGULAR_CODECS).codecInfos.any { info ->
      !info.isEncoder &&
        isHardware(info) &&
        info.supportedTypes.any { it.equals(mime, ignoreCase = true) } &&
        runCatching {
          info.getCapabilitiesForType(mime).videoCapabilities
            ?.areSizeAndRateSupported(width, height, fps) == true
        }.getOrDefault(false)
    }
  }

  private fun isHardware(info: MediaCodecInfo): Boolean =
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      info.isHardwareAccelerated
    } else {
      val name = info.name.lowercase()
      !name.startsWith("omx.google.") && !name.startsWith("c2.android.") &&
        !name.startsWith("c2.google.")
    }

  private const val DEFAULT_FRAME_RATE = 30.0
}
