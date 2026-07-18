package com.example.hexa_prod

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var compressionPlugin: HexaVideoCompressionPlugin? = null

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine,
    ) {
        // pubspec.yaml üzerinden gelen standart Flutter pluginlerini korur.
        super.configureFlutterEngine(flutterEngine)

        // Aynı engine yeniden yapılandırılırsa ikinci bir MethodChannel
        // kaydı bırakmayız.
        compressionPlugin?.dispose()

        compressionPlugin =
            HexaVideoCompressionPlugin(
                context = applicationContext,
                messenger = flutterEngine.dartExecutor.binaryMessenger,
            ).also { plugin ->
                plugin.register()
            }
    }

    override fun cleanUpFlutterEngine(
        flutterEngine: FlutterEngine,
    ) {
        compressionPlugin?.dispose()
        compressionPlugin = null

        super.cleanUpFlutterEngine(flutterEngine)
    }
}