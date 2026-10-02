package xyz.gloryolaifa.stitch.engine

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.MimeTypes
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.common.audio.BaseAudioProcessor
import androidx.media3.common.audio.SonicAudioProcessor
import androidx.media3.common.util.UnstableApi
import androidx.media3.transformer.Composition
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.ProgressHolder
import androidx.media3.transformer.Transformer
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

/**
 * Renders a document's mixed sound for speech recognition: 16 kHz mono
 * float PCM, raw and little endian, at [outputPath]. Mirrors
 * SpeechAudio.swift.
 *
 * The sound alone goes through a [Transformer] (no video is decoded), and
 * [SpeechCapture] copies the mix on its way to the encoder. The encoded
 * file is thrown away. A document with no sound gives an empty file.
 */
@OptIn(UnstableApi::class)
class SpeechAudio(
  private val context: Context,
  private val doc: EngineDocument,
  private val outputPath: String,
) : EngineJob {
  private val handler = Handler(Looper.getMainLooper())
  private var transformer: Transformer? = null
  private var stream: OutputStream? = null
  private var finished = false
  private val output = File(outputPath)
  private val temp = File("$outputPath.part")
  private val encoded = File("$outputPath.m4a")

  override fun start(listener: Exporter.Listener) {
    temp.delete()
    val out = BufferedOutputStream(FileOutputStream(temp), 1 shl 16)
    stream = out
    val composition = try {
      CompositionBuilder.build(
        doc,
        forExport = true,
        audioOnly = true,
        outputEffects = Effects(
          listOf(
            SonicAudioProcessor().apply { setOutputSampleRateHz(SpeechCapture.INPUT_RATE) },
            SpeechCapture(out),
          ),
          listOf(),
        ),
      ).composition
    } catch (e: EngineException) {
      // Nothing that makes a sound: no speech.
      if (e.code == "bad_document") complete(listener) else fail(listener, e)
      return
    }
    val t = Transformer.Builder(context)
      .setAudioMixerFactory(LimitingAudioMixer.Factory())
      .setAudioMimeType(MimeTypes.AUDIO_AAC)
      .addListener(object : Transformer.Listener {
        override fun onCompleted(composition: Composition, exportResult: ExportResult) {
          encoded.delete()
          complete(listener)
        }

        override fun onError(
          composition: Composition,
          exportResult: ExportResult,
          exportException: ExportException,
        ) {
          Log.e(TAG, "Speech audio failed", exportException)
          encoded.delete()
          fail(listener, EngineException.exportFailed(exportException.message ?: ""))
        }
      })
      .build()
    transformer = t
    t.start(composition, encoded.path)
    pollProgress(listener)
  }

  override fun cancel(listener: Exporter.Listener) {
    if (finished) return
    transformer?.cancel()
    encoded.delete()
    fail(listener, EngineException.cancelled())
  }

  private fun complete(listener: Exporter.Listener) {
    if (finished) return
    val closed = runCatching { stream?.close() }.isSuccess
    if (!closed || !temp.renameTo(output)) {
      fail(listener, EngineException.exportFailed("Could not write output"))
      return
    }
    finished = true
    transformer = null
    listener.onProgress(1.0)
    listener.onCompleted(output.path)
  }

  private fun fail(listener: Exporter.Listener, error: EngineException) {
    if (finished) return
    finished = true
    transformer = null
    runCatching { stream?.close() }
    temp.delete()
    listener.onFailed(error)
  }

  private fun pollProgress(listener: Exporter.Listener) {
    val holder = ProgressHolder()
    var last = -1
    val poll = object : Runnable {
      override fun run() {
        val t = transformer ?: return
        if (finished) return
        if (t.getProgress(holder) == Transformer.PROGRESS_STATE_AVAILABLE &&
          holder.progress > last
        ) {
          last = holder.progress
          listener.onProgress(last / 100.0)
        }
        handler.postDelayed(this, PROGRESS_INTERVAL_MS)
      }
    }
    handler.post(poll)
  }

  private companion object {
    const val TAG = "StitchSpeech"
    const val PROGRESS_INTERVAL_MS = 100L
  }
}

/**
 * Passes 48 kHz PCM through unchanged, writing a 16 kHz mono float copy to
 * [out]: the channels averaged, low-pass filtered, and every third sample
 * kept.
 */
@OptIn(UnstableApi::class)
class SpeechCapture(private val out: OutputStream) : BaseAudioProcessor() {
  private val decimator = Decimator()
  private var bytes = ByteBuffer.allocate(0).order(ByteOrder.LITTLE_ENDIAN)

  override fun onConfigure(inputAudioFormat: AudioProcessor.AudioFormat): AudioProcessor.AudioFormat {
    if (inputAudioFormat.sampleRate != INPUT_RATE ||
      (inputAudioFormat.encoding != C.ENCODING_PCM_16BIT &&
        inputAudioFormat.encoding != C.ENCODING_PCM_FLOAT)
    ) {
      throw AudioProcessor.UnhandledAudioFormatException(inputAudioFormat)
    }
    return inputAudioFormat
  }

  override fun queueInput(inputBuffer: ByteBuffer) {
    val size = inputBuffer.remaining()
    if (size == 0) return
    val format = inputAudioFormat
    val channels = format.channelCount
    val float = format.encoding == C.ENCODING_PCM_FLOAT
    val frames = size / format.bytesPerFrame
    val view = inputBuffer.duplicate().order(ByteOrder.LITTLE_ENDIAN)
    val needed = (frames / Decimator.FACTOR + 1) * 4
    if (bytes.capacity() < needed) bytes = ByteBuffer.allocate(needed).order(ByteOrder.LITTLE_ENDIAN)
    bytes.clear()
    for (f in 0 until frames) {
      var sum = 0f
      for (c in 0 until channels) {
        sum += if (float) view.float else view.short / 32768f
      }
      decimator.push(sum / channels)?.let { bytes.putFloat(it) }
    }
    out.write(bytes.array(), 0, bytes.position())

    val output = replaceOutputBuffer(size)
    output.put(inputBuffer)
    output.flip()
  }

  companion object {
    const val INPUT_RATE = 48_000
  }
}

/**
 * 48 kHz to 16 kHz: a windowed-sinc low-pass at 7.2 kHz, then every third
 * sample. The delay (half the filter, 0.5 ms) is too small to matter for
 * captions.
 */
class Decimator {
  private val taps = FloatArray(TAPS) { i ->
    val n = i - (TAPS - 1) / 2.0
    val cutoff = CUTOFF_HZ / 48_000.0
    val sinc = if (n == 0.0) 2 * cutoff else sin(2 * PI * cutoff * n) / (PI * n)
    val window = 0.42 - 0.5 * cos(2 * PI * i / (TAPS - 1)) + 0.08 * cos(4 * PI * i / (TAPS - 1))
    (sinc * window).toFloat()
  }
  private val history = FloatArray(TAPS)
  private var position = 0
  private var phase = 0

  /** Adds a 48 kHz sample; returns a 16 kHz sample every third call. */
  fun push(sample: Float): Float? {
    history[position] = sample
    position = (position + 1) % TAPS
    phase = (phase + 1) % FACTOR
    if (phase != 0) return null
    var sum = 0f
    var i = position
    for (k in 0 until TAPS) {
      sum += taps[k] * history[i]
      i = (i + 1) % TAPS
    }
    return sum
  }

  companion object {
    const val FACTOR = 3
    private const val TAPS = 63
    private const val CUTOFF_HZ = 7_200.0
  }
}
