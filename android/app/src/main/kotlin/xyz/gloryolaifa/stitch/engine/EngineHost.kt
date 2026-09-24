package xyz.gloryolaifa.stitch.engine

import android.content.Context
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
  private val exports = mutableMapOf<String, Pair<Exporter, Exporter.Listener>>()

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

  override fun startExport(request: ExportRequestMessage): String {
    val doc = document ?: throw FlutterError("bad_document", "No document to export")
    val jobId = UUID.randomUUID().toString()
    val exporter = Exporter(context, doc, request)
    val listener = object : Exporter.Listener {
      override fun onProgress(fraction: Double) {
        scope.launch { runCatching { callbacks.onExportProgress(jobId, fraction) } }
      }

      override fun onCompleted(path: String) {
        exports.remove(jobId)
        scope.launch { runCatching { callbacks.onExportCompleted(jobId, path) } }
      }

      override fun onFailed(error: EngineException) {
        exports.remove(jobId)
        scope.launch {
          runCatching { callbacks.onExportFailed(jobId, error.code, error.message ?: "") }
        }
      }
    }
    exports[jobId] = exporter to listener
    // Start after returning the id, so Dart knows the job before any event.
    scope.launch { exporter.start(listener) }
    return jobId
  }

  override fun cancelExport(jobId: String) {
    val (exporter, listener) = exports[jobId] ?: return
    exporter.cancel(listener)
  }

  fun dispose() {
    exports.values.toList().forEach { (exporter, listener) -> exporter.cancel(listener) }
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
    fun register(context: Context, engine: FlutterEngine): EngineHost {
      val messenger = engine.dartExecutor.binaryMessenger
      val host = EngineHost(context.applicationContext, messenger, engine.renderer)
      EngineHostApi.setUp(messenger, host)
      return host
    }
  }
}
