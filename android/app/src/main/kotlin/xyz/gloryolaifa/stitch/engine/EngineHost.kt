package xyz.gloryolaifa.stitch.engine

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.view.TextureRegistry
import java.util.UUID
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * Implements the Pigeon host API: owns the preview player and running
 * exports, and reports back through [EngineFlutterApi] on the main thread.
 * Mirrors EngineHost.swift.
 */
class EngineHost(
  private val context: Context,
  messenger: BinaryMessenger,
  private val textures: TextureRegistry,
) : EngineHostApi {
  private val callbacks = EngineFlutterApi(messenger)
  private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
  private var preview: PreviewPlayer? = null
  private var document: EngineDocument? = null
  private val jobs = mutableMapOf<String, Pair<EngineJob, Exporter.Listener>>()

  private fun player(): PreviewPlayer = preview ?: PreviewPlayer(context, textures) { state ->
    scope.launch { runCatching { callbacks.onPlaybackState(state) } }
  }.also { preview = it }

  override fun createPreview(): Long = player().textureId

  override fun setDocument(json: String) {
    val doc = try {
      EngineDocument.decode(json)
    } catch (e: Exception) {
      throw FlutterError("bad_document", e.message)
    }
    document = doc
    player().setDocument(doc)
  }

  override fun play() = player().play()

  override fun pause() = player().pause()

  override fun seek(positionUs: Long, exact: Boolean) = player().seek(positionUs, exact)

  override fun release() {
    preview?.release()
  }

  override suspend fun probe(path: String): MediaInfoMessage = bridged { MediaProbe.probe(path) }

  override suspend fun thumbnails(
    path: String,
    timesUs: List<Long>,
    maxSize: Long,
    outDir: String,
  ): List<String?> = Thumbnailer.thumbnails(path, timesUs, maxSize.toInt(), outDir)

  override suspend fun createProxy(path: String, outPath: String) =
    bridged { ProxyMaker.createProxy(context, path, outPath) }

  override fun capabilities(): CapabilitiesMessage = Exporter.capabilities()

  override suspend fun waveform(path: String, peaksPerSecond: Long): List<Double> =
    bridged { Waveform.peaks(path, peaksPerSecond.toInt()) }

  override fun setPreviewVolume(volume: Double) {
    preview?.setVolume(volume)
  }

  override fun startExport(request: ExportRequestMessage): String {
    val doc = document ?: throw FlutterError("bad_document", "No document to export")
    ExportService.start(context, request.progressTitle)
    return start(Exporter(context, doc, request), foreground = true)
  }

  override fun startSpeechAudio(documentJson: String, outputPath: String): String {
    val doc = try {
      EngineDocument.decode(documentJson)
    } catch (e: Exception) {
      throw FlutterError("bad_document", e.message)
    }
    return start(SpeechAudio(context, doc, outputPath))
  }

  /**
   * Runs [job], reporting through the export callbacks under a new id.
   * With [foreground], the export service shows its progress and stops
   * with it.
   */
  private fun start(job: EngineJob, foreground: Boolean = false): String {
    val jobId = UUID.randomUUID().toString()
    val listener = object : Exporter.Listener {
      override fun onProgress(fraction: Double) {
        if (foreground) ExportService.update(context, fraction)
        scope.launch { runCatching { callbacks.onExportProgress(jobId, fraction) } }
      }

      override fun onCompleted(path: String) {
        jobs.remove(jobId)
        if (foreground) ExportService.stop(context)
        scope.launch { runCatching { callbacks.onExportCompleted(jobId, path) } }
      }

      override fun onFailed(error: EngineException) {
        jobs.remove(jobId)
        if (foreground) ExportService.stop(context)
        scope.launch {
          runCatching { callbacks.onExportFailed(jobId, error.code, error.message ?: "") }
        }
      }
    }
    jobs[jobId] = job to listener
    // Start after returning the id, so Dart knows the job before any event.
    scope.launch {
      try {
        job.start(listener)
      } catch (e: Exception) {
        // Anything unexpected ends this job, not the app.
        Log.e(TAG, "Job failed to start", e)
        listener.onFailed(EngineException.exportFailed(e.message ?: "Could not start"))
      }
    }
    return jobId
  }

  override fun cancelExport(jobId: String) {
    val (job, listener) = jobs[jobId] ?: return
    job.cancel(listener)
  }

  fun dispose() {
    jobs.values.toList().forEach { (job, listener) -> job.cancel(listener) }
    preview?.dispose()
    preview = null
    scope.cancel()
  }

  private suspend fun <T> bridged(block: suspend () -> T): T = try {
    block()
  } catch (e: EngineException) {
    throw FlutterError(e.code, e.message)
  }

  companion object {
    private const val TAG = "StitchEngine"

    fun register(context: Context, engine: FlutterEngine): EngineHost {
      val messenger = engine.dartExecutor.binaryMessenger
      val host = EngineHost(context.applicationContext, messenger, engine.renderer)
      EngineHostApi.setUp(messenger, host)
      return host
    }
  }
}
