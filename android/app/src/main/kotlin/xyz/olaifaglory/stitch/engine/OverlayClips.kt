package xyz.olaifaglory.stitch.engine

import android.opengl.EGL14
import android.opengl.EGLContext
import androidx.annotation.OptIn
import androidx.media3.common.util.GlUtil
import androidx.media3.common.util.UnstableApi

/** An overlay clip with the file to read it from (null when missing). */
data class OverlayLayer(val clip: EngineDocument.OverlayClip, val path: String?)

/**
 * Frames of a composition's overlay clips, drawn by every clip's
 * [ClipEffect]. Media3 gives each clip its own effect, but an overlay
 * often runs across cuts, so its decoder lives here, for the whole
 * composition: it keeps playing through a cut instead of starting over.
 *
 * Decoders open shortly before their overlay shows and close once it has
 * ended. Used on the GL thread; [release] (from any thread) frees the
 * decoders when the composition is replaced or the export ends, and the
 * textures follow on the GL thread.
 */
class OverlayClipFrames(
  /** In drawing order. */
  val layers: List<OverlayLayer>,
  /** How long to wait for a frame; see [OutgoingFrames.open]. */
  private val timeoutMs: () -> Long,
  /** Report frames drawn without an overlay (preview), so a paused preview redraws. */
  private val reportMisses: Boolean,
) {
  private val open = HashMap<String, OutgoingFrames?>()
  private var context: EGLContext? = null
  private var released = false

  /**
   * The overlays showing at [timeUs] with their frames, in drawing order.
   * GL thread.
   */
  @Synchronized
  fun showing(timeUs: Long): List<Pair<OverlayLayer, SourceFrame>> {
    if (released) return emptyList()
    val current = EGL14.eglGetCurrentContext()
    if (current != context) {
      // A new GL context: the old one's textures went with it.
      open.values.forEach { it?.abandon() }
      open.clear()
      context = current
    }
    GlGarbage.drain(current)
    val result = mutableListOf<Pair<OverlayLayer, SourceFrame>>()
    for (layer in layers) {
      val clip = layer.clip
      val path = layer.path ?: continue
      when {
        timeUs >= clip.startUs && timeUs < clip.endUs -> {
          val frames = frames(clip, path)
          val sourceUs = clip.sourceInUs + ((timeUs - clip.startUs) * clip.speed).toLong()
          val frame = frames?.frameAt(sourceUs)
          if (frame != null) {
            result += layer to frame
          } else if (reportMisses) {
            FrameMisses.report()
          }
        }
        // Opened a little early, so the first frame is ready on time.
        timeUs < clip.startUs && clip.startUs - timeUs <= PREROLL_US && clip.kind == "video" ->
          frames(clip, path)
        timeUs >= clip.endUs || clip.startUs - timeUs > PREROLL_US ->
          open.remove(clip.id)?.release()
      }
    }
    return result
  }

  /** [clip]'s frames, opened on first use; a file that fails stays null. */
  private fun frames(clip: EngineDocument.OverlayClip, path: String): OutgoingFrames? =
    if (open.containsKey(clip.id)) {
      open[clip.id]
    } else {
      OutgoingFrames.open(path, clip.kind, timeoutMs).also { open[clip.id] = it }
    }

  /** Frees every decoder. Any thread; nothing is drawn afterwards. */
  @Synchronized
  fun release() {
    if (released) return
    released = true
    val ctx = context
    for (frames in open.values) {
      val textures = frames?.abandon() ?: continue
      if (ctx != null) GlGarbage.add(ctx, textures)
    }
    open.clear()
  }

  companion object {
    /** How far ahead of an overlay its decoder opens. */
    const val PREROLL_US = 500_000L
  }
}

/**
 * Textures freed off their GL thread, deleted the next time that thread
 * draws. Entries for contexts that never draw again are dropped once the
 * list grows: their textures went with the context.
 */
@OptIn(UnstableApi::class)
object GlGarbage {
  private val pending = ArrayList<Pair<EGLContext, IntArray>>()

  @Synchronized
  fun add(context: EGLContext, textures: IntArray) {
    pending += context to textures
    while (pending.size > MAX_PENDING) pending.removeAt(0)
  }

  /** Deletes what was freed in [context], the current one. GL thread. */
  @Synchronized
  fun drain(context: EGLContext) {
    if (pending.isEmpty()) return
    val iterator = pending.iterator()
    while (iterator.hasNext()) {
      val (ctx, textures) = iterator.next()
      if (ctx != context) continue
      textures.forEach { runCatching { GlUtil.deleteTexture(it) } }
      iterator.remove()
    }
  }

  private const val MAX_PENDING = 64
}
