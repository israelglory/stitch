package xyz.gloryolaifa.stitch

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import xyz.gloryolaifa.stitch.engine.EngineHost

class MainActivity : FlutterActivity() {
  private var engineHost: EngineHost? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    engineHost = EngineHost.register(this, flutterEngine)
  }

  override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
    engineHost?.dispose()
    engineHost = null
    super.cleanUpFlutterEngine(flutterEngine)
  }
}
