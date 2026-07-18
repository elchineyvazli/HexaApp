package com.example.hexa_prod

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class HexaVideoCompressionPlugin(
    context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    private val applicationContext =
        context.applicationContext

    private val mainHandler =
        Handler(Looper.getMainLooper())

    private val methodChannel =
        MethodChannel(
            messenger,
            METHOD_CHANNEL_NAME,
        )

    private val progressChannel =
        EventChannel(
            messenger,
            PROGRESS_CHANNEL_NAME,
        )

    private var progressSink:
        EventChannel.EventSink? = null

    private var activeCompression:
        ActiveCompression? = null

    private var nextRequestId = 0L
    private var isRegistered = false
    private var isDisposed = false

    fun register() {
        if (isDisposed || isRegistered) {
            return
        }

        methodChannel.setMethodCallHandler(this)
        progressChannel.setStreamHandler(this)

        isRegistered = true
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        if (isDisposed) {
            result.error(
                ERROR_PLUGIN_DISPOSED,
                "Video sıkıştırma servisi artık kullanılamıyor.",
                null,
            )
            return
        }

        when (call.method) {
            METHOD_COMPRESS_VIDEO -> {
                startCompression(
                    call = call,
                    result = result,
                )
            }

            METHOD_CANCEL_COMPRESSION -> {
                cancelActiveCompression(
                    notifyPendingCall = true,
                )

                // Eski Dart sözleşmesini bozmamak için void döndürülür.
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun startCompression(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        if (activeCompression != null) {
            result.error(
                ERROR_COMPRESSION_BUSY,
                "Başka bir video hâlâ hazırlanıyor.",
                null,
            )
            return
        }

        val arguments = parseArguments(call)

        if (arguments == null) {
            result.error(
                ERROR_INVALID_ARGUMENTS,
                "Video sıkıştırma bilgileri eksik veya geçersiz.",
                null,
            )
            return
        }

        val inputFile = File(arguments.inputPath)

        if (!inputFile.exists() || !inputFile.isFile) {
            result.error(
                ERROR_INPUT_NOT_FOUND,
                "Sıkıştırılacak video dosyası bulunamadı.",
                mapOf(
                    "inputPath" to arguments.inputPath,
                ),
            )
            return
        }

        val requestId = ++nextRequestId

        val compressor =
            HexaVideoCompressor(
                context = applicationContext,
                inputPath = arguments.inputPath,
                durationMs = arguments.durationMs,
                width = arguments.width,
                height = arguments.height,
                targetBytes = arguments.targetBytes,
                maxBytes = arguments.maxBytes,
                onProgress = { progress ->
                    mainHandler.post {
                        emitProgress(
                            requestId = requestId,
                            progress = progress,
                        )
                    }
                },
                onSuccess = { compressionResult ->
                    mainHandler.post {
                        finishWithSuccess(
                            requestId = requestId,
                            compressionResult =
                                compressionResult,
                        )
                    }
                },
                onError = { code, message ->
                    mainHandler.post {
                        finishWithError(
                            requestId = requestId,
                            code = code,
                            message = message,
                        )
                    }
                },
            )

        activeCompression =
            ActiveCompression(
                requestId = requestId,
                compressor = compressor,
                result = result,
            )

        try {
            compressor.start()
        } catch (error: Throwable) {
            activeCompression = null

            result.error(
                ERROR_START_FAILED,
                "Video sıkıştırma işlemi başlatılamadı.",
                mapOf(
                    "requestId" to requestId,
                    "cause" to error.toString(),
                ),
            )
        }
    }

    private fun parseArguments(
        call: MethodCall,
    ): CompressionArguments? {
        val inputPath =
            call.argument<String>("inputPath")
                ?.trim()
                .orEmpty()

        val durationMs =
            call.argument<Number>("durationMs")
                ?.toLong()
                ?: 0L

        val width =
            call.argument<Number>("width")
                ?.toInt()
                ?: 0

        val height =
            call.argument<Number>("height")
                ?.toInt()
                ?: 0

        val targetBytes =
            call.argument<Number>("targetBytes")
                ?.toLong()
                ?: 0L

        val maxBytes =
            call.argument<Number>("maxBytes")
                ?.toLong()
                ?: 0L

        val isValid =
            inputPath.isNotEmpty() &&
                durationMs > 0L &&
                width > 0 &&
                height > 0 &&
                targetBytes > 0L &&
                maxBytes > 0L &&
                targetBytes <= maxBytes

        if (!isValid) {
            return null
        }

        return CompressionArguments(
            inputPath = inputPath,
            durationMs = durationMs,
            width = width,
            height = height,
            targetBytes = targetBytes,
            maxBytes = maxBytes,
        )
    }

    private fun emitProgress(
        requestId: Long,
        progress: Int,
    ) {
        val active = activeCompression

        if (
            isDisposed ||
            active == null ||
            active.requestId != requestId
        ) {
            return
        }

        try {
            progressSink?.success(
                mapOf(
                    "requestId" to requestId,
                    "progress" to progress.coerceIn(0, 100),
                ),
            )
        } catch (error: Throwable) {
            Log.w(
                LOG_TAG,
                "Sıkıştırma ilerlemesi Flutter'a iletilemedi.",
                error,
            )
        }
    }

    private fun finishWithSuccess(
        requestId: Long,
        compressionResult: Any?,
    ) {
        val active = activeCompression

        if (
            isDisposed ||
            active == null ||
            active.requestId != requestId
        ) {
            return
        }

        activeCompression = null
        active.result.success(compressionResult)
    }

    private fun finishWithError(
        requestId: Long,
        code: String,
        message: String,
    ) {
        val active = activeCompression

        if (
            isDisposed ||
            active == null ||
            active.requestId != requestId
        ) {
            return
        }

        activeCompression = null

        active.result.error(
            code.ifBlank {
                ERROR_COMPRESSION_FAILED
            },
            message.ifBlank {
                "Video sıkıştırma tamamlanamadı."
            },
            mapOf(
                "requestId" to requestId,
            ),
        )
    }

    private fun cancelActiveCompression(
        notifyPendingCall: Boolean,
    ): Boolean {
        val active =
            activeCompression ?: return false

        // Önce aktif kayıt kaldırılır. Böylece compressor.cancel() sonrasında
        // gelebilecek eski success/error callback'leri dikkate alınmaz.
        activeCompression = null

        try {
            active.compressor.cancel()
        } catch (error: Throwable) {
            Log.w(
                LOG_TAG,
                "Video sıkıştırma iptal edilirken hata oluştu.",
                error,
            )
        }

        if (notifyPendingCall && !isDisposed) {
            active.result.error(
                ERROR_COMPRESSION_CANCELLED,
                "Video sıkıştırma işlemi iptal edildi.",
                mapOf(
                    "requestId" to active.requestId,
                ),
            )
        }

        return true
    }

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?,
    ) {
        if (isDisposed) {
            events?.error(
                ERROR_PLUGIN_DISPOSED,
                "Video sıkıştırma servisi kapatıldı.",
                null,
            )
            return
        }

        progressSink = events
    }

    override fun onCancel(arguments: Any?) {
        progressSink = null
    }

    fun dispose() {
        if (isDisposed) {
            return
        }

        isDisposed = true

        cancelActiveCompression(
            notifyPendingCall = false,
        )

        progressSink = null

        if (isRegistered) {
            methodChannel.setMethodCallHandler(null)
            progressChannel.setStreamHandler(null)
            isRegistered = false
        }

        mainHandler.removeCallbacksAndMessages(null)
    }

    private data class CompressionArguments(
        val inputPath: String,
        val durationMs: Long,
        val width: Int,
        val height: Int,
        val targetBytes: Long,
        val maxBytes: Long,
    )

    private data class ActiveCompression(
        val requestId: Long,
        val compressor: HexaVideoCompressor,
        val result: MethodChannel.Result,
    )

    private companion object {
        const val LOG_TAG =
            "HexaVideoCompression"

        const val METHOD_CHANNEL_NAME =
            "hexa/video_compression"

        const val PROGRESS_CHANNEL_NAME =
            "hexa/video_compression_progress"

        const val METHOD_COMPRESS_VIDEO =
            "compressVideo"

        const val METHOD_CANCEL_COMPRESSION =
            "cancelCompression"

        const val ERROR_COMPRESSION_BUSY =
            "compression_busy"

        const val ERROR_COMPRESSION_CANCELLED =
            "compression_cancelled"

        const val ERROR_COMPRESSION_FAILED =
            "compression_failed"

        const val ERROR_INVALID_ARGUMENTS =
            "invalid_arguments"

        const val ERROR_INPUT_NOT_FOUND =
            "input_not_found"

        const val ERROR_START_FAILED =
            "compression_start_failed"

        const val ERROR_PLUGIN_DISPOSED =
            "plugin_disposed"
    }
}