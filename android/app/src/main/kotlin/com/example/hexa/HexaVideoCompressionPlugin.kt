package com.example.hexa_prod

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class HexaVideoCompressionPlugin(
    context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val applicationContext = context.applicationContext

    private val methodChannel = MethodChannel(
        messenger,
        METHOD_CHANNEL_NAME,
    )

    private val progressChannel = EventChannel(
        messenger,
        PROGRESS_CHANNEL_NAME,
    )

    private var progressSink: EventChannel.EventSink? = null
    private var activeCompressor: HexaVideoCompressor? = null

    fun register() {
        methodChannel.setMethodCallHandler(this)
        progressChannel.setStreamHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        when (call.method) {
            "compressVideo" -> startCompression(call, result)
            "cancelCompression" -> {
                activeCompressor?.cancel()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun startCompression(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        if (activeCompressor != null) {
            result.error(
                "compression_busy",
                "Başka bir video hâlâ sıkıştırılıyor.",
                null,
            )
            return
        }

        val inputPath = call.argument<String>("inputPath")?.trim().orEmpty()
        val durationMs = call.argument<Number>("durationMs")?.toLong() ?: 0L
        val width = call.argument<Number>("width")?.toInt() ?: 0
        val height = call.argument<Number>("height")?.toInt() ?: 0
        val targetBytes = call.argument<Number>("targetBytes")?.toLong() ?: 0L
        val maxBytes = call.argument<Number>("maxBytes")?.toLong() ?: 0L

        if (
            inputPath.isEmpty() ||
            durationMs <= 0 ||
            width <= 0 ||
            height <= 0 ||
            targetBytes <= 0 ||
            maxBytes <= 0
        ) {
            result.error(
                "invalid_arguments",
                "Video sıkıştırma bilgileri eksik.",
                null,
            )
            return
        }

        val compressor = HexaVideoCompressor(
            context = applicationContext,
            inputPath = inputPath,
            durationMs = durationMs,
            width = width,
            height = height,
            targetBytes = targetBytes,
            maxBytes = maxBytes,
            onProgress = { progress ->
                progressSink?.success(
                    mapOf("progress" to progress.coerceIn(0, 100)),
                )
            },
            onSuccess = { compressionResult ->
                activeCompressor = null
                result.success(compressionResult)
            },
            onError = { code, message ->
                activeCompressor = null
                result.error(code, message, null)
            },
        )

        activeCompressor = compressor
        compressor.start()
    }

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?,
    ) {
        progressSink = events
    }

    override fun onCancel(arguments: Any?) {
        progressSink = null
    }

    fun dispose() {
        activeCompressor?.cancel()
        activeCompressor = null
        progressSink = null
        methodChannel.setMethodCallHandler(null)
        progressChannel.setStreamHandler(null)
    }

    private companion object {
        const val METHOD_CHANNEL_NAME = "hexa/video_compression"
        const val PROGRESS_CHANNEL_NAME = "hexa/video_compression_progress"
    }
}
