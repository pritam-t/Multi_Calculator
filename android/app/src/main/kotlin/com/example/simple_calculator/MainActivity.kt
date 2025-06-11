package com.example.simple_calculator

import android.media.MediaScannerConnection
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "vault.media/remove"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "scanFile") {
                val path = call.argument<String>("path")
                if (path != null) {
                    // Notify Android that this file is removed or moved
                    MediaScannerConnection.scanFile(
                        applicationContext,
                        arrayOf(path),
                        null
                    ) { _, _ ->
                        // Delete the file if it still exists
                        val file = File(path)
                        if (file.exists()) file.delete()
                    }
                    result.success("Scanned")
                } else {
                    result.error("INVALID_ARGUMENT", "Path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
