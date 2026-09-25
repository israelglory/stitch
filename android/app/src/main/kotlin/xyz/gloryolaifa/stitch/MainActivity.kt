package xyz.gloryolaifa.stitch

import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import xyz.gloryolaifa.stitch.engine.DeviceHost
import xyz.gloryolaifa.stitch.engine.EngineHost

class MainActivity : FlutterActivity() {
  private var engineHost: EngineHost? = null
  private var deviceHost: DeviceHost? = null

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      // The system splash stays until Flutter's first frame, which draws
      // the same logo in the same place (lib/app/splash.dart). Removing it
      // at once makes the handoff invisible; the default exit cross-fades
      // the two, which shows a gray logo over the wallpaper.
      splashScreen.setOnExitAnimationListener { view -> view.remove() }
    }
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    engineHost = EngineHost.register(this, flutterEngine)
    deviceHost = DeviceHost.register(this, flutterEngine.dartExecutor.binaryMessenger)
  }

  override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
    engineHost?.dispose()
    engineHost = null
    deviceHost?.dispose()
    deviceHost = null
    super.cleanUpFlutterEngine(flutterEngine)
  }

  @Deprecated("Needed for the document picker's result")
  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    if (deviceHost?.onActivityResult(requestCode, resultCode, data) != true) {
      super.onActivityResult(requestCode, resultCode, data)
    }
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray,
  ) {
    if (deviceHost?.onRequestPermissionsResult(requestCode, grantResults) != true) {
      super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
  }
}
