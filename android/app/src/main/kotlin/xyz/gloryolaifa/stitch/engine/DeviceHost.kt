package xyz.gloryolaifa.stitch.engine

import android.Manifest
import android.app.Activity
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaRecorder
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Environment
import android.os.Looper
import android.os.StatFs
import android.os.SystemClock
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.provider.Settings
import android.view.WindowManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import io.flutter.plugin.common.BinaryMessenger
import java.io.File
import java.util.UUID
import kotlin.coroutines.resume
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext

/**
 * Device features: picking audio files, trying music before adding it, the
 * microphone permission, voiceover recording, free space, saving and
 * sharing exports, links, and keeping the screen on. Mirrors
 * DeviceHost.swift. Used on the main thread.
 */
class DeviceHost(
  private val activity: Activity,
  messenger: BinaryMessenger,
) : DeviceHostApi {
  private val callbacks = DeviceFlutterApi(messenger)
  private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
  private val handler = Handler(Looper.getMainLooper())
  private val prefs = activity.getSharedPreferences("stitch_device", Context.MODE_PRIVATE)

  private var pick: CancellableContinuation<PickedFileMessage?>? = null
  private var pickDir: String? = null
  private var micRequest: CancellableContinuation<MicrophonePermission>? = null
  private var permissionRequest: CancellableContinuation<Boolean>? = null

  // Picking files

  override suspend fun pickAudioFile(outDir: String): PickedFileMessage? {
    pick?.resume(null)
    return suspendCancellableCoroutine { cont ->
      pick = cont
      pickDir = outDir
      val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
        .addCategory(Intent.CATEGORY_OPENABLE)
        .setType("audio/*")
      activity.startActivityForResult(intent, REQUEST_PICK_AUDIO)
    }
  }

  /** Forwarded from the activity. Returns whether it was ours. */
  fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (requestCode != REQUEST_PICK_AUDIO) return false
    val cont = pick ?: return true
    pick = null
    val uri = data?.data
    val dir = pickDir
    if (resultCode != Activity.RESULT_OK || uri == null || dir == null) {
      cont.resume(null)
      return true
    }
    scope.launch {
      val picked = runCatching { copy(uri, dir) }
        .onFailure { Log.w(TAG, "Could not copy picked file", it) }
        .getOrNull()
      cont.resume(picked)
    }
    return true
  }

  private suspend fun copy(uri: Uri, dir: String): PickedFileMessage = withContext(Dispatchers.IO) {
    val resolver = activity.contentResolver
    val displayName = resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
      ?.use { if (it.moveToFirst()) it.getString(0) else null }
      ?: "Audio"
    val dot = displayName.lastIndexOf('.')
    val name = if (dot > 0) displayName.substring(0, dot) else displayName
    val ext = if (dot > 0) displayName.substring(dot + 1).lowercase() else "m4a"
    File(dir).mkdirs()
    val out = File(dir, "${UUID.randomUUID()}.$ext")
    val temp = File("${out.path}.part")
    resolver.openInputStream(uri).use { input ->
      requireNotNull(input) { "Cannot open $uri" }
      temp.outputStream().use { input.copyTo(it) }
    }
    check(temp.renameTo(out)) { "Cannot write ${out.path}" }
    PickedFileMessage(out.path, name)
  }

  // Trying music

  private var previewPlayer: ExoPlayer? = null
  private var previewPath: String? = null
  private val previewTicker = object : Runnable {
    override fun run() {
      publishPreview()
      if (previewPlayer?.isPlaying == true) handler.postDelayed(this, PREVIEW_TICK_MS)
    }
  }

  override fun startAudioPreview(path: String) {
    val player = previewPlayer ?: ExoPlayer.Builder(activity)
      .setAudioAttributes(
        androidx.media3.common.AudioAttributes.Builder()
          .setUsage(androidx.media3.common.C.USAGE_MEDIA)
          .setContentType(androidx.media3.common.C.AUDIO_CONTENT_TYPE_MUSIC)
          .build(),
        /* handleAudioFocus= */ true,
      )
      .build()
      .also { p ->
        p.addListener(object : Player.Listener {
          override fun onIsPlayingChanged(isPlaying: Boolean) {
            handler.removeCallbacks(previewTicker)
            if (isPlaying) handler.post(previewTicker) else publishPreview()
          }

          override fun onPlaybackStateChanged(playbackState: Int) {
            if (playbackState == Player.STATE_ENDED) p.playWhenReady = false
            publishPreview()
          }
        })
        previewPlayer = p
      }
    previewPath = path
    player.setMediaItem(MediaItem.fromUri(Uri.fromFile(File(path))))
    player.prepare()
    player.play()
  }

  override fun stopAudioPreview() {
    handler.removeCallbacks(previewTicker)
    previewPlayer?.release()
    previewPlayer = null
    publishPreview()
    previewPath = null
  }

  private fun publishPreview() {
    val p = previewPlayer
    val duration = p?.duration?.takeIf { it > 0 } ?: 0
    val state = AudioPreviewStateMessage(
      path = previewPath ?: "",
      positionUs = (p?.currentPosition ?: 0) * 1000,
      durationUs = duration * 1000,
      isPlaying = p?.isPlaying == true,
    )
    scope.launch { runCatching { callbacks.onAudioPreviewState(state) } }
  }

  // The microphone

  override fun microphonePermission(): MicrophonePermission = when {
    ContextCompat.checkSelfPermission(activity, Manifest.permission.RECORD_AUDIO) ==
      PackageManager.PERMISSION_GRANTED -> MicrophonePermission.GRANTED
    !prefs.getBoolean(ASKED_MIC, false) -> MicrophonePermission.UNDETERMINED
    // After a refusal the system shows the rationale flag until the user
    // chooses "Don't ask again"; then only settings can grant it.
    ActivityCompat.shouldShowRequestPermissionRationale(activity, Manifest.permission.RECORD_AUDIO) ->
      MicrophonePermission.DENIED
    else -> MicrophonePermission.PERMANENTLY_DENIED
  }

  override suspend fun requestMicrophone(): MicrophonePermission {
    val current = microphonePermission()
    if (current == MicrophonePermission.GRANTED || current == MicrophonePermission.PERMANENTLY_DENIED) {
      return current
    }
    micRequest?.resume(current)
    return suspendCancellableCoroutine { cont ->
      micRequest = cont
      prefs.edit().putBoolean(ASKED_MIC, true).apply()
      ActivityCompat.requestPermissions(
        activity,
        arrayOf(Manifest.permission.RECORD_AUDIO),
        REQUEST_MICROPHONE,
      )
    }
  }

  /** Forwarded from the activity. Returns whether it was ours. */
  fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray): Boolean {
    when (requestCode) {
      REQUEST_MICROPHONE -> {
        micRequest?.resume(microphonePermission())
        micRequest = null
      }
      REQUEST_OTHER -> {
        permissionRequest?.resume(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED)
        permissionRequest = null
      }
      else -> return false
    }
    return true
  }

  /** Asks for [permission]; true when granted. */
  private suspend fun request(permission: String): Boolean {
    if (ContextCompat.checkSelfPermission(activity, permission) == PackageManager.PERMISSION_GRANTED) {
      return true
    }
    permissionRequest?.resume(false)
    return suspendCancellableCoroutine { cont ->
      permissionRequest = cont
      ActivityCompat.requestPermissions(activity, arrayOf(permission), REQUEST_OTHER)
    }
  }

  // Storage, saving, and sharing

  override fun freeSpace(path: String): Long {
    var dir = File(path)
    while (!dir.exists()) dir = dir.parentFile ?: return 0
    return StatFs(dir.path).availableBytes
  }

  override suspend fun saveVideoToGallery(path: String): GallerySaveResult {
    val source = File(path)
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
      // Android 8 and 9 write to shared storage directly, with permission.
      val permission = Manifest.permission.WRITE_EXTERNAL_STORAGE
      if (!request(permission)) {
        return if (ActivityCompat.shouldShowRequestPermissionRationale(activity, permission)) {
          GallerySaveResult.DENIED
        } else {
          GallerySaveResult.PERMANENTLY_DENIED
        }
      }
    }
    try {
      withContext(Dispatchers.IO) { writeToMovies(source) }
    } catch (e: Exception) {
      Log.e(TAG, "Saving to the gallery failed", e)
      throw FlutterError("save_failed", e.message)
    }
    return GallerySaveResult.SAVED
  }

  /** Copies [source] into Movies/Stitch, where gallery apps find it. */
  @Suppress("DEPRECATION")
  private fun writeToMovies(source: File) {
    val resolver = activity.contentResolver
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      val values = ContentValues().apply {
        put(MediaStore.Video.Media.DISPLAY_NAME, source.name)
        put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
        put(MediaStore.Video.Media.RELATIVE_PATH, "${Environment.DIRECTORY_MOVIES}/$ALBUM")
        put(MediaStore.Video.Media.IS_PENDING, 1)
      }
      val collection = MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
      val uri = resolver.insert(collection, values) ?: error("Could not create the video")
      try {
        resolver.openOutputStream(uri)!!.use { out -> source.inputStream().use { it.copyTo(out) } }
        resolver.update(uri, ContentValues().apply { put(MediaStore.Video.Media.IS_PENDING, 0) }, null, null)
      } catch (e: Exception) {
        resolver.delete(uri, null, null)
        throw e
      }
    } else {
      val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES), ALBUM)
      dir.mkdirs()
      val target = File(dir, source.name)
      source.copyTo(target, overwrite = true)
      android.media.MediaScannerConnection.scanFile(activity, arrayOf(target.path), arrayOf("video/mp4"), null)
    }
  }

  override fun shareFile(path: String, mimeType: String) {
    val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.files", File(path))
    val send = Intent(Intent.ACTION_SEND)
      .setType(mimeType)
      .putExtra(Intent.EXTRA_STREAM, uri)
      .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    activity.startActivity(Intent.createChooser(send, null))
  }

  override fun openUrl(url: String) {
    try {
      activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
    } catch (e: android.content.ActivityNotFoundException) {
      Log.w(TAG, "No app opens $url", e)
    }
  }

  override fun setKeepScreenOn(on: Boolean) {
    if (on) {
      activity.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    } else {
      activity.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
  }

  override fun appVersion(): String {
    val info = activity.packageManager.getPackageInfo(activity.packageName, 0)
    @Suppress("DEPRECATION")
    val code = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) info.longVersionCode else info.versionCode.toLong()
    return "${info.versionName} ($code)"
  }

  override suspend fun requestNotifications(): Boolean =
    Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
      request(Manifest.permission.POST_NOTIFICATIONS)

  override fun openAppSettings() {
    activity.startActivity(
      Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", activity.packageName, null))
        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
    )
  }

  // Recording

  private var recorder: MediaRecorder? = null
  private var recordingPath: String? = null
  private var recordingStart = 0L
  private var focusRequest: AudioFocusRequest? = null
  private val audioManager get() = activity.getSystemService(Context.AUDIO_SERVICE) as AudioManager

  private val levelTicker = object : Runnable {
    override fun run() {
      val r = recorder ?: return
      val level = runCatching { r.maxAmplitude / 32767.0 }.getOrDefault(0.0).coerceIn(0.0, 1.0)
      scope.launch { runCatching { callbacks.onRecordingLevel(level) } }
      handler.postDelayed(this, LEVEL_TICK_MS)
    }
  }

  override fun startRecording(outPath: String) {
    cancelRecording()
    File(outPath).parentFile?.mkdirs()
    val r = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) MediaRecorder(activity) else MediaRecorder()
    try {
      r.setAudioSource(MediaRecorder.AudioSource.MIC)
      r.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
      r.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
      r.setAudioSamplingRate(48_000)
      r.setAudioEncodingBitRate(128_000)
      r.setAudioChannels(1)
      r.setOutputFile(outPath)
      r.setOnErrorListener { _, what, _ ->
        Log.w(TAG, "Recording error $what")
        interrupt()
      }
      r.prepare()
      r.start()
    } catch (e: Exception) {
      r.release()
      throw FlutterError("recording_failed", e.message)
    }
    recorder = r
    recordingPath = outPath
    recordingStart = SystemClock.elapsedRealtime()
    requestFocus()
    handler.post(levelTicker)
  }

  /** Other apps and calls taking audio end the recording (kept so far). */
  private fun requestFocus() {
    val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
      .setAudioAttributes(
        AudioAttributes.Builder()
          .setUsage(AudioAttributes.USAGE_MEDIA)
          .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
          .build(),
      )
      .setOnAudioFocusChangeListener({ change ->
        if (change == AudioManager.AUDIOFOCUS_LOSS || change == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT) {
          interrupt()
        }
      }, handler)
      .build()
    focusRequest = request
    audioManager.requestAudioFocus(request)
  }

  private fun interrupt() {
    if (recorder == null) return
    val (path, durationUs) = finish(keep = true)
    scope.launch { runCatching { callbacks.onRecordingInterrupted(path, durationUs) } }
  }

  /** Stops the recorder; returns the file (when kept and valid) and its length. */
  private fun finish(keep: Boolean): Pair<String?, Long> {
    handler.removeCallbacks(levelTicker)
    focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
    focusRequest = null
    val r = recorder ?: return null to 0L
    val path = recordingPath
    val elapsedUs = (SystemClock.elapsedRealtime() - recordingStart) * 1000
    recorder = null
    recordingPath = null
    // Stopping right after starting throws: nothing was recorded.
    val stopped = runCatching { r.stop() }.isSuccess
    r.release()
    if (!keep || !stopped || path == null) {
      path?.let { File(it).delete() }
      return null to 0L
    }
    return path to elapsedUs
  }

  override suspend fun stopRecording(): RecordingMessage {
    val (path, elapsedUs) = finish(keep = true)
    if (path == null) throw FlutterError("recording_failed", "Nothing was recorded")
    // The file knows its exact length.
    val durationUs = runCatching { MediaProbe.probe(path).durationUs }.getOrNull() ?: elapsedUs
    return RecordingMessage(path, durationUs)
  }

  override fun cancelRecording() {
    finish(keep = false)
  }

  fun dispose() {
    cancelRecording()
    stopAudioPreview()
    pick?.resume(null)
    micRequest?.resume(MicrophonePermission.DENIED)
    permissionRequest?.resume(false)
    scope.cancel()
  }

  companion object {
    private const val TAG = "StitchDevice"
    private const val REQUEST_PICK_AUDIO = 0x5171
    private const val REQUEST_MICROPHONE = 0x5172
    private const val REQUEST_OTHER = 0x5173
    private const val ALBUM = "Stitch"
    private const val ASKED_MIC = "asked_microphone"
    private const val PREVIEW_TICK_MS = 200L
    private const val LEVEL_TICK_MS = 50L

    fun register(activity: Activity, messenger: BinaryMessenger): DeviceHost =
      DeviceHost(activity, messenger).also { DeviceHostApi.setUp(messenger, it) }
  }
}
