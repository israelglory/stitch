package xyz.gloryolaifa.stitch.engine

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import androidx.annotation.OptIn
import androidx.media3.common.util.GlUtil
import androidx.media3.common.util.UnstableApi
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import kotlin.math.max
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Assume.assumeTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Engine tests against the media corpus in test_media/ (regenerate with
 * tool/make_test_media.sh), packaged as test assets. Mirrors
 * ios/RunnerTests/EngineTests.swift.
 */
@OptIn(UnstableApi::class)
@RunWith(AndroidJUnit4::class)
class EngineTests {
  private val context = InstrumentationRegistry.getInstrumentation().targetContext
  private lateinit var tempDir: File

  @Before
  fun setUp() {
    tempDir = File(context.cacheDir, "engine_tests_${System.nanoTime()}").apply { mkdirs() }
  }

  @After
  fun tearDown() {
    tempDir.deleteRecursively()
  }

  /** Copies a corpus file out of the test APK's assets, once per run. */
  private fun media(name: String): String {
    val out = File(context.cacheDir, "test_media/$name")
    if (!out.exists()) {
      out.parentFile!!.mkdirs()
      InstrumentationRegistry.getInstrumentation().context.assets.open(name).use { input ->
        out.outputStream().use { input.copyTo(it) }
      }
    }
    return out.path
  }

  // Probe

  @Test
  fun probeVariableFrameRateVideo() = runBlocking<Unit> {
    val info = MediaProbe.probe(media("vfr.mp4"))
    assertEquals(360L, info.width)
    assertEquals(640L, info.height)
    assertTrue(info.hasAudio)
    assertEquals(3.93, info.durationUs!! / 1e6, 0.1)
  }

  @Test
  fun probeRotatedVideoReportsDisplaySize() = runBlocking<Unit> {
    val info = MediaProbe.probe(media("rotated_portrait.mp4"))
    assertEquals("stored 640x360, displayed portrait", 360L, info.width)
    assertEquals(640L, info.height)
    assertTrue(info.rotationDeg == 90L || info.rotationDeg == 270L)
  }

  @Test
  fun probeHdrAndSilentAndStillAndAudio() = runBlocking<Unit> {
    assertTrue(MediaProbe.probe(media("hevc_hdr.mov")).isHdr)
    assertFalse(MediaProbe.probe(media("no_audio.mp4")).hasAudio)

    val still = MediaProbe.probe(media("still.jpg"))
    assertNull(still.durationUs)
    assertEquals(1200L, still.width)
    assertEquals(1600L, still.height)

    for (name in listOf("music.mp3", "audio_44k.m4a", "audio_48k.wav")) {
      val audio = MediaProbe.probe(media(name))
      assertFalse(name, audio.hasVideo)
      assertTrue(name, audio.hasAudio)
    }
  }

  @Test
  fun probeMissingFileThrows() = runBlocking<Unit> {
    try {
      MediaProbe.probe("/nope/missing.mp4")
      fail("expected an error")
    } catch (e: EngineException) {
      assertEquals("missing_file", e.code)
    }
  }

  // Composition

  private fun framing(mode: String) =
    """{"mode": "$mode", "scale": 1, "offsetX": 0, "offsetY": 0, "rotationDeg": 0}"""

  /** Two clips with a 0.5 s crossfade, a photo, and looping music. */
  private fun sampleDocument(background: String = "solid"): EngineDocument = EngineDocument.decode(
    """
    {
      "canvas": {"width": 360, "height": 640, "frameRate": 30},
      "background": {"type": "$background", "color": 4278190080},
      "media": {
        "a": {"path": "${media("vfr.mp4")}", "kind": "video", "durationUs": 3930000},
        "b": {"path": "${media("rotated_portrait.mp4")}", "kind": "video", "durationUs": 3000000},
        "p": {"path": "${media("still.jpg")}", "kind": "photo"},
        "m": {"path": "${media("music.mp3")}", "kind": "audio"}
      },
      "composition": {
        "durationUs": 6500000,
        "clips": [
          {"clipId": "c1", "mediaId": "a", "kind": "video", "startUs": 0,
           "endUs": 2000000, "sourceInUs": 0, "sourceOutUs": 2000000, "speed": 1,
           "volume": 1, "audioFadeInUs": 0, "audioFadeOutUs": 500000,
           "framing": ${framing("fit")}},
          {"clipId": "c2", "mediaId": "b", "kind": "video", "startUs": 1500000,
           "endUs": 3500000, "sourceInUs": 0, "sourceOutUs": 2000000, "speed": 1,
           "volume": 1, "audioFadeInUs": 500000, "audioFadeOutUs": 0,
           "framing": ${framing("fill")}},
          {"clipId": "c3", "mediaId": "p", "kind": "photo", "startUs": 3500000,
           "endUs": 6500000, "sourceInUs": 0, "sourceOutUs": 3000000, "speed": 1,
           "volume": 0, "audioFadeInUs": 0, "audioFadeOutUs": 0,
           "framing": ${framing("fit")}}
        ],
        "transitions": [
          {"type": "crossfade", "fromClipId": "c1", "toClipId": "c2",
           "startUs": 1500000, "durationUs": 500000}
        ],
        "audio": [
          {"id": "m1", "mediaId": "m", "startUs": 1000000, "endUs": 6500000,
           "sourceInUs": 0, "sourceOutUs": 2000000, "speed": 1, "loop": true,
           "volume": 0.8, "fadeInUs": 200000, "fadeOutUs": 500000}
        ]
      }
    }
    """,
  )

  private fun singleClip(
    mediaName: String,
    kind: String = "video",
    durationUs: Long,
    speed: Double = 1.0,
    sourceOutUs: Long = durationUs,
    color: Long = 4278190080,
    mode: String = "fit",
    canvas: Pair<Int, Int> = 360 to 640,
  ): EngineDocument {
    val mediaDuration = if (kind == "video") """, "durationUs": ${sourceOutUs + 1}""" else ""
    return EngineDocument.decode(
      """
      {"canvas": {"width": ${canvas.first}, "height": ${canvas.second}, "frameRate": 30},
       "background": {"type": "solid", "color": $color},
       "media": {"x": {"path": "${media(mediaName)}", "kind": "$kind"$mediaDuration}},
       "composition": {"durationUs": $durationUs, "clips": [
         {"clipId": "c", "mediaId": "x", "kind": "$kind", "startUs": 0, "endUs": $durationUs,
          "sourceInUs": 0, "sourceOutUs": $sourceOutUs, "speed": $speed, "volume": 1,
          "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": ${framing(mode)}}]}}
      """,
    )
  }

  @Test
  fun compositionIsOneVideoSequenceWithSoundUnderTransitions() {
    val built = CompositionBuilder.build(sampleDocument(), forExport = true)
    assertEquals(6_500_000L, built.durationUs)
    // Video, the first clip's sound under the crossfade, and the music.
    assertEquals(3, built.composition.sequences.size)
    val items = built.composition.sequences[0].editedMediaItems
    // Clip 1 stops where the crossfade starts; clip 2 draws the rest of it.
    assertEquals(
      listOf(1_500_000.0, 2_000_000.0, 3_000_000.0),
      items.map { it.presentationDurationUs.toDouble() },
    )
    val tail = built.composition.sequences[1].editedMediaItems
    assertEquals(1_500_000.0, tail[0].presentationDurationUs.toDouble(), 1_000.0)
    assertEquals(500_000.0, tail[1].presentationDurationUs.toDouble(), 1_000.0)
  }

  @Test
  fun gainPlacesClipFadesAndCrossfades() {
    // The part of a 2 s clip under a 0.5 s transition, with a 1 s fade out.
    val tail = Gain(
      volume = 1f,
      clipDurationUs = 2_000_000,
      fadeInUs = 0,
      fadeOutUs = 1_000_000,
      itemDurationUs = 500_000,
      offsetUs = 1_500_000,
      rampOutUs = 500_000,
    )
    assertEquals(0.5f, tail.at(0), 0.01f)
    // Halfway: clip fade at 0.25, crossfade at 0.5.
    assertEquals(0.125f, tail.at(250_000), 0.01f)
    assertEquals(0f, tail.at(500_000), 0.0f)
    val incoming = Gain(1f, 2_000_000, 0, 0, rampInUs = 500_000)
    assertEquals(0f, incoming.at(0), 0.0f)
    assertEquals(0.5f, incoming.at(250_000), 0.01f)
    assertEquals(1f, incoming.at(1_000_000), 0.0f)
  }

  // Export

  private suspend fun export(
    doc: EngineDocument,
    width: Long = 360,
    height: Long = 640,
    fps: Long = 30,
    hevc: Boolean = false,
    name: String = "out.mp4",
    onProgress: (Exporter, Exporter.Listener, Double) -> Unit = { _, _, _ -> },
  ): String {
    val out = File(tempDir, name).path
    val result = CompletableDeferred<String>()
    var last = 0.0
    withContext(Dispatchers.Main) {
      val exporter = Exporter(
        context,
        doc,
        ExportRequestMessage(out, width, height, fps, 2_000_000, hevc, "Exporting"),
      )
      exporter.start(object : Exporter.Listener {
        override fun onProgress(fraction: Double) {
          last = fraction
          onProgress(exporter, this, fraction)
        }

        override fun onCompleted(path: String) {
          result.complete(path)
        }

        override fun onFailed(error: EngineException) {
          result.completeExceptionally(error)
        }
      })
    }
    val path = withTimeout(EXPORT_TIMEOUT_MS) { result.await() }
    assertEquals(1.0, last, 0.0)
    assertFalse(File(tempDir, name.removeSuffix(".mp4") + ".part.mp4").exists())
    return path
  }

  @Test
  fun exportMatchesTheDocument() = runBlocking<Unit> {
    val out = export(sampleDocument())
    val info = MediaProbe.probe(out)
    assertEquals(6.5, info.durationUs!! / 1e6, 0.1)
    assertEquals(360L, info.width)
    assertEquals(640L, info.height)
    assertEquals(30.0, measuredFrameRate(out), 1.5)
    assertEquals("one mixed audio track", 1, trackCount(out, "audio/"))
  }

  @Test
  fun exportDrawsEveryClipAndHidesTheIdleSequence() = runBlocking<Unit> {
    val out = export(sampleDocument())
    // Clip 1 alone, the crossfade, clip 2 alone (sequence A is in a gap
    // and must not cover it), and the photo.
    for (seconds in listOf(0.5, 1.75, 2.75, 5.0)) {
      val frame = frameAt(out, (seconds * 1e6).toLong())
      assertTrue("frame at ${seconds}s is drawn", meanBrightness(frame) > 0.1)
    }
  }

  /** Clip 1 (vertical color bars) then clip 2 (horizontal bars), back to back. */
  private fun backToBack(): EngineDocument = EngineDocument.decode(
    """
    {"canvas": {"width": 360, "height": 640, "frameRate": 30},
     "background": {"type": "solid", "color": 4278190080},
     "media": {"a": {"path": "${media("large_1440p.mp4")}", "kind": "video", "durationUs": 1000000},
               "b": {"path": "${media("rotated_portrait.mp4")}", "kind": "video", "durationUs": 3000000}},
     "composition": {"durationUs": 4000000, "clips": [
       {"clipId": "c1", "mediaId": "a", "kind": "video", "startUs": 0, "endUs": 1000000,
        "sourceInUs": 0, "sourceOutUs": 1000000, "speed": 1, "volume": 1,
        "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": ${framing("fill")}},
       {"clipId": "c2", "mediaId": "b", "kind": "video", "startUs": 1000000, "endUs": 4000000,
        "sourceInUs": 0, "sourceOutUs": 3000000, "speed": 1, "volume": 1,
        "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": ${framing("fill")}}]}}
    """,
  )

  /**
   * Which clip a frame shows: clip 1 has vertical bars (red on the left,
   * cyan on the right); clip 2 has horizontal ones (cyan on top, red below).
   */
  private fun clipShown(frame: Bitmap): Int {
    fun redAt(x: Float, y: Float): Boolean {
      val p = frame.getPixel((frame.width * x).toInt(), (frame.height * y).toInt())
      return Color.red(p) > 150 && Color.green(p) < 100 && Color.blue(p) < 100
    }
    return when {
      redAt(0.05f, 0.5f) -> 1
      redAt(0.3f, 0.93f) || redAt(0.7f, 0.93f) -> 2
      else -> 0
    }
  }

  @Test
  fun exportShowsEachClipInItsRange() = runBlocking<Unit> {
    val out = export(backToBack())
    // Kept for inspection: adb shell run-as xyz.gloryolaifa.stitch ls cache/frames
    val frames = File(context.cacheDir, "frames").apply { mkdirs() }
    for (t in listOf(500_000L, 1_500_000L, 2_000_000L, 3_500_000L)) {
      File(frames, "back_to_back_$t.png").outputStream().use {
        frameAt(out, t).compress(Bitmap.CompressFormat.PNG, 100, it)
      }
    }
    assertEquals("at 0.5s", 1, clipShown(frameAt(out, 500_000)))
    assertEquals("at 2s", 2, clipShown(frameAt(out, 2_000_000)))
    assertEquals("at 3.5s", 2, clipShown(frameAt(out, 3_500_000)))
  }

  // Transitions

  /** A solid [color] image the size of the test canvas. */
  private fun solidPhoto(name: String, color: Int): String {
    val file = File(tempDir, "$name.png")
    val bitmap = Bitmap.createBitmap(360, 640, Bitmap.Config.ARGB_8888).apply { eraseColor(color) }
    file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
    return file.path
  }

  /**
   * Two clips of 2.4 s with a 1.2 s [type] transition from 1.2 s to 2.4 s.
   * [a] and [b] are media JSON entries.
   */
  private fun transitionDoc(
    type: String,
    a: String,
    b: String,
    kind: String,
    background: String = "solid",
  ): EngineDocument = EngineDocument.decode(
    """
    {"canvas": {"width": 360, "height": 640, "frameRate": 30},
     "background": {"type": "$background", "color": 4278190080},
     "media": {"a": $a, "b": $b},
     "composition": {"durationUs": 3600000, "clips": [
       {"clipId": "c1", "mediaId": "a", "kind": "$kind", "startUs": 0, "endUs": 2400000,
        "sourceInUs": 0, "sourceOutUs": 2400000, "speed": 1, "volume": 1,
        "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": ${framing("fit")}},
       {"clipId": "c2", "mediaId": "b", "kind": "$kind", "startUs": 1200000, "endUs": 3600000,
        "sourceInUs": 0, "sourceOutUs": 2400000, "speed": 1, "volume": 1,
        "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": ${framing("fit")}}],
      "transitions": [{"type": "$type", "fromClipId": "c1", "toClipId": "c2",
        "startUs": 1200000, "durationUs": 1200000}]}}
    """,
  )

  @Test
  fun transitionsMatchTheSharedTable() = runBlocking<Unit> {
    val red = solidPhoto("red", Color.RED)
    val blue = solidPhoto("blue", Color.BLUE)
    val table = org.json.JSONObject(
      InstrumentationRegistry.getInstrumentation().context.assets.open("transition_cases.json")
        .bufferedReader().readText(),
    ).getJSONArray("cases")
    val cases = (0 until table.length()).map { table.getJSONObject(it) }
    val failures = mutableListOf<String>()
    for ((type, typeCases) in cases.groupBy { it.getString("type") }) {
      val out = export(
        transitionDoc(type, """{"path": "$red", "kind": "photo"}""", """{"path": "$blue", "kind": "photo"}""", "photo"),
        name = "$type.mp4",
      )
      for ((progress, atProgress) in typeCases.groupBy { it.getDouble("progress") }) {
        val frame = frameAt(out, 1_200_000 + (progress * 1_200_000).toLong())
        for (case in atProgress) {
          val x = case.getDouble("x")
          val y = case.getDouble("y")
          // Frame rows run top down; the table's y runs bottom up.
          val pixel = frame.getPixel(
            (x * frame.width).toInt(),
            ((1 - y) * frame.height).toInt().coerceAtMost(frame.height - 1),
          )
          val r = Color.red(pixel) / 255.0
          val b = Color.blue(pixel) / 255.0
          val wantR = case.getDouble("from")
          val wantB = case.getDouble("to")
          if (kotlin.math.abs(r - wantR) > 0.12 || kotlin.math.abs(b - wantB) > 0.12) {
            failures += "$type p=$progress x=$x: red %.2f (want %.2f), blue %.2f (want %.2f)"
              .format(r, wantR, b, wantB)
          }
        }
      }
    }
    assertTrue(failures.joinToString("\n"), failures.isEmpty())
  }

  /** Clip 1 (vertical bars) slides out left while clip 2 (horizontal bars) slides in. */
  private fun videoSlide(proxy: String? = null): EngineDocument = EngineDocument.decode(
    """
    {"canvas": {"width": 360, "height": 640, "frameRate": 30},
     "background": {"type": "solid", "color": 4278190080},
     "media": {"a": {"path": "${media("large_1440p.mp4")}", "kind": "video", "durationUs": 1000000
                     ${proxy?.let { ", \"proxyPath\": \"$it\"" } ?: ""}},
               "b": {"path": "${media("rotated_portrait.mp4")}", "kind": "video", "durationUs": 3000000}},
     "composition": {"durationUs": 3600000, "clips": [
       {"clipId": "c1", "mediaId": "a", "kind": "video", "startUs": 0, "endUs": 1000000,
        "sourceInUs": 0, "sourceOutUs": 1000000, "speed": 1, "volume": 1,
        "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": ${framing("fill")}},
       {"clipId": "c2", "mediaId": "b", "kind": "video", "startUs": 600000, "endUs": 3600000,
        "sourceInUs": 0, "sourceOutUs": 3000000, "speed": 1, "volume": 1,
        "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": ${framing("fill")}}],
      "transitions": [{"type": "slideLeft", "fromClipId": "c1", "toClipId": "c2",
        "startUs": 600000, "durationUs": 400000}]}}
    """,
  )

  /**
   * Halfway through [videoSlide]: the left half shows clip 1's right half
   * (a magenta bar at 75 percent across), the right half clip 2's left half
   * (cyan along the top, red along the bottom).
   */
  private fun assertHalfwayThroughSlide(frame: Bitmap) {
    fun at(x: Float, y: Float) = frame.getPixel((frame.width * x).toInt(), (frame.height * y).toInt())
    val left = at(0.25f, 0.5f)
    assertTrue(
      "left half is clip 1's magenta: ${Integer.toHexString(left)}",
      Color.red(left) > 150 && Color.blue(left) > 150 && Color.green(left) < 100,
    )
    val topRight = at(0.75f, 0.05f)
    assertTrue(
      "top right is clip 2's cyan: ${Integer.toHexString(topRight)}",
      Color.red(topRight) < 100 && Color.green(topRight) > 150 && Color.blue(topRight) > 150,
    )
    val bottomRight = at(0.75f, 0.95f)
    assertTrue(
      "bottom right is clip 2's red: ${Integer.toHexString(bottomRight)}",
      Color.red(bottomRight) > 150 && Color.green(bottomRight) < 100,
    )
  }

  @Test
  fun videoTransitionDrawsBothClips() = runBlocking<Unit> {
    val out = export(videoSlide())
    assertHalfwayThroughSlide(frameAt(out, 800_000))
    // Before and after, one clip each.
    assertEquals(1, clipShown(frameAt(out, 300_000)))
    assertEquals(2, clipShown(frameAt(out, 2_000_000)))
  }

  @Test
  fun blurBackgroundFillsTheBars() = runBlocking<Unit> {
    // A 3:4 still fitted into 9:16 leaves bars above and below. The still is
    // green on top and blue below; blurred, the top bar is greenish.
    val file = File(tempDir, "halves.png")
    val bitmap = Bitmap.createBitmap(300, 400, Bitmap.Config.ARGB_8888)
    android.graphics.Canvas(bitmap).apply {
      drawColor(Color.BLUE)
      drawRect(0f, 0f, 300f, 200f, android.graphics.Paint().apply { color = Color.GREEN })
    }
    file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
    val doc = EngineDocument.decode(
      """
      {"canvas": {"width": 360, "height": 640, "frameRate": 30},
       "background": {"type": "blur"},
       "media": {"p": {"path": "${file.path}", "kind": "photo"}},
       "composition": {"durationUs": 1000000, "clips": [
         {"clipId": "c", "mediaId": "p", "kind": "photo", "startUs": 0, "endUs": 1000000,
          "sourceInUs": 0, "sourceOutUs": 1000000, "speed": 1, "volume": 0,
          "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": ${framing("fit")}}]}}
      """,
    )
    val frame = frameAt(export(doc), 500_000)
    val top = frame.getPixel(frame.width / 2, 10)
    val bottom = frame.getPixel(frame.width / 2, frame.height - 10)
    assertTrue("top bar is green: ${Integer.toHexString(top)}", Color.green(top) > 120 && Color.blue(top) < 100)
    assertTrue("bottom bar is blue: ${Integer.toHexString(bottom)}", Color.blue(bottom) > 120 && Color.green(bottom) < 100)
  }

  @Test
  fun previewShowsTransitions() = runBlocking<Unit> {
    // As in the app, preview reads a 720p proxy of the 1440p source.
    val proxy = File(tempDir, "proxy.mp4").path
    ProxyMaker.createProxy(context, media("large_1440p.mp4"), proxy)
    val textures = FakeTextures()
    val player = withContext(Dispatchers.Main) {
      PreviewPlayer(context, textures, handleAudioFocus = false) {}.apply { setDocument(videoSlide(proxy)) }
    }
    withContext(Dispatchers.Main) { player.seek(800_000, exact = true) }
    // The first outgoing frame needs its decoder started, which is slow on
    // emulators; wait for the frame at the target.
    var last: AssertionError? = null
    val start = System.currentTimeMillis()
    while (System.currentTimeMillis() - start < 20_000) {
      val frame = textures.latest
      if (frame != null) {
        try {
          assertHalfwayThroughSlide(frame)
          last = null
          break
        } catch (e: AssertionError) {
          last = e
        }
      }
      kotlinx.coroutines.delay(200)
    }
    withContext(Dispatchers.Main) { player.dispose() }
    last?.let { throw it }
    assertTrue("a frame was drawn", textures.latest != null)
  }

  // Sound

  @Test
  fun clipFadesShapeTheSound() = runBlocking<Unit> {
    val doc = EngineDocument.decode(
      """
      {"canvas": {"width": 360, "height": 640, "frameRate": 30},
       "background": {"type": "solid", "color": 4278190080},
       "media": {"a": {"path": "${media("vfr.mp4")}", "kind": "video", "durationUs": 3930000}},
       "composition": {"durationUs": 3000000, "clips": [
         {"clipId": "c", "mediaId": "a", "kind": "video", "startUs": 0, "endUs": 3000000,
          "sourceInUs": 0, "sourceOutUs": 3000000, "speed": 1, "volume": 1,
          "audioFadeInUs": 1000000, "audioFadeOutUs": 0, "framing": ${framing("fit")}}]}}
      """,
    )
    val out = export(doc)
    val fading = rms(out, 50_000, 250_000)
    val full = rms(out, 1_500_000, 2_500_000)
    assertTrue("fading $fading, full $full", fading < full * 0.35 && full > 0.02)
  }

  @Test
  fun soundCrossfadesUnderTransitions() = runBlocking<Unit> {
    // Clip 1 has sound, clip 2 has none: clip 1 fades out under the transition.
    val doc = EngineDocument.decode(
      """
      {"canvas": {"width": 360, "height": 640, "frameRate": 30},
       "background": {"type": "solid", "color": 4278190080},
       "media": {"a": {"path": "${media("vfr.mp4")}", "kind": "video", "durationUs": 3930000},
                 "b": {"path": "${media("no_audio.mp4")}", "kind": "video", "durationUs": 3000000,
                       "hasAudio": false}},
       "composition": {"durationUs": 3500000, "clips": [
         {"clipId": "c1", "mediaId": "a", "kind": "video", "startUs": 0, "endUs": 2000000,
          "sourceInUs": 0, "sourceOutUs": 2000000, "speed": 1, "volume": 1,
          "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": ${framing("fit")}},
         {"clipId": "c2", "mediaId": "b", "kind": "video", "startUs": 1000000, "endUs": 3500000,
          "sourceInUs": 0, "sourceOutUs": 2500000, "speed": 1, "volume": 1,
          "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": ${framing("fit")}}],
        "transitions": [{"type": "crossfade", "fromClipId": "c1", "toClipId": "c2",
          "startUs": 1000000, "durationUs": 1000000}]}}
      """,
    )
    val out = export(doc)
    val before = rms(out, 200_000, 900_000)
    val early = rms(out, 1_050_000, 1_300_000)
    val late = rms(out, 1_700_000, 1_950_000)
    val after = rms(out, 2_200_000, 3_300_000)
    val levels = "before $before, early $early, late $late, after $after"
    assertTrue(levels, early > before * 0.5)
    assertTrue(levels, late < early * 0.5)
    assertTrue(levels, after < before * 0.05)
  }

  @Test
  fun letterboxTakesTheBackgroundColor() = runBlocking<Unit> {
    // A 3:4 still fitted into 9:16 leaves bars above and below.
    val out = export(singleClip("still.jpg", kind = "photo", durationUs = 1_000_000, color = 0xFFFF0000))
    val frame = frameAt(out, 500_000)
    val bar = frame.getPixel(frame.width / 2, 4)
    assertTrue("bar is red: ${Integer.toHexString(bar)}", Color.red(bar) > 200 && Color.green(bar) < 60)
  }

  @Test
  fun exportAt60fpsAndDifferentSize() = runBlocking<Unit> {
    val out = export(sampleDocument(background = "blur"), width = 720, height = 1280, fps = 60)
    val info = MediaProbe.probe(out)
    assertEquals(720L, info.width)
    // Frames are capped at the requested rate, never duplicated: the
    // corpus is 30 fps, so the output stays at most 60.
    assertTrue(measuredFrameRate(out) <= 62)
  }

  @Test
  fun speedScalesTheSegment() = runBlocking<Unit> {
    val out = export(singleClip("vfr.mp4", durationUs = 1_000_000, speed = 2.0, sourceOutUs = 2_000_000))
    assertEquals(1.0, MediaProbe.probe(out).durationUs!! / 1e6, 0.1)
  }

  @Test
  fun hdrSourceExportsAsSdr() = runBlocking<Unit> {
    val out = try {
      export(singleClip("hevc_hdr.mov", durationUs = 2_000_000), width = 540, height = 960)
    } catch (e: EngineException) {
      // Emulators cannot take 10-bit video through GL; phones that play HDR
      // can. Without it the export must fail cleanly, as unsupported media.
      assertEquals("unsupported_media", e.code)
      assumeTrue("no 10-bit GL path on this device", GlUtil.isYuvTargetExtensionSupported())
      throw e
    }
    val format = videoFormat(out)
    val transfer =
      if (format.containsKey(MediaFormat.KEY_COLOR_TRANSFER)) format.getInteger(MediaFormat.KEY_COLOR_TRANSFER) else 0
    assertTrue(
      "transfer $transfer",
      transfer != MediaFormat.COLOR_TRANSFER_ST2084 && transfer != MediaFormat.COLOR_TRANSFER_HLG,
    )
    assertFalse(MediaProbe.probe(out).isHdr)
  }

  @Test
  fun photoOnlyProjectExports() = runBlocking<Unit> {
    val out = export(singleClip("still.jpg", kind = "photo", durationUs = 3_000_000, color = 4294967295))
    assertEquals(3.0, MediaProbe.probe(out).durationUs!! / 1e6, 0.1)
  }

  @Test
  fun missingFileExportsAsBlack() = runBlocking<Unit> {
    val doc = EngineDocument.decode(
      """
      {"canvas": {"width": 360, "height": 640, "frameRate": 30},
       "background": {"type": "solid", "color": 4278190080},
       "media": {"a": {"path": "${media("vfr.mp4")}", "kind": "video", "durationUs": 3930000},
                 "gone": {"path": "/nope/gone.mp4", "kind": "video", "durationUs": 2000000}},
       "composition": {"durationUs": 3000000, "clips": [
         {"clipId": "c1", "mediaId": "a", "kind": "video", "startUs": 0, "endUs": 1000000,
          "sourceInUs": 0, "sourceOutUs": 1000000, "speed": 1, "volume": 1,
          "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": ${framing("fit")}},
         {"clipId": "c2", "mediaId": "gone", "kind": "video", "startUs": 1000000, "endUs": 3000000,
          "sourceInUs": 0, "sourceOutUs": 2000000, "speed": 1, "volume": 1,
          "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": ${framing("fit")}}]}}
      """,
    )
    val out = export(doc)
    assertEquals(3.0, MediaProbe.probe(out).durationUs!! / 1e6, 0.1)
  }

  @Test
  fun cancelStopsAndLeavesNoFile() = runBlocking<Unit> {
    val doc = singleClip("long.mp4", durationUs = 60_000_000)
    try {
      export(doc, name = "cancel.mp4") { exporter, listener, fraction ->
        if (fraction > 0.05) exporter.cancel(listener)
      }
      fail("expected cancel")
    } catch (e: EngineException) {
      assertEquals("cancelled", e.code)
    }
    assertFalse(File(tempDir, "cancel.mp4").exists())
    assertFalse(File(tempDir, "cancel.part.mp4").exists())
  }

  /** Reported, not a gate: emulators are not representative devices. */
  @Test
  fun reportExportSpeedOneMinute1080p() = runBlocking<Unit> {
    val doc = singleClip("long.mp4", durationUs = 60_000_000, mode = "fill", canvas = 1080 to 1920)
    val start = System.nanoTime()
    export(doc, width = 1080, height = 1920)
    val seconds = (System.nanoTime() - start) / 1e9
    println("PERF export 60s 1080p30: ${"%.1f".format(seconds)}s")
    android.util.Log.i("StitchPerf", "export 60s 1080p30: ${"%.1f".format(seconds)}s")
  }

  // Preview

  /** A texture registry whose one surface is an ImageReader. */
  private class FakeTextures : io.flutter.view.TextureRegistry {
    /** The last frame drawn, as the screen would show it. */
    @Volatile var latest: Bitmap? = null

    val reader: android.media.ImageReader = android.media.ImageReader.newInstance(
      360,
      640,
      android.graphics.PixelFormat.RGBA_8888,
      4,
    ).apply {
      setOnImageAvailableListener(
        { r ->
          r.acquireLatestImage()?.use { image ->
            val plane = image.planes[0]
            val bitmap = Bitmap.createBitmap(
              plane.rowStride / plane.pixelStride,
              image.height,
              Bitmap.Config.ARGB_8888,
            )
            bitmap.copyPixelsFromBuffer(plane.buffer)
            latest = Bitmap.createBitmap(bitmap, 0, 0, image.width, image.height)
          }
        },
        android.os.Handler(android.os.Looper.getMainLooper()),
      )
    }

    override fun createSurfaceProducer(
      lifecycle: io.flutter.view.TextureRegistry.SurfaceLifecycle,
    ): io.flutter.view.TextureRegistry.SurfaceProducer =
      object : io.flutter.view.TextureRegistry.SurfaceProducer {
        override fun id(): Long = 1
        override fun release() = reader.close()
        override fun setSize(width: Int, height: Int) {}
        override fun getWidth(): Int = 360
        override fun getHeight(): Int = 640
        override fun getSurface(): android.view.Surface = reader.surface
        override fun getForcedNewSurface(): android.view.Surface = reader.surface
        override fun setCallback(callback: io.flutter.view.TextureRegistry.SurfaceProducer.Callback?) {}
        override fun scheduleFrame() {}
        override fun handlesCropAndRotation(): Boolean = false
      }

    override fun createSurfaceTexture() = throw UnsupportedOperationException()
    override fun registerSurfaceTexture(texture: android.graphics.SurfaceTexture) =
      throw UnsupportedOperationException()
    override fun createImageTexture() = throw UnsupportedOperationException()
  }

  /** Plays [doc] through [PreviewPlayer]; returns the last state seen while playing. */
  private suspend fun playPreview(
    doc: EngineDocument,
    textures: FakeTextures = FakeTextures(),
  ): PlaybackStateMessage? {
    var last: PlaybackStateMessage? = null
    val player = withContext(Dispatchers.Main) {
      PreviewPlayer(context, textures, handleAudioFocus = false) { last = it }.apply {
        setDocument(doc)
        play()
      }
    }
    val start = System.currentTimeMillis()
    while (last?.positionUs?.let { it < 1_500_000 } != false &&
      System.currentTimeMillis() - start < 20_000
    ) {
      kotlinx.coroutines.delay(100)
    }
    val reached = last
    withContext(Dispatchers.Main) { player.dispose() }
    return reached
  }

  @Test
  fun previewPlayerPlaysBackToBackClips() = runBlocking<Unit> {
    val doc = EngineDocument.decode(
      """
      {"canvas": {"width": 1080, "height": 1920, "frameRate": 30},
       "background": {"type": "solid", "color": 4278190080},
       "media": {"a": {"path": "${media("large_1440p.mp4")}", "kind": "video", "durationUs": 3000000},
                 "b": {"path": "${media("rotated_portrait.mp4")}", "kind": "video", "durationUs": 3000000}},
       "composition": {"durationUs": 6000000, "clips": [
         {"clipId": "c1", "mediaId": "a", "kind": "video", "startUs": 0, "endUs": 3000000,
          "sourceInUs": 0, "sourceOutUs": 3000000, "speed": 1, "volume": 1,
          "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": ${framing("fill")}},
         {"clipId": "c2", "mediaId": "b", "kind": "video", "startUs": 3000000, "endUs": 6000000,
          "sourceInUs": 0, "sourceOutUs": 3000000, "speed": 1, "volume": 1,
          "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": ${framing("fill")}}]}}
      """,
    )
    val reached = playPreview(doc)
    assertTrue("state $reached", (reached?.positionUs ?: 0) >= 1_000_000)
  }

  @Test
  fun previewPlayerPlaysFromAProxy() = runBlocking<Unit> {
    val proxy = File(tempDir, "proxy.mp4").path
    ProxyMaker.createProxy(context, media("large_1440p.mp4"), proxy)
    val original = MediaProbe.probe(media("large_1440p.mp4")).durationUs!!
    val proxied = MediaProbe.probe(proxy).durationUs!!
    android.util.Log.i("StitchTest", "original $original proxy $proxied")
    val doc = EngineDocument.decode(
      """
      {"canvas": {"width": 1080, "height": 1920, "frameRate": 30},
       "background": {"type": "solid", "color": 4278190080},
       "media": {"a": {"path": "${media("large_1440p.mp4")}", "kind": "video",
                       "durationUs": $original, "proxyPath": "$proxy"},
                 "b": {"path": "${media("rotated_portrait.mp4")}", "kind": "video", "durationUs": 3000000}},
       "composition": {"durationUs": ${original + 3000000}, "clips": [
         {"clipId": "c1", "mediaId": "a", "kind": "video", "startUs": 0, "endUs": $original,
          "sourceInUs": 0, "sourceOutUs": $original, "speed": 1, "volume": 1,
          "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": ${framing("fill")}},
         {"clipId": "c2", "mediaId": "b", "kind": "video", "startUs": $original, "endUs": ${original + 3000000},
          "sourceInUs": 0, "sourceOutUs": 3000000, "speed": 1, "volume": 1,
          "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": ${framing("fill")}}]}}
      """,
    )
    val reached = playPreview(doc)
    assertTrue("state $reached", (reached?.positionUs ?: 0) >= 1_000_000)
  }

  @Test
  fun previewShowsEachClipInItsRange() = runBlocking<Unit> {
    val textures = FakeTextures()
    val player = withContext(Dispatchers.Main) {
      PreviewPlayer(context, textures, handleAudioFocus = false) {}.apply { setDocument(backToBack()) }
    }
    // Seeks exactly and waits for the frame to arrive.
    suspend fun shownAt(us: Long): Int {
      textures.latest = null
      withContext(Dispatchers.Main) { player.seek(us, exact = true) }
      val start = System.currentTimeMillis()
      var shown = 0
      while (System.currentTimeMillis() - start < 10_000) {
        textures.latest?.let { shown = clipShown(it) }
        if (shown != 0 && System.currentTimeMillis() - start > 1_000) break
        kotlinx.coroutines.delay(100)
      }
      return shown
    }
    val second = shownAt(2_500_000)
    val first = shownAt(500_000)
    withContext(Dispatchers.Main) { player.dispose() }
    assertEquals("at 2.5s", 2, second)
    assertEquals("at 0.5s", 1, first)
  }

  @Test
  fun previewPlayerPlaysTheSample() = runBlocking<Unit> {
    val reached = playPreview(sampleDocument())
    assertTrue("state $reached", (reached?.positionUs ?: 0) >= 1_000_000)
  }

  // Sound: limiter, loudness, waveforms

  @Test
  fun limiterHoldsTheCeilingAndLeavesQuietSoundAlone() {
    val rate = 48_000
    fun sine(amplitude: Float) = FloatArray(rate * 2) {
      amplitude * kotlin.math.sin(2 * Math.PI * 440 * (it / 2) / rate).toFloat()
    }
    val loud = sine(2f)
    Limiter(2, rate).process(loud)
    assertTrue(loud.maxOf { kotlin.math.abs(it) } <= Limiter.CEILING + 1e-4f)

    val input = sine(0.5f)
    val quiet = input.copyOf()
    Limiter(2, rate).process(quiet)
    val delay = (rate * Limiter.LOOKAHEAD_S).toInt() * 2
    for (i in delay until quiet.size step 97) assertEquals(input[i - delay], quiet[i], 1e-6f)
  }

  /** A 2 s, 440 Hz stereo sine at 0.9 of full scale, as 16-bit WAV. */
  private fun loudTone(): String {
    val file = File(tempDir, "tone.wav")
    val frames = 96_000
    val data = java.nio.ByteBuffer.allocate(44 + frames * 4).order(java.nio.ByteOrder.LITTLE_ENDIAN)
    data.put("RIFF".toByteArray()).putInt(36 + frames * 4).put("WAVE".toByteArray())
    data.put("fmt ".toByteArray()).putInt(16).putShort(1).putShort(2).putInt(48_000)
      .putInt(48_000 * 4).putShort(4).putShort(16)
    data.put("data".toByteArray()).putInt(frames * 4)
    repeat(frames) {
      val v = (0.9 * Short.MAX_VALUE * kotlin.math.sin(2 * Math.PI * 440 * it / 48_000)).toInt().toShort()
      data.putShort(v).putShort(v)
    }
    file.writeBytes(data.array())
    return file.path
  }

  /** Two copies of [path] at [volume] over a black photo, 2 s. */
  private fun toneDocument(path: String, volume: Double, copies: Int = 2): EngineDocument {
    val items = (0 until copies).joinToString(",") {
      """{"id": "a$it", "mediaId": "t", "startUs": 0, "endUs": 2000000, "sourceInUs": 0,
        "sourceOutUs": 2000000, "speed": 1, "loop": false, "volume": $volume,
        "fadeInUs": 0, "fadeOutUs": 0}"""
    }
    return EngineDocument.decode(
      """
      {"canvas": {"width": 360, "height": 640, "frameRate": 30},
       "background": {"type": "solid", "color": 4278190080},
       "media": {"p": {"path": "${solidPhoto("black", Color.BLACK)}", "kind": "photo"},
                 "t": {"path": "$path", "kind": "audio", "durationUs": 2000000}},
       "composition": {"durationUs": 2000000, "clips": [
         {"clipId": "c", "mediaId": "p", "kind": "photo", "startUs": 0, "endUs": 2000000,
          "sourceInUs": 0, "sourceOutUs": 2000000, "speed": 1, "volume": 0,
          "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": ${framing("fit")}}],
        "audio": [$items]}}
      """,
    )
  }

  @Test
  fun loudMixIsLimitedNotClipped() = runBlocking<Unit> {
    // Two copies of a loud tone at 200 percent: 3.6 times full scale.
    val out = export(toneDocument(loudTone(), volume = 2.0), name = "loud.mp4")
    val x = pcm(out).drop(9_600)
    val clipped = x.count { kotlin.math.abs(it) >= 0.99f }
    assertTrue("clipped samples: $clipped of ${x.size}", clipped.toDouble() / x.size < 0.001)
    assertTrue("still loud", kotlin.math.sqrt(x.sumOf { (it * it).toDouble() } / x.size) > 0.4)
  }

  @Test
  fun volumeAboveFullIsLouder() = runBlocking<Unit> {
    val tone = loudTone()
    // A quiet tone (0.9 at 25 percent), so doubling it stays clear of the limiter.
    val normal = rms(export(toneDocument(tone, 0.25, copies = 1), name = "n.mp4"), 200_000, 1_800_000)
    val doubled = rms(export(toneDocument(tone, 0.5, copies = 1), name = "d.mp4"), 200_000, 1_800_000)
    assertEquals(2.0, doubled / normal, 0.2)
  }

  @Test
  fun waveformHasPeaksOverTime() = runBlocking<Unit> {
    val peaks = Waveform.peaks(media("music.mp3"), 20)
    val seconds = MediaProbe.probe(media("music.mp3")).durationUs!! / 1e6
    assertEquals(seconds * 20, peaks.size.toDouble(), 3.0)
    assertTrue(peaks.max() > 0.1 && peaks.max() <= 1.0)
    assertTrue(Waveform.peaks(media("no_audio.mp4"), 20).isEmpty())
    // AAC in M4A, like the bundled music and recordings.
    val m4a = Waveform.peaks(media("audio_44k.m4a"), 20)
    val m4aSeconds = MediaProbe.probe(media("audio_44k.m4a")).durationUs!! / 1e6
    assertEquals(m4aSeconds * 20, m4a.size.toDouble(), 3.0)
    assertTrue("m4a peaks ${m4a.take(5)}", m4a.max() > 0.1)
  }

  // Text

  @Test
  fun overlaysArePlacedAndAnimated() = runBlocking<Unit> {
    val blue = solidPhoto("blue", Color.BLUE)
    // A 90 x 64 red block, drawn at twice its canvas size as Dart does.
    val red = File(tempDir, "red.png").apply {
      outputStream().use {
        Bitmap.createBitmap(180, 128, Bitmap.Config.ARGB_8888).apply { eraseColor(Color.RED) }
          .compress(Bitmap.CompressFormat.PNG, 100, it)
      }
    }.path
    val doc = EngineDocument.decode(
      """
      {"canvas": {"width": 360, "height": 640, "frameRate": 30},
       "background": {"type": "solid", "color": 4278190080},
       "media": {"p": {"path": "$blue", "kind": "photo"}},
       "composition": {"durationUs": 2000000, "clips": [
         {"clipId": "c", "mediaId": "p", "kind": "photo", "startUs": 0, "endUs": 2000000,
          "sourceInUs": 0, "sourceOutUs": 2000000, "speed": 1, "volume": 0,
          "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": ${framing("fit")}}]},
       "overlays": [{"id": "t", "startUs": 0, "endUs": 2000000, "images": ["$red"],
         "width": 90, "height": 64, "x": 0.5, "y": 0.25, "scale": 1, "rotationDeg": 0,
         "animationIn": {"type": "fade", "durationUs": 400000},
         "animationOut": {"type": "none", "durationUs": 0}}]}
      """,
    )
    val out = export(doc, name = "overlay.mp4")
    val shown = frameAt(out, 1_000_000)
    fun at(b: Bitmap, x: Float, y: Float) = b.getPixel((b.width * x).toInt(), (b.height * y).toInt())
    val center = at(shown, 0.5f, 0.25f)
    assertTrue("red at the overlay's center: ${Integer.toHexString(center)}", Color.red(center) > 200 && Color.blue(center) < 60)
    // The block is 90 canvas pixels wide: 0.625 of the width is outside it.
    val beside = at(shown, 0.7f, 0.25f)
    assertTrue("blue beside it: ${Integer.toHexString(beside)}", Color.blue(beside) > 200)
    val fading = at(frameAt(out, 0), 0.5f, 0.25f)
    assertTrue("hidden as the fade starts: ${Integer.toHexString(fading)}", Color.blue(fading) > 200)
  }

  // Thumbnails and proxies

  @Test
  fun thumbnailsAreWrittenAndCached() = runBlocking<Unit> {
    val dir = File(tempDir, "thumbs").path
    val paths = Thumbnailer.thumbnails(
      media("rotated_portrait.mp4"),
      listOf(0L, 1_000_000L, 2_000_000L),
      128,
      dir,
    )
    assertEquals(3, paths.filterNotNull().size)
    val image = BitmapFactory.decodeFile(paths[0])
    assertTrue("upright portrait", image.height > image.width)
    assertTrue(max(image.width, image.height) <= 128)

    val still = Thumbnailer.thumbnails(media("still.jpg"), listOf(0L, 500_000L), 64, dir)
    assertEquals("a still has one frame", still[0], still[1])
  }

  @Test
  fun stableKeyMatchesIos() {
    // Same FNV-1a as Thumbnailer.stableKey in MediaTools.swift.
    assertEquals("1na42wz0z081x", Thumbnailer.stableKey("/a/b.mp4"))
  }

  @Test
  fun proxyIsSmaller() = runBlocking<Unit> {
    val out = File(tempDir, "proxy.mp4").path
    ProxyMaker.createProxy(context, media("large_1440p.mp4"), out)
    val info = MediaProbe.probe(out)
    assertTrue(max(info.width, info.height) <= 1280)
  }

  @Test
  fun capabilitiesReportsAvc() {
    // Every device can encode H.264 at 1080p; the call must not throw.
    Exporter.capabilities()
  }

  // Helpers

  private fun frameAt(path: String, timeUs: Long): Bitmap {
    val retriever = MediaMetadataRetriever()
    try {
      retriever.setDataSource(path)
      return retriever.getFrameAtTime(timeUs, MediaMetadataRetriever.OPTION_CLOSEST)!!
    } finally {
      retriever.release()
    }
  }

  /** [path]'s decoded sound as floats, all channels interleaved. */
  // Speech audio

  /** A second of photo, then the speech clip from 1 s. Mirrors the Swift test. */
  private fun speechDocument(photoOnly: Boolean = false): EngineDocument {
    val speech = """, {"clipId": "s", "mediaId": "v", "kind": "video", "startUs": 1000000,
      "endUs": 4900000, "sourceInUs": 0, "sourceOutUs": 3900000, "speed": 1, "volume": 1,
      "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": ${framing("fit")}}"""
    return EngineDocument.decode(
      """{"canvas": {"width": 360, "height": 640, "frameRate": 30},
        "background": {"type": "solid", "color": 4278190080},
        "media": {"p": {"path": "${media("still.jpg")}", "kind": "photo"},
                  "v": {"path": "${media("speech.mp4")}", "kind": "video", "hasAudio": true,
                        "durationUs": 3970000}},
        "composition": {"durationUs": ${if (photoOnly) 1000000 else 4900000}, "clips": [
          {"clipId": "p", "mediaId": "p", "kind": "photo", "startUs": 0, "endUs": 1000000,
           "sourceInUs": 0, "sourceOutUs": 1000000, "speed": 1, "volume": 0,
           "audioFadeInUs": 0, "audioFadeOutUs": 0, "framing": ${framing("fit")}}
          ${if (photoOnly) "" else speech}]}}""",
    )
  }

  private suspend fun speechAudio(doc: EngineDocument, name: String): FloatArray {
    val out = File(tempDir, name).path
    val result = CompletableDeferred<String>()
    var last = 0.0
    withContext(Dispatchers.Main) {
      SpeechAudio(context, doc, out).start(object : Exporter.Listener {
        override fun onProgress(fraction: Double) {
          last = fraction
        }

        override fun onCompleted(path: String) {
          result.complete(path)
        }

        override fun onFailed(error: EngineException) {
          result.completeExceptionally(error)
        }
      })
    }
    assertEquals(out, withTimeout(EXPORT_TIMEOUT_MS) { result.await() })
    assertEquals(1.0, last, 0.0)
    assertFalse(File("$out.part").exists())
    assertFalse("the encoded copy is removed", File("$out.m4a").exists())
    val bytes = java.nio.ByteBuffer.wrap(File(out).readBytes()).order(java.nio.ByteOrder.LITTLE_ENDIAN)
    return FloatArray(bytes.remaining() / 4) { bytes.float }
  }

  private fun rms(x: FloatArray, from: Int, to: Int): Double =
    kotlin.math.sqrt((from until to).sumOf { (x[it] * x[it]).toDouble() } / (to - from))

  @Test
  fun speechAudioIsSixteenKilohertzMonoOnTheTimeline() = runBlocking<Unit> {
    val x = speechAudio(speechDocument(), "speech.f32")
    // The sound runs to the end of the speech (the photo second included).
    assertTrue("length ${x.size / 16_000.0} s", x.size / 16_000.0 in 4.6..5.1)
    // Silent over the photo; speech after (it starts about 0.15 s in).
    assertTrue(rms(x, 0, 15_000) < 0.001)
    assertTrue(rms(x, 20_000, 60_000) > 0.01)
  }

  @Test
  fun speechAudioWithoutSoundIsEmpty() = runBlocking<Unit> {
    assertEquals(0, speechAudio(speechDocument(photoOnly = true), "silent.f32").size)
  }

  @Test
  fun decimatorPassesSpeechAndStopsAliases() {
    fun through(hz: Double): Double {
      val d = Decimator()
      val out = (0 until 48_000).mapNotNull {
        d.push(kotlin.math.sin(2 * Math.PI * hz * it / 48_000).toFloat())
      }.drop(100)
      return kotlin.math.sqrt(out.sumOf { (it * it).toDouble() } / out.size)
    }
    // A sine has an RMS of 0.707.
    assertEquals(0.707, through(1_000.0), 0.02)
    // 12 kHz would fold down to 4 kHz: it must be gone.
    assertTrue(through(12_000.0) < 0.01)
  }

  private fun pcm(path: String): List<Float> {
    val extractor = MediaExtractor().apply { setDataSource(path) }
    val track = (0 until extractor.trackCount).first {
      extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME)!!.startsWith("audio/")
    }
    extractor.selectTrack(track)
    val format = extractor.getTrackFormat(track)
    val codec = android.media.MediaCodec.createDecoderByType(format.getString(MediaFormat.KEY_MIME)!!)
    codec.configure(format, null, null, 0)
    codec.start()
    val info = android.media.MediaCodec.BufferInfo()
    val out = ArrayList<Float>()
    var inputDone = false
    try {
      while (true) {
        if (!inputDone) {
          val i = codec.dequeueInputBuffer(10_000)
          if (i >= 0) {
            val size = extractor.readSampleData(codec.getInputBuffer(i)!!, 0)
            if (size < 0) {
              codec.queueInputBuffer(i, 0, 0, 0, android.media.MediaCodec.BUFFER_FLAG_END_OF_STREAM)
              inputDone = true
            } else {
              codec.queueInputBuffer(i, 0, size, extractor.sampleTime, 0)
              extractor.advance()
            }
          }
        }
        val o = codec.dequeueOutputBuffer(info, 10_000)
        if (o < 0) continue
        val samples = codec.getOutputBuffer(o)!!.order(java.nio.ByteOrder.nativeOrder()).asShortBuffer()
        while (samples.hasRemaining()) out += samples.get() / 32768f
        codec.releaseOutputBuffer(o, false)
        if (info.flags and android.media.MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) break
      }
    } finally {
      codec.release()
      extractor.release()
    }
    return out
  }

  /** Loudness of [path]'s audio from [fromUs] to [toUs], 0 to 1. */
  private fun rms(path: String, fromUs: Long, toUs: Long): Double {
    val extractor = MediaExtractor().apply { setDataSource(path) }
    val track = (0 until extractor.trackCount).first {
      extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME)!!.startsWith("audio/")
    }
    extractor.selectTrack(track)
    val format = extractor.getTrackFormat(track)
    val codec = android.media.MediaCodec.createDecoderByType(format.getString(MediaFormat.KEY_MIME)!!)
    codec.configure(format, null, null, 0)
    codec.start()
    val info = android.media.MediaCodec.BufferInfo()
    var sum = 0.0
    var n = 0L
    var inputDone = false
    try {
      while (true) {
        if (!inputDone) {
          val i = codec.dequeueInputBuffer(10_000)
          if (i >= 0) {
            val size = extractor.readSampleData(codec.getInputBuffer(i)!!, 0)
            if (size < 0) {
              codec.queueInputBuffer(i, 0, 0, 0, android.media.MediaCodec.BUFFER_FLAG_END_OF_STREAM)
              inputDone = true
            } else {
              codec.queueInputBuffer(i, 0, size, extractor.sampleTime, 0)
              extractor.advance()
            }
          }
        }
        val o = codec.dequeueOutputBuffer(info, 10_000)
        if (o < 0) continue
        if (info.presentationTimeUs in fromUs until toUs) {
          val samples = codec.getOutputBuffer(o)!!.order(java.nio.ByteOrder.nativeOrder()).asShortBuffer()
          while (samples.hasRemaining()) {
            val v = samples.get() / 32768.0
            sum += v * v
            n++
          }
        }
        codec.releaseOutputBuffer(o, false)
        if (info.flags and android.media.MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) break
      }
    } finally {
      codec.release()
      extractor.release()
    }
    return if (n == 0L) 0.0 else kotlin.math.sqrt(sum / n)
  }

  private fun meanBrightness(bitmap: Bitmap): Double {
    var sum = 0.0
    var n = 0
    for (y in 0 until bitmap.height step 8) {
      for (x in 0 until bitmap.width step 8) {
        val p = bitmap.getPixel(x, y)
        sum += (Color.red(p) + Color.green(p) + Color.blue(p)) / (3 * 255.0)
        n++
      }
    }
    return sum / n
  }

  private fun trackCount(path: String, prefix: String): Int {
    val extractor = MediaExtractor()
    try {
      extractor.setDataSource(path)
      return (0 until extractor.trackCount).count {
        extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME)!!.startsWith(prefix)
      }
    } finally {
      extractor.release()
    }
  }

  private fun videoFormat(path: String): MediaFormat {
    val extractor = MediaExtractor()
    try {
      extractor.setDataSource(path)
      return (0 until extractor.trackCount).map { extractor.getTrackFormat(it) }
        .first { it.getString(MediaFormat.KEY_MIME)!!.startsWith("video/") }
    } finally {
      extractor.release()
    }
  }

  /** Samples per second of the video track, from its timestamps. */
  private fun measuredFrameRate(path: String): Double {
    val extractor = MediaExtractor()
    try {
      extractor.setDataSource(path)
      val track = (0 until extractor.trackCount).first {
        extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME)!!.startsWith("video/")
      }
      extractor.selectTrack(track)
      var count = 0
      var first = Long.MAX_VALUE
      var last = 0L
      do {
        val t = extractor.sampleTime
        if (t < 0) break
        first = minOf(first, t)
        last = max(last, t)
        count++
      } while (extractor.advance())
      return if (last > first) (count - 1) * 1e6 / (last - first) else 0.0
    } finally {
      extractor.release()
    }
  }

  private companion object {
    const val EXPORT_TIMEOUT_MS = 10 * 60 * 1000L
  }
}
