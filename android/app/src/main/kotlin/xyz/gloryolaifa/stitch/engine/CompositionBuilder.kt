package xyz.gloryolaifa.stitch.engine

import android.net.Uri
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.Effect
import androidx.media3.common.MediaItem
import androidx.media3.common.OverlaySettings
import androidx.media3.common.VideoCompositorSettings
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.common.util.GlUtil
import androidx.media3.common.util.Size
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.Presentation
import androidx.media3.effect.StaticOverlaySettings
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.EditedMediaItemSequence
import androidx.media3.transformer.Effects
import java.io.File
import kotlin.math.abs
import kotlin.math.min

/**
 * Builds a Media3 [Composition] for an [EngineDocument], mirroring the iOS
 * CompositionBuilder.
 *
 * Clips alternate between two video sequences (A and B) with gaps between
 * them, so the clips on either side of a transition overlap. Each clip is
 * fitted or filled to the output size, framed, and made opaque over the
 * canvas background. The compositor shows only the sequences that have a
 * clip at each moment and mixes the two during transitions.
 *
 * Media3 draws the first sequence on top and times the output by it.
 *
 * Preview uses one video sequence instead, with each transition played as a
 * cut at its midpoint: CompositionPlayer stalls within a second when it
 * composites two video sequences (seen on the emulator with plain Media3
 * too). Export composites both and is verified frame by frame.
 *
 * Audio items get one sequence each; loops are inserted repeatedly.
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
    val sequences = mutableListOf<EditedMediaItemSequence>()

    // Video: sequences A and B for export, one cut sequence for preview.
    val slots = if (forExport) {
      List(2) { slot -> comp.clips.filterIndexed { i, _ -> i % 2 == slot } }
    } else {
      listOf(cutAtTransitions(comp))
    }
    for (clips in slots) {
      if (clips.isEmpty()) continue
      val builder = EditedMediaItemSequence.Builder(
        setOf(C.TRACK_TYPE_VIDEO, C.TRACK_TYPE_AUDIO),
      )
      var cursor = 0L
      for (clip in clips) {
        if (clip.startUs > cursor) builder.addGap(clip.startUs - cursor)
        // A missing file plays as black silence.
        val item = clipItem(doc, clip, forExport, size)
        if (item == null) builder.addGap(clip.endUs - clip.startUs) else builder.addItem(item)
        cursor = clip.endUs
      }
      if (cursor < comp.durationUs) builder.addGap(comp.durationUs - cursor)
      sequences += builder.build()
    }

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
        val segmentFirst = t == item.startUs
        val segmentLast = segmentEnd == item.endUs
        builder.addItem(
          audioItem(
            path = media.path,
            mediaDurationUs = media.durationUs,
            sourceInUs = item.sourceInUs,
            sourceOutUs = min(sourceEnd, item.sourceOutUs),
            speed = item.speed,
            gain = GainProcessor(
              volume = item.volume.toFloat(),
              durationUs = segmentEnd - t,
              fadeInUs = if (segmentFirst) item.fadeInUs else 0,
              fadeOutUs = if (segmentLast) item.fadeOutUs else 0,
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
      .apply {
        // With one video sequence Media3 skips the compositor, and rejects
        // compositor settings.
        if (slots.count { it.isNotEmpty() } == 2) setVideoCompositorSettings(Compositor(doc, slots, size))
      }
      .setEffects(outputEffects)
      .setHdrMode(hdrMode)
      .experimentalSetForceAudioTrack(true)
      .build()
    return Built(composition, comp.durationUs)
  }

  /**
   * The clips back to back, each trimmed so a transition becomes a cut at
   * its midpoint.
   */
  private fun cutAtTransitions(comp: EngineDocument.Composition): List<EngineDocument.Clip> {
    val cutIn = comp.transitions.associate { it.toClipId to it.startUs + it.durationUs / 2 }
    val cutOut = comp.transitions.associate { it.fromClipId to it.startUs + it.durationUs / 2 }
    return comp.clips.mapNotNull { clip ->
      val start = cutIn[clip.clipId] ?: clip.startUs
      val end = cutOut[clip.clipId] ?: clip.endUs
      if (end <= start) return@mapNotNull null
      clip.copy(
        startUs = start,
        endUs = end,
        sourceInUs = clip.sourceInUs + ((start - clip.startUs) * clip.speed).toLong(),
        sourceOutUs = clip.sourceOutUs - ((clip.endUs - end) * clip.speed).toLong(),
      )
    }
  }

  private fun clipItem(
    doc: EngineDocument,
    clip: EngineDocument.Clip,
    forExport: Boolean,
    size: Size,
  ): EditedMediaItem? {
    val media = doc.media[clip.mediaId]
    val timelineUs = clip.endUs - clip.startUs
    val path = media?.let {
      if (!forExport && it.proxyPath != null && File(it.proxyPath).exists()) it.proxyPath else it.path
    }
    val videoEffects = listOf<Effect>(
      Presentation.createForWidthAndHeight(
        size.width,
        size.height,
        if (clip.framing.mode == "fill") Presentation.LAYOUT_SCALE_TO_FIT_WITH_CROP
        else Presentation.LAYOUT_SCALE_TO_FIT,
      ),
      FramingTransformation(clip.framing, size.width, size.height),
      BackgroundFill(if (doc.background.type == "solid") doc.background.color ?: BLACK else BLACK),
    )

    if (path == null || !File(path).exists()) return null

    if (clip.kind == "photo") {
      val item = MediaItem.Builder()
        .setUri(Uri.fromFile(File(path)))
        .setImageDurationMs(timelineUs / 1000)
        .build()
      return EditedMediaItem.Builder(item)
        .setDurationUs(timelineUs)
        .setFrameRate(doc.canvas.frameRate)
        .setEffects(Effects(listOf(), videoEffects))
        .build()
    }

    val item = MediaItem.Builder()
      .setUri(Uri.fromFile(File(path)))
      .setClippingConfiguration(
        MediaItem.ClippingConfiguration.Builder()
          .setStartPositionUs(clip.sourceInUs)
          .setEndPositionUs(clip.sourceOutUs)
          .build(),
      )
      .build()
    val gain: AudioProcessor = GainProcessor(
      volume = clip.volume.toFloat(),
      durationUs = timelineUs,
      fadeInUs = clip.audioFadeInUs,
      fadeOutUs = clip.audioFadeOutUs,
    )
    return EditedMediaItem.Builder(item)
      .setDurationUs(media?.durationUs ?: clip.sourceOutUs)
      .apply { if (clip.speed != 1.0) setSpeed(ConstantSpeed(clip.speed.toFloat())) }
      .setEffects(Effects(listOf(gain), videoEffects))
      .build()
  }

  private fun audioItem(
    path: String,
    mediaDurationUs: Long?,
    sourceInUs: Long,
    sourceOutUs: Long,
    speed: Double,
    gain: GainProcessor,
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
      .setEffects(Effects(listOf(gain), listOf()))
      .build()
  }

  /**
   * Per frame, shows each video sequence only while it has a clip, and mixes
   * the two during a transition. Sequence 0 is on top.
   */
  private class Compositor(
    private val doc: EngineDocument,
    private val slots: List<List<EngineDocument.Clip>>,
    private val size: Size,
  ) : VideoCompositorSettings {
    private val videoSlots = slots.filter { it.isNotEmpty() }
    private val transitionsByTo = doc.composition.transitions.associateBy { it.toClipId }

    override fun getOutputSize(inputSizes: List<Size>): Size = size

    override fun getOverlaySettings(inputId: Int, presentationTimeUs: Long): OverlaySettings {
      val clips = videoSlots.getOrNull(inputId) ?: return hidden
      val t = presentationTimeUs
      val clip = clips.firstOrNull { t >= it.startUs && t < it.endUs } ?: return hidden

      // During a transition both sequences have a clip; mix them.
      val transition = transitionsByTo[clip.clipId]
        ?: doc.composition.transitions.firstOrNull { it.fromClipId == clip.clipId }
      if (transition != null && t >= transition.startUs &&
        t < transition.startUs + transition.durationUs
      ) {
        val p = (t - transition.startUs).toFloat() / transition.durationUs
        val incoming = transition.toClipId == clip.clipId
        val alpha = when (transition.type) {
          "fadeToBlack" -> {
            val dim = 1 - abs(p - 0.5f) * 2
            if ((p >= 0.5f) == incoming) dim else 0f
          }
          // Everything else crossfades until the shader transitions (M7).
          else -> if (inputId == 0) (if (incoming) p else 1 - p) else 1f
        }
        return overlay(alpha)
      }
      return overlay(1f)
    }

    private fun overlay(alpha: Float): OverlaySettings =
      StaticOverlaySettings.Builder()
        .setAlphaScale(alpha.coerceIn(0f, 1f))
        .setBackgroundFrameAnchor(0f, 0f)
        .setOverlayFrameAnchor(0f, 0f)
        .build()

    private val hidden = overlay(0f)
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

  private const val BLACK = 0xFF000000L
}
