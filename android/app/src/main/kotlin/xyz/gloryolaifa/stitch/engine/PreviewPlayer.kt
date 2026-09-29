package xyz.gloryolaifa.stitch.engine

import android.content.Context
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.os.Process
import android.util.Log
import android.view.Surface
import androidx.annotation.OptIn
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.Size
import androidx.media3.common.util.UnstableApi
import androidx.media3.transformer.CompositionPlayer
import io.flutter.view.TextureRegistry
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
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
 * Called from the main thread; the player runs on its own thread. Media3
 * does its composition work on the thread that owns the player
 * (`setComposition` takes 25 to 40 ms on a mid-range phone), and Flutter
 * draws its UI on the main thread, so a player there made every edit drop
 * frames. Calls are posted to the player thread; for documents and seeks
 * only the newest waiting one is applied. The Flutter surface is only
 * touched on the main thread, which hands it to the player thread.
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

  private val thread = HandlerThread("StitchPreview", Process.THREAD_PRIORITY_DISPLAY).apply {
    start()
  }

  /** The player thread. Everything below [thread] is used on it only. */
  private val handler = Handler(thread.looper)
  private var player: CompositionPlayer? = null
  private var durationUs = 0L
  private var size = Size(1, 1)
  private var surfaceAttached = false

  /** The surface to draw into and its size, from the main thread. */
  private data class Target(val surface: Surface, val size: Size)

  /** Main thread only: the size last given to the producer. */
  private var producerSize: Size? = null

  /** The newest target, for players made or rebuilt on the player thread. */
  @Volatile private var target: Target? = null

  private data class DocumentRequest(val doc: EngineDocument, val target: Target)

  private val pendingDocument = AtomicReference<DocumentRequest?>(null)
  private val pendingSeek = AtomicReference<Pair<Long, Boolean>?>(null)

  private val ticker = object : Runnable {
    override fun run() {
      publish()
      if (player?.isPlaying == true) handler.postDelayed(this, TICK_MS)
    }
  }

  private val listener = object : Player.Listener {
    override fun onIsPlayingChanged(isPlaying: Boolean) {
      PreviewPlayback.playing = player?.playWhenReady == true
      handler.removeCallbacks(ticker)
      if (isPlaying) handler.post(ticker) else publish()
    }

    override fun onPlaybackStateChanged(playbackState: Int) {
      if (playbackState == Player.STATE_ENDED) player?.playWhenReady = false
      publish()
    }

    override fun onPlayerError(error: PlaybackException) {
      Log.e(TAG, "Preview failed", error)
      // CompositionPlayer (Media3 1.11.1) never clears an error: it stays
      // idle for good, whatever is prepared or set next. Only a new player
      // plays again (leaving and reopening the editor did that). Start
      // over at the same spot, paused; not from inside this callback.
      val at = player?.currentPosition ?: 0
      failed = true
      publish()
      handler.post { replaceFailedPlayer(at) }
    }

    override fun onRenderedFirstFrame() = markShown()
  }

  /** The last document set, to rebuild a player that failed. */
  private var document: EngineDocument? = null

  /** The player failed and is idle for good (see [Player.Listener.onPlayerError]). */
  private var failed = false

  /** Whether the current document was already given a new player. */
  private var rebuiltForDocument = false

  /**
   * Replaces a failed player with a new one showing the same document at
   * [atMs], paused. Once per document: if that one fails too (the
   * document itself cannot play, like a clip this device cannot decode),
   * it stays paused until the next document, which gets a new player.
   */
  private fun replaceFailedPlayer(atMs: Long) {
    if (!failed || rebuiltForDocument) return
    val doc = document ?: return
    val target = target ?: return
    rebuiltForDocument = true
    discardPlayer()
    apply(doc, target, positionMs = atMs)
  }

  private fun discardPlayer() {
    handler.removeCallbacks(ticker)
    player?.removeListener(listener)
    player?.release()
    player = null
    surfaceAttached = false
    failed = false
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

  /**
   * Redraws a paused frame that was drawn while a decoder was starting.
   * Only when paused by the user: while Play waits for buffering the
   * player is not playing either, and a seek then restarted the wait
   * (playback near a transition could keep not starting).
   */
  private val redraw = Runnable {
    val p = player ?: return@Runnable
    if (!p.playWhenReady && redrawsLeft > 0) {
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
        val next = Target(producer.surface, producerSize ?: return)
        target = next
        handler.post {
          player?.setVideoSurface(next.surface, next.size)
          surfaceAttached = player != null
        }
      }

      override fun onSurfaceCleanup() {
        // The surface goes when this returns: stop drawing into it first.
        runAndWait {
          player?.clearVideoSurface()
          surfaceAttached = false
        }
      }
    })
  }

  private val audioAttributes = AudioAttributes.Builder()
    .setUsage(C.USAGE_MEDIA)
    .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
    .build()

  private fun ensurePlayer(): CompositionPlayer = player ?: CompositionPlayer.Builder(context)
    .setLooper(thread.looper)
    .setAudioMixerFactory(LimitingAudioMixer.Factory())
    // Calls and other apps taking audio pause the preview.
    .setAudioAttributes(audioAttributes, handleAudioFocus)
    .build()
    .also {
      it.addListener(listener)
      if (level != 1f) applyVolume(it)
      player = it
    }

  /** Runs [block] on the player thread and waits for it, briefly. */
  private fun runAndWait(block: () -> Unit) {
    if (Looper.myLooper() == thread.looper) return block()
    val done = CountDownLatch(1)
    val posted = handler.post {
      try {
        block()
      } finally {
        done.countDown()
      }
    }
    if (posted) done.await(WAIT_MS, TimeUnit.MILLISECONDS)
  }

  /**
   * Replaces what is played, keeping the position and play state. Main
   * thread: sizes the Flutter surface, then hands the rest to the player
   * thread. Only the newest waiting document is built.
   */
  fun setDocument(doc: EngineDocument) {
    val previewSize = previewSize(doc.canvas)
    if (previewSize != producerSize) {
      producerSize = previewSize
      producer.setSize(previewSize.width, previewSize.height)
    }
    val next = Target(producer.surface, previewSize)
    target = next
    pendingDocument.set(DocumentRequest(doc, next))
    handler.post {
      pendingDocument.getAndSet(null)?.let { apply(it.doc, it.target) }
    }
  }

  /** Player thread: plays [doc] into [target]. */
  private fun apply(doc: EngineDocument, target: Target, positionMs: Long? = null) {
    if (doc !== document) rebuiltForDocument = false
    document = doc
    // A failed player cannot take a new document; a new one can.
    val keepFromFailed = if (failed) player?.currentPosition else null
    if (failed) discardPlayer()
    val built = try {
      CompositionBuilder.build(doc, forExport = false, outputSize = target.size)
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
    val keepMs = min(positionMs ?: keepFromFailed ?: p.currentPosition, built.durationUs / 1000)
    durationUs = built.durationUs
    if (target.size != size || !surfaceAttached) {
      size = target.size
      p.setVideoSurface(target.surface, size)
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
    handler.post(::playNow)
  }

  private fun playNow() {
    // Play is the way to try a failed document again: on a new player.
    if (failed) {
      val doc = document ?: return
      val target = target ?: return
      apply(doc, target, positionMs = player?.currentPosition)
    }
    val p = player ?: return
    p.isScrubbingModeEnabled = false
    if (p.currentPosition * 1000 >= durationUs - END_TOLERANCE_US) p.seekTo(0)
    PreviewPlayback.playing = true
    p.play()
    publish()
  }

  /** 0 to 1; muted while a voiceover records. */
  /**
   * Muted (while a voiceover records), the preview gives up audio focus:
   * taking it would end the recording, which holds focus itself.
   */
  fun setVolume(volume: Double) {
    val next = volume.toFloat().coerceIn(0f, 1f)
    handler.post {
      level = next
      player?.let(::applyVolume)
    }
  }

  /** Preview volume, kept for players made later. */
  private var level = 1f

  private fun applyVolume(p: CompositionPlayer) {
    p.volume = level
    p.setAudioAttributes(audioAttributes, handleAudioFocus && level > 0f)
  }

  fun pause() {
    PreviewPlayback.playing = false
    handler.post(::pauseNow)
  }

  private fun pauseNow() {
    PreviewPlayback.playing = false
    val p = player ?: return
    p.pause()
    // Video can trail the audio clock on slow devices; show the frame at the
    // position the playhead stopped on.
    p.isScrubbingModeEnabled = false
    p.seekTo(p.currentPosition)
    publish()
  }

  /** Only the newest waiting seek is made: scrubbing asks for many. */
  fun seek(us: Long, exact: Boolean) {
    pendingSeek.set(us to exact)
    handler.post {
      pendingSeek.getAndSet(null)?.let { (at, isExact) -> seekNow(at, isExact) }
    }
  }

  private fun seekNow(us: Long, exact: Boolean) {
    redrawsLeft = MAX_REDRAWS
    val p = player ?: return
    // Scrubbing mode coalesces rapid seeks and allows landing near the target.
    p.isScrubbingModeEnabled = !exact
    p.seekTo(max(0, min(us, durationUs)) / 1000)
    publish()
  }

  private fun publish() {
    val p = player
    val buffering = !failed && p?.playbackState == Player.STATE_BUFFERING
    onState(
      PlaybackStateMessage(
        positionUs = min((p?.currentPosition ?: 0) * 1000, durationUs),
        durationUs = durationUs,
        isPlaying = !failed && (p?.isPlaying == true || (p?.playWhenReady == true && buffering)),
        isBuffering = buffering,
        documentVersion = shownVersion,
      ),
    )
  }

  /** Stops playback and frees decoders. The texture stays usable. */
  fun release() {
    PreviewPlayback.playing = false
    pendingDocument.set(null)
    handler.post(::releaseNow)
  }

  private fun releaseNow() {
    PreviewPlayback.playing = false
    discardPlayer()
    document = null
    durationUs = 0
    publish()
  }

  fun dispose() {
    FrameMisses.listener = null
    pendingDocument.set(null)
    runAndWait {
      handler.removeCallbacksAndMessages(null)
      releaseNow()
    }
    thread.quitSafely()
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

    /** Longest the main thread waits for the player thread. */
    const val WAIT_MS = 2_000L
  }
}
