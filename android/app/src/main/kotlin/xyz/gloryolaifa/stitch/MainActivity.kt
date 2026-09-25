package xyz.gloryolaifa.stitch

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import xyz.gloryolaifa.stitch.engine.DeviceHost
import xyz.gloryolaifa.stitch.engine.EngineHost

class MainActivity : FlutterActivity() {
  private var engineHost: EngineHost? = null
  private var deviceHost: DeviceHost? = null

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
