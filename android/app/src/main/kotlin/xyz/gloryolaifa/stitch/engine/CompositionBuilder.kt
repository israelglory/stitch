package xyz.gloryolaifa.stitch.engine

import android.net.Uri
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.util.GlUtil
import androidx.media3.common.util.Size
import androidx.media3.common.util.UnstableApi
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.EditedMediaItemSequence
import androidx.media3.transformer.Effects
import java.io.File
import kotlin.math.max
import kotlin.math.min

/**
 * Builds a Media3 [Composition] for an [EngineDocument]. Preview and export
 * use the same composition.
 *
 * Video is one sequence of clips back to back. A clip that ends in a
 * transition stops where the transition starts; the next clip's
 * [ClipEffect] draws the rest of it, mixed by the transition shader, from
 * frames it decodes itself. Each effect also fits or fills its clip, frames
 * it, and draws the background.
 *
 * Sound: each clip's own audio plays with its item, and fades in across an
 * incoming transition. The sound of a clip's part under a transition plays
 * from a second, audio-only sequence, fading out. Audio items get one
 * sequence each; loops are inserted repeatedly.
 */
@OptIn(UnstableApi::class)
object CompositionBuilder {
  data class Built(val composition: Composition, val durationUs: Long)

  /** [outputEffects] apply to the mixed result (export frame rate, resampling). */
  fun build(
    doc: EngineDocument,
    forExport: Boolean,
    outputSize: Size? = null,
    outputEffects: Effects = Effects.EMPTY,
  ): Built {
    val comp = doc.composition
    val size = outputSize ?: Size(doc.canvas.width, doc.canvas.height)
    val look = CanvasLook(size.width, size.height, doc.background)
    val clipsById = comp.clips.associateBy { it.clipId }
    val incoming = comp.transitions.associateBy { it.toClipId }
    val outgoing = comp.transitions.associateBy { it.fromClipId }
    val sequences = mutableListOf<EditedMediaItemSequence>()

    // Video, with each clip's own sound.
    if (comp.clips.isNotEmpty()) {
      val video = EditedMediaItemSequence.Builder(setOf(C.TRACK_TYPE_VIDEO, C.TRACK_TYPE_AUDIO))
      var cursor = 0L
      for (clip in comp.clips) {
        val start = max(cursor, clip.startUs)
        val end = outgoing[clip.clipId]?.startUs ?: clip.endUs
        if (clip.startUs > cursor) video.addGap(clip.startUs - cursor)
        if (end <= start) continue
        val into = incoming[clip.clipId]?.let { t ->
          clipsById[t.fromClipId]?.let { from -> incomingFor(doc, t, from, forExport) }
        }
        // A missing file plays as black silence.
        val item = clipItem(doc, clip, end, forExport, look, into)
        if (item == null) video.addGap(end - start) else video.addItem(item)
        cursor = end
      }
      if (cursor < comp.durationUs) video.addGap(comp.durationUs - cursor)
      sequences += video.build()
    }

    // The sound of each clip under the transition that leaves it.
    val tails = EditedMediaItemSequence.Builder(setOf(C.TRACK_TYPE_AUDIO))
    var tailCursor = 0L
    var hasTails = false
    for (t in comp.transitions.sortedBy { it.startUs }) {
      val clip = clipsById[t.fromClipId] ?: continue
      val media = doc.media[clip.mediaId] ?: continue
      val path = sourcePath(media, forExport) ?: continue
      if (clip.kind != "video" || !media.hasAudio || !hasAudioTrack(path)) continue
      if (t.startUs < tailCursor) continue
      if (t.startUs > tailCursor) tails.addGap(t.startUs - tailCursor)
      val sourceStart = clip.sourceInUs + ((t.startUs - clip.startUs) * clip.speed).toLong()
      tails.addItem(
        audioItem(
          path = path,
          mediaDurationUs = media.durationUs,
          sourceInUs = sourceStart,
          sourceOutUs = clip.sourceOutUs,
          speed = clip.speed,
          gain = Gain(
            volume = clip.volume.toFloat(),
            clipDurationUs = clip.endUs - clip.startUs,
            fadeInUs = clip.audioFadeInUs,
            fadeOutUs = clip.audioFadeOutUs,
            itemDurationUs = t.durationUs,
            offsetUs = t.startUs - clip.startUs,
            rampOutUs = t.durationUs,
          ),
        ),
      )
      tailCursor = t.startUs + t.durationUs
      hasTails = true
    }
    if (hasTails) sequences += tails.build()

    // Audio items, one sequence each.
    for (item in comp.audio) {
      val media = doc.media[item.mediaId] ?: continue
      if (!File(media.path).exists()) continue
      val builder = EditedMediaItemSequence.Builder(setOf(C.TRACK_TYPE_AUDIO))
      if (item.startUs > 0) builder.addGap(item.startUs)
      val passSourceUs = item.sourceOutUs - item.sourceInUs
      val passTimelineUs = (passSourceUs / item.speed).toLong()
      var t = item.startUs
      while (t < item.endUs && passTimelineUs > 0) {
        val segmentEnd = min(t + passTimelineUs, item.endUs)
        val sourceEnd = item.sourceInUs + ((segmentEnd - t) * item.speed).toLong()
        builder.addItem(
          audioItem(
            path = media.path,
            mediaDurationUs = media.durationUs,
            sourceInUs = item.sourceInUs,
            sourceOutUs = min(sourceEnd, item.sourceOutUs),
            speed = item.speed,
            gain = Gain(
              volume = item.volume.toFloat(),
              clipDurationUs = segmentEnd - t,
              fadeInUs = if (t == item.startUs) item.fadeInUs else 0,
              fadeOutUs = if (segmentEnd == item.endUs) item.fadeOutUs else 0,
            ),
          ),
        )
        if (!item.loop) break
        t = segmentEnd
      }
      sequences += builder.build()
    }

    if (sequences.isEmpty()) throw EngineException.badDocument("Nothing to play")

    val composition = Composition.Builder(sequences)
      .setEffects(outputEffects)
      .setHdrMode(hdrMode)
      .experimentalSetForceAudioTrack(true)
      .build()
    return Built(composition, comp.durationUs)
  }

  private val audioTracks = java.util.concurrent.ConcurrentHashMap<String, Boolean>()

  /**
   * Whether [path] has sound, read from the file once. An audio-only item
   * without sound fails the whole export, so the document's flag is not
   * trusted alone.
   */
  private fun hasAudioTrack(path: String): Boolean = audioTracks.getOrPut(path) {
    val extractor = android.media.MediaExtractor()
    try {
      extractor.setDataSource(path)
      (0 until extractor.trackCount).any {
        extractor.getTrackFormat(it).getString(android.media.MediaFormat.KEY_MIME)
          ?.startsWith("audio/") == true
      }
    } catch (_: Exception) {
      false
    } finally {
      extractor.release()
    }
  }

  /** The proxy for preview when there is one, else the original; null if missing. */
  private fun sourcePath(media: EngineDocument.Media, forExport: Boolean): String? {
    val path = if (!forExport && media.proxyPath != null && File(media.proxyPath).exists()) {
      media.proxyPath
    } else {
      media.path
    }
    return path.takeIf { File(it).exists() }
  }

  private fun incomingFor(
    doc: EngineDocument,
    t: EngineDocument.Transition,
    from: EngineDocument.Clip,
    forExport: Boolean,
  ): Incoming = Incoming(
    type = t.type,
    startUs = t.startUs,
    durationUs = t.durationUs,
    from = Outgoing(
      path = doc.media[from.mediaId]?.let { sourcePath(it, forExport) },
      kind = from.kind,
      sourceStartUs = from.sourceInUs + ((t.startUs - from.startUs) * from.speed).toLong(),
      speed = from.speed,
      framing = from.framing,
      timeoutMs = if (forExport) EXPORT_FRAME_TIMEOUT_MS else PREVIEW_FRAME_TIMEOUT_MS,
    ),
  )

  // Under Media3's 10 s export watchdog: a stuck decoder repeats the last
  // frame instead of failing the export.
  private const val EXPORT_FRAME_TIMEOUT_MS = 8_000L
  private const val PREVIEW_FRAME_TIMEOUT_MS = 3_000L

  /** [clip] up to [endUs] on the timeline, drawn by a [ClipEffect]. */
  private fun clipItem(
    doc: EngineDocument,
    clip: EngineDocument.Clip,
    endUs: Long,
    forExport: Boolean,
    look: CanvasLook,
    incoming: Incoming?,
  ): EditedMediaItem? {
    val media = doc.media[clip.mediaId] ?: return null
    val path = sourcePath(media, forExport) ?: return null
    val timelineUs = endUs - clip.startUs
    val effects = listOf(ClipEffect(look, clip.framing, incoming))

    if (clip.kind == "photo") {
      val item = MediaItem.Builder()
        .setUri(Uri.fromFile(File(path)))
        .setImageDurationMs(timelineUs / 1000)
        .build()
      return EditedMediaItem.Builder(item)
        .setDurationUs(timelineUs)
        .setFrameRate(doc.canvas.frameRate)
        .setEffects(Effects(listOf(), effects))
        .build()
    }

    val sourceOut = min(clip.sourceOutUs, clip.sourceInUs + (timelineUs * clip.speed).toLong())
    val item = MediaItem.Builder()
      .setUri(Uri.fromFile(File(path)))
      .setClippingConfiguration(
        MediaItem.ClippingConfiguration.Builder()
          .setStartPositionUs(clip.sourceInUs)
          .setEndPositionUs(sourceOut)
          .build(),
      )
      .build()
    val gain = Gain(
      volume = clip.volume.toFloat(),
      clipDurationUs = clip.endUs - clip.startUs,
      fadeInUs = clip.audioFadeInUs,
      fadeOutUs = clip.audioFadeOutUs,
      itemDurationUs = timelineUs,
      rampInUs = incoming?.durationUs ?: 0,
    )
    return EditedMediaItem.Builder(item)
      .setDurationUs(media.durationUs ?: clip.sourceOutUs)
      .apply { if (clip.speed != 1.0) setSpeed(ConstantSpeed(clip.speed.toFloat())) }
      .setEffects(Effects(listOf(GainProcessor(gain)), effects))
      .build()
  }

  private fun audioItem(
    path: String,
    mediaDurationUs: Long?,
    sourceInUs: Long,
    sourceOutUs: Long,
    speed: Double,
    gain: Gain,
  ): EditedMediaItem {
    val item = MediaItem.Builder()
      .setUri(Uri.fromFile(File(path)))
      .setClippingConfiguration(
        MediaItem.ClippingConfiguration.Builder()
          .setStartPositionUs(sourceInUs)
          .setEndPositionUs(sourceOutUs)
          .build(),
      )
      .build()
    return EditedMediaItem.Builder(item)
      .setDurationUs(mediaDurationUs ?: sourceOutUs)
      .apply { if (speed != 1.0) setSpeed(ConstantSpeed(speed.toFloat())) }
      .setEffects(Effects(listOf(GainProcessor(gain)), listOf()))
      .build()
  }

  /**
   * Tone maps HDR to SDR in OpenGL, which needs GL_EXT_YUV_target (on every
   * GPU that decodes HDR video, but missing on emulators). Without it, HDR is
   * read as SDR: washed out, but it plays and exports.
   */
  private val hdrMode by lazy {
    if (GlUtil.isYuvTargetExtensionSupported()) {
      Composition.HDR_MODE_TONE_MAP_HDR_TO_SDR_USING_OPEN_GL
    } else {
      Composition.HDR_MODE_EXPERIMENTAL_FORCE_INTERPRET_HDR_AS_SDR
    }
  }
}
