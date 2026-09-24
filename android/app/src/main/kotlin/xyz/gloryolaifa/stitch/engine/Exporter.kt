package xyz.gloryolaifa.stitch.engine

import android.content.Context
import android.media.MediaCodecList
import android.media.MediaFormat
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.MimeTypes
import androidx.media3.common.audio.SonicAudioProcessor
import androidx.media3.common.util.Size
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.FrameDropEffect
import androidx.media3.transformer.AudioEncoderSettings
import androidx.media3.transformer.Composition
import androidx.media3.transformer.DefaultEncoderFactory
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.ProgressHolder
import androidx.media3.transformer.Transformer
import androidx.media3.transformer.VideoEncoderSettings
import java.io.File

/**
 * Renders a document to an MP4 with a Media3 [Transformer]. Mirrors
 * Exporter.swift: H.264 or HEVC at the requested bitrate, AAC 48 kHz at
 * 192 kbps, written to `*.part.mp4` and renamed when complete.
 *
 * Runs on the main looper; callbacks arrive there too.
 */
@OptIn(UnstableApi::class)
class Exporter(
  private val context: Context,
  private val doc: EngineDocument,
  private val request: ExportRequestMessage,
) {
  interface Listener {
    fun onProgress(fraction: Double)
    fun onCompleted(path: String)
    fun onFailed(error: EngineException)
  }

  private val handler = Handler(Looper.getMainLooper())
  private var transformer: Transformer? = null
  private var finished = false
  private val output = File(request.outputPath)
  private val temp = File(output.parentFile, output.nameWithoutExtension + ".part.mp4")

  fun start(listener: Listener) {
    val composition = try {
      val built = CompositionBuilder.build(
        doc,
        forExport = true,
        outputSize = Size(request.width.toInt(), request.height.toInt()),
        outputEffects = outputEffects(),
      )
      if (built.durationUs <= 0) throw EngineException.exportFailed("Nothing to export")
      built.composition
    } catch (e: EngineException) {
      finish(listener) { it.onFailed(e) }
      return
    }
    temp.delete()
    val t = Transformer.Builder(context)
      .setVideoMimeType(if (request.hevc) MimeTypes.VIDEO_H265 else MimeTypes.VIDEO_H264)
      .setAudioMimeType(MimeTypes.AUDIO_AAC)
      .setEncoderFactory(
        DefaultEncoderFactory.Builder(context)
          .setRequestedVideoEncoderSettings(
            VideoEncoderSettings.Builder().setBitrate(request.videoBitrate.toInt()).build(),
          )
          .setRequestedAudioEncoderSettings(
            AudioEncoderSettings.Builder().setBitrate(AUDIO_BITRATE).build(),
          )
          .build(),
      )
      .addListener(object : Transformer.Listener {
        override fun onCompleted(composition: Composition, exportResult: ExportResult) {
          if (!temp.renameTo(output)) {
            temp.delete()
            finish(listener) { it.onFailed(EngineException.exportFailed("Could not write output")) }
            return
          }
          finish(listener) {
            it.onProgress(1.0)
            it.onCompleted(output.path)
          }
        }

        override fun onError(
          composition: Composition,
          exportResult: ExportResult,
          exportException: ExportException,
        ) {
          Log.e(TAG, "Export failed", exportException)
          temp.delete()
          finish(listener) { it.onFailed(map(exportException)) }
        }
      })
      .build()
    transformer = t
    t.start(composition, temp.path)
    pollProgress(listener)
  }

  /** Stops the export and deletes the partial file; reports `cancelled`. */
  fun cancel(listener: Listener) {
    if (finished) return
    transformer?.cancel()
    temp.delete()
    finish(listener) { it.onFailed(EngineException.cancelled()) }
  }

  private fun pollProgress(listener: Listener) {
    val holder = ProgressHolder()
    var last = -1
    val poll = object : Runnable {
      override fun run() {
        val t = transformer ?: return
        if (finished) return
        if (t.getProgress(holder) == Transformer.PROGRESS_STATE_AVAILABLE &&
          holder.progress > last
        ) {
          // Percent steps, like iOS.
          last = holder.progress
          listener.onProgress(last / 100.0)
        }
        handler.postDelayed(this, PROGRESS_INTERVAL_MS)
      }
    }
    handler.post(poll)
  }

  private fun finish(listener: Listener, report: (Listener) -> Unit) {
    if (finished) return
    finished = true
    transformer = null
    report(listener)
  }

  /** Caps the frame rate and resamples the mix to 48 kHz. */
  private fun outputEffects(): Effects {
    val resample = SonicAudioProcessor().apply { setOutputSampleRateHz(AUDIO_SAMPLE_RATE) }
    return Effects(
      listOf(resample),
      listOf(FrameDropEffect.createDefaultFrameDropEffect(request.frameRate.toFloat())),
    )
  }

  private fun map(e: ExportException): EngineException = when (e.errorCode) {
    ExportException.ERROR_CODE_IO_FILE_NOT_FOUND -> EngineException.missingFile(e.message ?: "")
    ExportException.ERROR_CODE_DECODING_FORMAT_UNSUPPORTED,
    ExportException.ERROR_CODE_DECODER_INIT_FAILED,
    ExportException.ERROR_CODE_DECODING_FAILED,
    -> EngineException.unsupported(e.message ?: "")
    else -> EngineException.exportFailed("${e.errorCodeName}: ${e.message}")
  }

  companion object {
    private const val TAG = "StitchExport"
    private const val AUDIO_BITRATE = 192_000
    private const val AUDIO_SAMPLE_RATE = 48_000
    private const val PROGRESS_INTERVAL_MS = 100L

    /** HEVC and 4K support from the device's hardware encoders. */
    fun capabilities(): CapabilitiesMessage {
      val encoders = MediaCodecList(MediaCodecList.REGULAR_CODECS).codecInfos
        .filter { it.isEncoder }
      fun supports(mime: String, w: Int, h: Int): Boolean = encoders.any { info ->
        info.supportedTypes.any { it.equals(mime, ignoreCase = true) } &&
          runCatching {
            info.getCapabilitiesForType(mime).videoCapabilities
              .let { it.isSizeSupported(w, h) || it.isSizeSupported(h, w) }
          }.getOrDefault(false)
      }
      return CapabilitiesMessage(
        hevc = supports(MediaFormat.MIMETYPE_VIDEO_HEVC, 1920, 1080),
        max4k = supports(MediaFormat.MIMETYPE_VIDEO_AVC, 3840, 2160),
      )
    }
  }
}
