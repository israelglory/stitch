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
  fun compositionHasTwoVideoSequencesAndOneForMusic() {
    val built = CompositionBuilder.build(sampleDocument(), forExport = true)
    assertEquals(6_500_000L, built.durationUs)
    assertEquals(3, built.composition.sequences.size)
    // Every sequence spans the whole document, so none ends early.
    for (sequence in built.composition.sequences.take(2)) {
      val total = sequence.editedMediaItems.sumOf { it.presentationDurationUs }
      assertEquals(6_500_000.0, total.toDouble(), 1_000.0)
    }
  }

  @Test
  fun previewCompositionCutsAtTransitions() {
    val built = CompositionBuilder.build(sampleDocument(), forExport = false)
    // One video sequence, plus the music.
    assertEquals(2, built.composition.sequences.size)
    val items = built.composition.sequences[0].editedMediaItems
    assertEquals(3, items.size)
    // The crossfade from 1.5 s to 2 s becomes a cut at 1.75 s.
    assertEquals(1_750_000.0, items[0].presentationDurationUs.toDouble(), 1_000.0)
    assertEquals(6_500_000.0, items.sumOf { it.presentationDurationUs }.toDouble(), 1_000.0)
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
        ExportRequestMessage(out, width, height, fps, 2_000_000, hevc),
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
