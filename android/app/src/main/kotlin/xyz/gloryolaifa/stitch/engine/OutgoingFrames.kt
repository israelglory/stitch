package xyz.gloryolaifa.stitch.engine

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.Image
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.opengl.GLES20
import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.util.GlUtil
import androidx.media3.common.util.UnstableApi
import java.nio.ByteBuffer
import kotlin.math.abs
import kotlin.math.max

/**
 * A frame of the outgoing clip, ready to sample: [texMatrix] maps upright
 * frame coordinates (0 to 1, y up) to texture coordinates.
 *
 * An RGB frame is one texture ([textures] has one id). A YUV frame is three
 * (Y, U, V), converted to RGB by [yuvToRgb] after subtracting [yuvOffset].
 */
class SourceFrame(
  val textures: IntArray,
  val width: Int,
  val height: Int,
  val texMatrix: FloatArray,
  val yuvToRgb: FloatArray? = null,
  val yuvOffset: FloatArray? = null,
) {
  val isYuv get() = yuvToRgb != null
}

/**
 * Frames of the clip that a transition leaves, drawn by the incoming clip's
 * effect. Media3 delivers one clip at a time to an effect, so the outgoing
 * clip's last moments are decoded here. Used on the GL thread only.
 */
interface OutgoingFrames {
  /** The frame at [sourceUs] in the source file, or null if there is none. */
  fun frameAt(sourceUs: Long): SourceFrame?

  fun release()

  companion object {
    /**
     * Frames of [path]. A video frame not decoded within [timeoutMs] is
     * skipped (the previous one shows): long for export, short for preview
     * so playback never freezes.
     */
    fun open(path: String, kind: String, timeoutMs: Long): OutgoingFrames? = try {
      if (kind == "photo") OutgoingPhoto(path) else OutgoingVideo(path, timeoutMs)
    } catch (e: Exception) {
      Log.w(TAG, "Cannot read outgoing clip $path", e)
      null
    }

    const val TAG = "StitchOutgoing"

    /** Frame coordinates to texture coordinates for rows stored top down. */
    val FLIP_Y = floatArrayOf(1f, 0f, 0f, 0f, -1f, 0f, 0f, 1f, 1f)
  }
}

/** A photo, upright, uploaded once. */
@OptIn(UnstableApi::class)
private class OutgoingPhoto(path: String) : OutgoingFrames {
  private val frame: SourceFrame

  init {
    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeFile(path, bounds)
    // Large photos are sampled down to about the largest export size.
    var sample = 1
    while (max(bounds.outWidth, bounds.outHeight) / (sample * 2) >= MAX_SIDE) sample *= 2
    var bitmap = BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })
      ?: error("Cannot decode $path")
    val rotation = MediaProbe.exifRotation(path)
    if (rotation != 0) {
      val m = Matrix().apply { postRotate(rotation.toFloat()) }
      bitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, m, true)
    }
    val texId = GlUtil.createTexture(bitmap)
    frame = SourceFrame(intArrayOf(texId), bitmap.width, bitmap.height, OutgoingFrames.FLIP_Y)
    bitmap.recycle()
  }

  override fun frameAt(sourceUs: Long): SourceFrame = frame

  override fun release() {
    runCatching { GlUtil.deleteTexture(frame.textures[0]) }
  }

  companion object {
    const val MAX_SIDE = 4096
  }
}

/**
 * A video decoded to memory and uploaded as Y, U, and V textures. Decoding
 * to a SurfaceTexture instead ties the decoder to the GL thread this runs
 * on, and it stalls while that thread waits for a frame.
 *
 * Frames are decoded forward; a jump back, or far ahead, seeks to the
 * previous sync frame first.
 */
@OptIn(UnstableApi::class)
private class OutgoingVideo(path: String, private val timeoutMs: Long) : OutgoingFrames {
  private val extractor = MediaExtractor()
  private val codec: MediaCodec
  private val planes = IntArray(3) { GlUtil.generateTexture() }
  private val planeSizes = arrayOfNulls<IntArray>(3)

  private val rotation: Int
  private val halfFrameUs: Long
  private val yuvToRgb: FloatArray
  private val yuvOffset: FloatArray

  private var width = 0
  private var height = 0
  private var texMatrix = Mat3.IDENTITY
  private var inputDone = false
  private var outputDone = false
  private var shownPts: Long? = null
  private var lastDecodedPts = Long.MIN_VALUE
  private var scratch = ByteArray(0)

  init {
    extractor.setDataSource(path)
    val track = (0 until extractor.trackCount).first {
      extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME)!!.startsWith("video/")
    }
    extractor.selectTrack(track)
    val format = extractor.getTrackFormat(track)
    rotation = if (format.containsKey(MediaFormat.KEY_ROTATION)) {
      ((format.getInteger(MediaFormat.KEY_ROTATION) % 360) + 360) % 360
    } else {
      0
    }
    val fps = runCatching { format.getInteger(MediaFormat.KEY_FRAME_RATE) }.getOrDefault(30)
    halfFrameUs = 500_000L / max(1, fps)
    val conversion = YuvConversion.forFormat(format)
    yuvToRgb = conversion.first
    yuvOffset = conversion.second

    format.setInteger(
      MediaFormat.KEY_COLOR_FORMAT,
      MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible,
    )
    codec = MediaCodec.createDecoderByType(format.getString(MediaFormat.KEY_MIME)!!)
    codec.configure(format, null, null, 0)
    codec.start()
  }

  override fun frameAt(sourceUs: Long): SourceFrame? {
    val shown = shownPts
    if (shown != null && abs(sourceUs - shown) <= halfFrameUs) return current()
    if ((shown != null && sourceUs < shown) || sourceUs > lastDecodedPts + SEEK_AHEAD_US) {
      seek(sourceUs)
    }
    if (decodeTo(sourceUs)) return current()
    Log.w(OutgoingFrames.TAG, "No frame at $sourceUs us within $timeoutMs ms")
    return shownPts?.let { current() }
  }

  private fun current(): SourceFrame {
    val swap = rotation == 90 || rotation == 270
    return SourceFrame(
      planes,
      if (swap) height else width,
      if (swap) width else height,
      texMatrix,
      yuvToRgb,
      yuvOffset,
    )
  }

  private fun seek(sourceUs: Long) {
    extractor.seekTo(sourceUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
    if (lastDecodedPts != Long.MIN_VALUE || inputDone) codec.flush()
    inputDone = false
    outputDone = false
    lastDecodedPts = Long.MIN_VALUE
  }

  /** Decodes until a frame near [targetUs] is uploaded. */
  private fun decodeTo(targetUs: Long): Boolean {
    val info = MediaCodec.BufferInfo()
    val deadline = System.nanoTime() + timeoutMs * 1_000_000
    while (!outputDone && System.nanoTime() < deadline) {
      if (!inputDone) {
        val input = codec.dequeueInputBuffer(0)
        if (input >= 0) {
          val size = extractor.readSampleData(codec.getInputBuffer(input)!!, 0)
          if (size < 0) {
            codec.queueInputBuffer(input, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
            inputDone = true
          } else {
            codec.queueInputBuffer(input, 0, size, extractor.sampleTime, 0)
            extractor.advance()
          }
        }
      }
      val output = codec.dequeueOutputBuffer(info, DEQUEUE_TIMEOUT_US)
      if (output < 0) continue
      if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) outputDone = true
      val hasFrame = info.size > 0
      if (hasFrame) lastDecodedPts = max(lastDecodedPts, info.presentationTimeUs)
      // Upload the first frame at the target, or the last one before the end.
      val show = hasFrame && (info.presentationTimeUs >= targetUs - halfFrameUs || outputDone)
      var uploaded = false
      if (show) {
        codec.getOutputImage(output)?.use { uploaded = upload(it) }
      }
      codec.releaseOutputBuffer(output, false)
      if (uploaded) {
        shownPts = info.presentationTimeUs
        return true
      }
    }
    return false
  }

  /** Uploads a YUV 4:2:0 image as three single-channel textures. */
  private fun upload(image: Image): Boolean {
    val crop = image.cropRect
    width = crop.width()
    height = crop.height()
    val chromaWidth = (width + 1) / 2
    val chromaHeight = (height + 1) / 2
    GLES20.glPixelStorei(GLES20.GL_UNPACK_ALIGNMENT, 1)
    for (i in 0 until 3) {
      val plane = image.planes[i]
      val w = if (i == 0) width else chromaWidth
      val h = if (i == 0) height else chromaHeight
      val left = if (i == 0) crop.left else crop.left / 2
      val top = if (i == 0) crop.top else crop.top / 2
      val bytes = tightPlane(plane.buffer, plane.rowStride, plane.pixelStride, left, top, w, h)
      GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, planes[i])
      val size = planeSizes[i]
      if (size == null || size[0] != w || size[1] != h) {
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexImage2D(
          GLES20.GL_TEXTURE_2D, 0, GLES20.GL_LUMINANCE, w, h, 0,
          GLES20.GL_LUMINANCE, GLES20.GL_UNSIGNED_BYTE, bytes,
        )
        planeSizes[i] = intArrayOf(w, h)
      } else {
        GLES20.glTexSubImage2D(
          GLES20.GL_TEXTURE_2D, 0, 0, 0, w, h,
          GLES20.GL_LUMINANCE, GLES20.GL_UNSIGNED_BYTE, bytes,
        )
      }
    }
    GLES20.glPixelStorei(GLES20.GL_UNPACK_ALIGNMENT, 4)
    // Rows are uploaded top down; then the stored frame is turned upright.
    texMatrix = multiply(OutgoingFrames.FLIP_Y, rotationMatrix(rotation))
    return true
  }

  /** The plane's [w] x [h] pixels, packed without row or pixel padding. */
  private fun tightPlane(
    buffer: ByteBuffer,
    rowStride: Int,
    pixelStride: Int,
    left: Int,
    top: Int,
    w: Int,
    h: Int,
  ): ByteBuffer {
    if (scratch.size < w * h) scratch = ByteArray(w * h)
    val base = buffer.position()
    if (pixelStride == 1) {
      for (row in 0 until h) {
        buffer.position(base + (top + row) * rowStride + left)
        buffer.get(scratch, row * w, w)
      }
    } else {
      var o = 0
      for (row in 0 until h) {
        var p = base + (top + row) * rowStride + left * pixelStride
        for (col in 0 until w) {
          scratch[o++] = buffer.get(p)
          p += pixelStride
        }
      }
    }
    buffer.position(base)
    return ByteBuffer.wrap(scratch, 0, w * h)
  }

  override fun release() {
    runCatching { codec.stop() }
    runCatching { codec.release() }
    runCatching { extractor.release() }
    planes.forEach { runCatching { GlUtil.deleteTexture(it) } }
  }

  companion object {
    const val SEEK_AHEAD_US = 1_000_000L
    const val DEQUEUE_TIMEOUT_US = 10_000L
  }
}

/** YUV to RGB for decoded video, from the stream's color standard and range. */
private object YuvConversion {
  /** Column-major matrix, and the offset subtracted from (Y, U, V) first. */
  fun forFormat(format: MediaFormat): Pair<FloatArray, FloatArray> {
    val height = runCatching { format.getInteger(MediaFormat.KEY_HEIGHT) }.getOrDefault(1080)
    val standard = runCatching { format.getInteger(MediaFormat.KEY_COLOR_STANDARD) }.getOrNull()
    val full = runCatching { format.getInteger(MediaFormat.KEY_COLOR_RANGE) }.getOrNull() ==
      MediaFormat.COLOR_RANGE_FULL
    val (kr, kb) = when (standard) {
      MediaFormat.COLOR_STANDARD_BT601_PAL, MediaFormat.COLOR_STANDARD_BT601_NTSC -> 0.299f to 0.114f
      MediaFormat.COLOR_STANDARD_BT2020 -> 0.2627f to 0.0593f
      MediaFormat.COLOR_STANDARD_BT709 -> 0.2126f to 0.0722f
      // Unlabeled: SD streams are usually BT.601, HD BT.709.
      else -> if (height < 720) 0.299f to 0.114f else 0.2126f to 0.0722f
    }
    val kg = 1 - kr - kb
    val ys = if (full) 1f else 255f / 219f
    val cs = if (full) 1f else 255f / 224f
    // R = Y + 2(1 - kr) V, B = Y + 2(1 - kb) U, and G from the luma equation.
    val rv = 2 * (1 - kr) * cs
    val bu = 2 * (1 - kb) * cs
    val gu = -bu * kb / kg
    val gv = -rv * kr / kg
    val matrix = floatArrayOf(
      ys, ys, ys,
      0f, gu, bu,
      rv, gv, 0f,
    )
    val offset = floatArrayOf(if (full) 0f else 16f / 255f, 0.5f, 0.5f)
    return matrix to offset
  }
}

/**
 * Upright frame coordinates to stored frame coordinates (y up), for a frame
 * shown rotated [degrees] clockwise. Column-major mat3.
 */
fun rotationMatrix(degrees: Int): FloatArray = when (degrees) {
  90 -> floatArrayOf(0f, 1f, 0f, -1f, 0f, 0f, 1f, 0f, 1f)
  180 -> floatArrayOf(-1f, 0f, 0f, 0f, -1f, 0f, 1f, 1f, 1f)
  270 -> floatArrayOf(0f, -1f, 0f, 1f, 0f, 0f, 0f, 1f, 1f)
  else -> Mat3.IDENTITY
}

/** Column-major 3x3 matrices, as GLSL expects them. */
object Mat3 {
  val IDENTITY = floatArrayOf(1f, 0f, 0f, 0f, 1f, 0f, 0f, 0f, 1f)
}

/** [a] times [b], both column-major 3x3. */
fun multiply(a: FloatArray, b: FloatArray): FloatArray {
  val r = FloatArray(9)
  for (col in 0 until 3) {
    for (row in 0 until 3) {
      var s = 0f
      for (k in 0 until 3) s += a[k * 3 + row] * b[col * 3 + k]
      r[col * 3 + row] = s
    }
  }
  return r
}
