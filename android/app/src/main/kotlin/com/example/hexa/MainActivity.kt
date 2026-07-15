package com.example.hexa_prod

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var compressionPlugin: HexaVideoCompressionPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        compressionPlugin = HexaVideoCompressionPlugin(
            context = applicationContext,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        ).also { it.register() }
    }

    override fun onDestroy() {
        compressionPlugin?.dispose()
        compressionPlugin = null
        super.onDestroy()
    }
}
