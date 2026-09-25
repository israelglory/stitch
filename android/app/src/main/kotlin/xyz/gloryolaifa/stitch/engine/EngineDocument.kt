package xyz.gloryolaifa.stitch.engine

import org.json.JSONArray
import org.json.JSONObject

/**
 * The document the Dart side sends: canvas, media files, and the timeline
 * flattened to absolute microseconds (Dart `ResolvedComposition`). Preview and
 * export are both built from this one value. Mirrors EngineDocument.swift.
 */
data class EngineDocument(
  val canvas: Canvas,
  val background: Background,
  val media: Map<String, Media>,
  val composition: Composition,
  /** Images placed on top of the video: text drawn by the Dart side. */
  val overlays: List<Overlay> = emptyList(),
  /** Numbers documents, so Dart can tell when the preview shows one. */
  val version: Int = 0,
) {
  /** How an overlay enters or leaves (see [TextMotion]). */
  data class Animation(val type: String, val durationUs: Long)

  data class Overlay(
    val id: String,
    val startUs: Long,
    val endUs: Long,
    /** One image, or a typewriter's frames from the first letter to all. */
    val images: List<String>,
    /** Size on the canvas at scale 1, in canvas pixels. */
    val width: Double,
    val height: Double,
    /** Center, as fractions of the canvas, y down. */
    val x: Double,
    val y: Double,
    val scale: Double,
    /** Clockwise. */
    val rotationDeg: Double,
    val animationIn: Animation,
    val animationOut: Animation,
  )

  data class Canvas(val width: Int, val height: Int, val frameRate: Int)

  /** [type] is "solid" or "blur"; [color] is ARGB for "solid". */
  data class Background(val type: String, val color: Long?)

  data class Media(
    val path: String,
    val kind: String,
    val proxyPath: String?,
    /** Full source length; null for photos. */
    val durationUs: Long?,
    val hasAudio: Boolean = true,
  )

  data class Framing(
    val mode: String,
    val scale: Double,
    val offsetX: Double,
    val offsetY: Double,
    val rotationDeg: Double,
  )

  data class Clip(
    val clipId: String,
    val mediaId: String,
    val kind: String,
    val startUs: Long,
    val endUs: Long,
    val sourceInUs: Long,
    val sourceOutUs: Long,
    val speed: Double,
    val volume: Double,
    val audioFadeInUs: Long,
    val audioFadeOutUs: Long,
    val framing: Framing,
  )

  data class Transition(
    val type: String,
    val fromClipId: String,
    val toClipId: String,
    val startUs: Long,
    val durationUs: Long,
  )

  data class Audio(
    val id: String,
    val mediaId: String,
    val startUs: Long,
    val endUs: Long,
    val sourceInUs: Long,
    val sourceOutUs: Long,
    val speed: Double,
    val loop: Boolean,
    val volume: Double,
    val fadeInUs: Long,
    val fadeOutUs: Long,
  )

  data class Composition(
    val durationUs: Long,
    val clips: List<Clip>,
    val transitions: List<Transition>,
    val audio: List<Audio>,
  )

  companion object {
    fun decode(json: String): EngineDocument {
      val root = JSONObject(json)
      val canvas = root.getJSONObject("canvas")
      val bg = root.getJSONObject("background")
      val media = root.getJSONObject("media")
      val comp = root.getJSONObject("composition")
      return EngineDocument(
        canvas = Canvas(canvas.getInt("width"), canvas.getInt("height"), canvas.getInt("frameRate")),
        background = Background(bg.getString("type"), if (bg.has("color")) bg.getLong("color") else null),
        media = media.keys().asSequence().associateWith { id ->
          val m = media.getJSONObject(id)
          Media(
            path = m.getString("path"),
            kind = m.getString("kind"),
            proxyPath = m.optString("proxyPath").ifEmpty { null },
            durationUs = if (m.has("durationUs")) m.getLong("durationUs") else null,
            hasAudio = m.optBoolean("hasAudio", true),
          )
        },
        composition = Composition(
          durationUs = comp.getLong("durationUs"),
          clips = comp.optJSONArray("clips").objects().map(::clip),
          transitions = comp.optJSONArray("transitions").objects().map {
            Transition(
              it.getString("type"), it.getString("fromClipId"), it.getString("toClipId"),
              it.getLong("startUs"), it.getLong("durationUs"),
            )
          },
          audio = comp.optJSONArray("audio").objects().map {
            Audio(
              it.getString("id"), it.getString("mediaId"), it.getLong("startUs"),
              it.getLong("endUs"), it.getLong("sourceInUs"), it.getLong("sourceOutUs"),
              it.getDouble("speed"), it.getBoolean("loop"), it.getDouble("volume"),
              it.getLong("fadeInUs"), it.getLong("fadeOutUs"),
            )
          },
        ),
        overlays = root.optJSONArray("overlays").objects().map(::overlay),
        version = root.optInt("version", 0),
      )
    }

    private fun overlay(o: JSONObject): Overlay {
      fun animation(a: JSONObject?) = Animation(
        a?.optString("type", "none") ?: "none",
        a?.optLong("durationUs", 0) ?: 0,
      )
      val images = o.getJSONArray("images")
      return Overlay(
        id = o.getString("id"),
        startUs = o.getLong("startUs"),
        endUs = o.getLong("endUs"),
        images = (0 until images.length()).map { images.getString(it) },
        width = o.getDouble("width"),
        height = o.getDouble("height"),
        x = o.getDouble("x"),
        y = o.getDouble("y"),
        scale = o.getDouble("scale"),
        rotationDeg = o.getDouble("rotationDeg"),
        animationIn = animation(o.optJSONObject("animationIn")),
        animationOut = animation(o.optJSONObject("animationOut")),
      )
    }

    private fun clip(o: JSONObject): Clip {
      val f = o.getJSONObject("framing")
      return Clip(
        clipId = o.getString("clipId"),
        mediaId = o.getString("mediaId"),
        kind = o.getString("kind"),
        startUs = o.getLong("startUs"),
        endUs = o.getLong("endUs"),
        sourceInUs = o.getLong("sourceInUs"),
        sourceOutUs = o.getLong("sourceOutUs"),
        speed = o.getDouble("speed"),
        volume = o.getDouble("volume"),
        audioFadeInUs = o.getLong("audioFadeInUs"),
        audioFadeOutUs = o.getLong("audioFadeOutUs"),
        framing = Framing(
          f.getString("mode"), f.getDouble("scale"), f.getDouble("offsetX"),
          f.getDouble("offsetY"), f.getDouble("rotationDeg"),
        ),
      )
    }

    private fun JSONArray?.objects(): List<JSONObject> =
      if (this == null) emptyList() else (0 until length()).map { getJSONObject(it) }
  }
}

/** Errors reported to Dart with a stable code. Same codes as iOS. */
class EngineException(val code: String, message: String) : Exception(message) {
  companion object {
    fun missingFile(path: String) = EngineException("missing_file", path)
    fun unsupported(path: String) = EngineException("unsupported_media", path)
    fun badDocument(message: String) = EngineException("bad_document", message)
    fun exportFailed(message: String) = EngineException("export_failed", message)
    fun cancelled() = EngineException("cancelled", "Cancelled")
  }
}
