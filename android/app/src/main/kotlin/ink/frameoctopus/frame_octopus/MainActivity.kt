package ink.frameoctopus.frame_octopus

import android.content.Intent
import android.media.MediaMetadataRetriever
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val executor = Executors.newSingleThreadExecutor()
    private lateinit var gallery: GalleryBridge

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        gallery = GalleryBridge(this, flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mosaic/media")
            .setMethodCallHandler { call, result ->
                if (call.method != "rotation") { result.notImplemented(); return@setMethodCallHandler }
                val path = call.argument<String>("path")
                executor.execute {
                    val retriever = MediaMetadataRetriever()
                    val rotation = try {
                        if (path == null) null else {
                            retriever.setDataSource(path)
                            retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull()
                        }
                    } catch (_: Exception) { null }
                    finally { try { retriever.release() } catch (_: Exception) { } }
                    runOnUiThread { result.success(rotation) }
                }
            }
    }

    @Deprecated("Activity result bridge for FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (::gallery.isInitialized && gallery.onActivityResult(requestCode, resultCode, data)) return
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (::gallery.isInitialized) gallery.onRequestPermissionsResult(requestCode, grantResults)
    }

    override fun onDestroy() {
        executor.shutdown()
        super.onDestroy()
    }
}
