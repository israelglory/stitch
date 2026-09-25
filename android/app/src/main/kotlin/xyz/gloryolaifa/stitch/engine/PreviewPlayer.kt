package xyz.gloryolaifa.stitch.engine

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.Size
import androidx.media3.common.util.UnstableApi
import androidx.media3.transformer.CompositionPlayer
import io.flutter.view.TextureRegistry
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * Plays the document into a Flutter texture through a Media3
 * [CompositionPlayer]. Mirrors PreviewPlayer.swift.
 *
 * The composition has one video sequence (see [CompositionBuilder]), so the
 * player's default single-input graph renders it.
 *
 * The preview renders at most [MAX_PREVIEW_SIDE] pixels on the long side;
 * the texture is scaled on screen. Scrubbing seeks use the player's
 * scrubbing mode, which drops stale seeks while a frame is being decoded.
 *
 * Used from the main thread only.
 */
@OptIn(UnstableApi::class)
class PreviewPlayer(
  private val context: Context,
  textures: TextureRegistry,
  /** Off in tests, whose process is in the background and denied focus. */
  private val handleAudioFocus: Boolean = true,
  private val onState: (PlaybackStateMessage) -> Unit,
) {
  private val producer = textures.createSurfaceProducer()
  val textureId: Long get() = producer.id()

  private val handler = Handler(Looper.getMainLooper())
  private var player: CompositionPlayer? = null
  private var durationUs = 0L
  private var size = Size(1, 1)
  private var surfaceAttached = false

  private val ticker = object : Runnable {
    override fun run() {
      publish()
      if (player?.isPlaying == true) handler.postDelayed(this, TICK_MS)
    }
  }

  private val listener = object : Player.Listener {
    override fun onIsPlayingChanged(isPlaying: Boolean) {
      handler.removeCallbacks(ticker)
      if (isPlaying) handler.post(ticker) else publish()
    }

    override fun onPlaybackStateChanged(playbackState: Int) {
      if (playbackState == Player.STATE_ENDED) player?.playWhenReady = false
      publish()
    }

    override fun onPlayerError(error: PlaybackException) {
      Log.e(TAG, "Preview failed", error)
      publish()
    }

    override fun onRenderedFirstFrame() = markShown()
  }

  /** Version of the document on screen (see `EngineDocument.version`). */
  private var shownVersion = 0L
  private var pendingVersion = 0L

  /**
   * The new document is on screen. Also run on a timer, in case no frame
   * comes (an audio-only document).
   */
  private val markShown: () -> Unit = {
    handler.removeCallbacks(markShownLater)
    if (shownVersion != pendingVersion) {
      shownVersion = pendingVersion
      publish()
    }
  }
  private val markShownLater = Runnable { markShown() }

  /** Redraws left for the current position after missed transition frames. */
  private var redrawsLeft = MAX_REDRAWS

  /** Redraws a paused frame that was drawn while a decoder was starting. */
  private val redraw = Runnable {
    val p = player ?: return@Runnable
    if (!p.isPlaying && redrawsLeft > 0) {
      redrawsLeft--
      p.seekTo(p.currentPosition)
    }
  }

  init {
    FrameMisses.listener = {
      handler.removeCallbacks(redraw)
      handler.postDelayed(redraw, REDRAW_DELAY_MS)
    }
    producer.setCallback(object : TextureRegistry.SurfaceProducer.Callback {
      override fun onSurfaceAvailable() {
        player?.setVideoSurface(producer.surface, size)
      }

      override fun onSurfaceCleanup() {
        player?.clearVideoSurface()
      }
    })
  }

  private val audioAttributes = AudioAttributes.Builder()
    .setUsage(C.USAGE_MEDIA)
    .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
    .build()

  private fun ensurePlayer(): CompositionPlayer = player ?: CompositionPlayer.Builder(context)
    .setAudioMixerFactory(LimitingAudioMixer.Factory())
    // Calls and other apps taking audio pause the preview.
    .setAudioAttributes(audioAttributes, handleAudioFocus)
    .build()
    .also {
      it.addListener(listener)
      player = it
    }

  /** Replaces what is played, keeping the position and play state. */
  fun setDocument(doc: EngineDocument) {
    val previewSize = previewSize(doc.canvas)
    val built = try {
      CompositionBuilder.build(doc, forExport = false, outputSize = previewSize)
    } catch (e: Exception) {
      Log.e(TAG, "Preview build failed", e)
      // Nothing left to play (the last clip went): stop showing the old
      // composition, and count this document as shown.
      player?.let {
        it.pause()
        it.clearVideoSurface()
      }
      surfaceAttached = false
      durationUs = 0
      shownVersion = doc.version.toLong()
      pendingVersion = shownVersion
      publish()
      return
    }
    val p = ensurePlayer()
    val keepMs = min(p.currentPosition, built.durationUs / 1000)
    durationUs = built.durationUs
    if (previewSize != size || !surfaceAttached) {
      size = previewSize
      producer.setSize(size.width, size.height)
      p.setVideoSurface(producer.surface, size)
      surfaceAttached = true
    }
    pendingVersion = doc.version.toLong()
    redrawsLeft = MAX_REDRAWS
    p.setComposition(built.composition, max(0, keepMs))
    handler.removeCallbacks(markShownLater)
    handler.postDelayed(markShownLater, SHOWN_FALLBACK_MS)
    if (p.playbackState == Player.STATE_IDLE) p.prepare()
    publish()
  }

  fun play() {
    val p = player ?: return
    p.isScrubbingModeEnabled = false
    if (p.currentPosition * 1000 >= durationUs - END_TOLERANCE_US) p.seekTo(0)
    p.play()
    publish()
  }

  /** 0 to 1; muted while a voiceover records. */
  /**
   * Muted (while a voiceover records), the preview gives up audio focus:
   * taking it would end the recording, which holds focus itself.
   */
  fun setVolume(volume: Double) {
    val p = player ?: return
    val level = volume.toFloat().coerceIn(0f, 1f)
    p.volume = level
    p.setAudioAttributes(audioAttributes, handleAudioFocus && level > 0f)
  }

  fun pause() {
    val p = player ?: return
    p.pause()
    // Video can trail the audio clock on slow devices; show the frame at the
    // position the playhead stopped on.
    p.isScrubbingModeEnabled = false
    p.seekTo(p.currentPosition)
    publish()
  }

  fun seek(us: Long, exact: Boolean) {
    redrawsLeft = MAX_REDRAWS
    val p = player ?: return
    // Scrubbing mode coalesces rapid seeks and allows landing near the target.
    p.isScrubbingModeEnabled = !exact
    p.seekTo(max(0, min(us, durationUs)) / 1000)
    publish()
  }

  private fun publish() {
    val p = player
    val buffering = p?.playbackState == Player.STATE_BUFFERING
    onState(
      PlaybackStateMessage(
        positionUs = min((p?.currentPosition ?: 0) * 1000, durationUs),
        durationUs = durationUs,
        isPlaying = p?.isPlaying == true || (p?.playWhenReady == true && buffering),
        isBuffering = buffering,
        documentVersion = shownVersion,
      ),
    )
  }

  /** Stops playback and frees decoders. The texture stays usable. */
  fun release() {
    handler.removeCallbacks(ticker)
    player?.removeListener(listener)
    player?.release()
    player = null
    surfaceAttached = false
    durationUs = 0
    publish()
  }

  fun dispose() {
    FrameMisses.listener = null
    handler.removeCallbacks(redraw)
    release()
    producer.release()
  }

  private fun previewSize(canvas: EngineDocument.Canvas): Size {
    val scale = min(1.0, MAX_PREVIEW_SIDE.toDouble() / max(canvas.width, canvas.height))
    // Even sizes keep encoders and GL buffers happy.
    fun even(v: Int) = max(2, (v * scale / 2).roundToInt() * 2)
    return Size(even(canvas.width), even(canvas.height))
  }

  private companion object {
    const val TAG = "StitchPreview"
    const val TICK_MS = 33L
    const val END_TOLERANCE_US = 10_000L
    const val MAX_PREVIEW_SIDE = 1280
    const val SHOWN_FALLBACK_MS = 1_500L
    const val REDRAW_DELAY_MS = 500L
    const val MAX_REDRAWS = 5
  }
}
