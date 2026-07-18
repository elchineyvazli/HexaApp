package com.example.hexa_prod

import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.Presentation
import androidx.media3.transformer.AudioEncoderSettings
import androidx.media3.transformer.Composition
import androidx.media3.transformer.DefaultEncoderFactory
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.ProgressHolder
import androidx.media3.transformer.Transformer
import androidx.media3.transformer.VideoEncoderSettings
import java.io.File
import java.util.UUID
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.roundToInt

@UnstableApi
class HexaVideoCompressor(
    context: Context,
    private val inputPath: String,
    private val durationMs: Long,
    private val width: Int,
    private val height: Int,
    private val targetBytes: Long,
    private val maxBytes: Long,
    private val onProgress: (Int) -> Unit,
    private val onSuccess: (Map<String, Any>) -> Unit,
    private val onError: (String, String) -> Unit,
) {
    private val applicationContext =
        context.applicationContext

    private val mainHandler =
        Handler(Looper.getMainLooper())

    private val cancelled =
        AtomicBoolean(false)

    private val finished =
        AtomicBoolean(false)

    private val outputFiles =
        linkedSetOf<File>()

    private val progressHolder =
        ProgressHolder()

    private var activeTransformer: Transformer? = null

    private var currentAttempt = 0
    private var currentTargetBytes = targetBytes
    private var currentVideoBitrate = 0
    private var lastReportedProgress = -1

    private val outputWidth = encoderSafeDimension(width)
    private val outputHeight = encoderSafeDimension(height)

    private val progressRunnable =
        object : Runnable {
            override fun run() {
                if (
                    cancelled.get() ||
                    finished.get()
                ) {
                    return
                }

                val transformer =
                    activeTransformer ?: return

                try {
                    val progressState =
                        transformer.getProgress(
                            progressHolder,
                        )

                    if (
                        progressState ==
                        Transformer.PROGRESS_STATE_AVAILABLE
                    ) {
                        emitProgress(
                            mapAttemptProgress(
                                attempt = currentAttempt,
                                attemptProgress =
                                    progressHolder.progress,
                            ),
                        )
                    }
                } catch (error: IllegalStateException) {
                    finishWithError(
                        code = ERROR_COMPRESSION_FAILED,
                        message =
                            "Video ilerleme bilgisi alınamadı.",
                    )
                    return
                }

                if (
                    !cancelled.get() &&
                    !finished.get() &&
                    activeTransformer != null
                ) {
                    mainHandler.postDelayed(
                        this,
                        PROGRESS_INTERVAL_MS,
                    )
                }
            }
        }

    fun start() {
        runOnMain {
            startOnMain()
        }
    }

    fun cancel() {
        cancelled.set(true)

        runOnMain {
            cancelOnMain()
        }
    }

    private fun startOnMain() {
        if (
            cancelled.get() ||
            finished.get()
        ) {
            return
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            finishWithError(
                code = ERROR_UNSUPPORTED_ANDROID,
                message =
                    "Video sıkıştırma Android 6 veya "
                        + "daha yeni bir cihaz gerektiriyor.",
            )
            return
        }

        val inputFile = File(inputPath)

        if (
            !inputFile.isFile ||
            inputFile.length() <= 0L
        ) {
            finishWithError(
                code = ERROR_INVALID_INPUT,
                message =
                    "Sıkıştırılacak video dosyası bulunamadı.",
            )
            return
        }

        if (
            durationMs <= 0L ||
            outputWidth < 2 ||
            outputHeight < 2 ||
            targetBytes <= 0L ||
            maxBytes <= 0L ||
            targetBytes > maxBytes
        ) {
            finishWithError(
                code = ERROR_INVALID_ARGUMENTS,
                message =
                    "Video sıkıştırma bilgileri geçersiz.",
            )
            return
        }

        startAttempt(
            attempt = 0,
            attemptTargetBytes = targetBytes,
        )
    }

    private fun cancelOnMain() {
        if (!finished.compareAndSet(false, true)) {
            return
        }

        stopProgressPolling()

        val transformer = activeTransformer
        activeTransformer = null

        try {
            transformer?.cancel()
        } catch (error: Exception) {
            Log.w(
                LOG_TAG,
                "Transformer iptal edilirken hata oluştu.",
                error,
            )
        }

        deleteAllOutputs()

        emitError(
            code = ERROR_COMPRESSION_CANCELLED,
            message =
                "Video sıkıştırma işlemi iptal edildi.",
        )
    }

    private fun startAttempt(
        attempt: Int,
        attemptTargetBytes: Long,
    ) {
        if (
            cancelled.get() ||
            finished.get()
        ) {
            return
        }

        currentAttempt = attempt
        currentTargetBytes = attemptTargetBytes

        val calculatedBitrate =
            calculateVideoBitrate(
                attemptTargetBytes,
            )

        if (calculatedBitrate == null) {
            finishWithError(
                code = ERROR_VIDEO_TOO_LONG,
                message =
                    "Bu video, çözünürlüğü korunarak "
                        + "yükleme sınırına indirilemeyecek kadar uzun.",
            )
            return
        }

        currentVideoBitrate = calculatedBitrate

        val outputDirectory = File(
            applicationContext.cacheDir,
            OUTPUT_DIRECTORY_NAME,
        )

        if (
            !outputDirectory.exists() &&
            !outputDirectory.mkdirs()
        ) {
            finishWithError(
                code = ERROR_OUTPUT_DIRECTORY,
                message =
                    "Geçici video klasörü oluşturulamadı.",
            )
            return
        }

        val outputFile = File(
            outputDirectory,
            "hexa_${UUID.randomUUID()}_$attempt.mp4",
        )

        outputFiles += outputFile

        try {
            val videoEncoderSettings =
                VideoEncoderSettings.Builder()
                    .setBitrate(currentVideoBitrate)
                    .build()

            val audioEncoderSettings =
                AudioEncoderSettings.Builder()
                    .setBitrate(REQUESTED_AUDIO_BITRATE)
                    .build()

            val encoderFactory =
                DefaultEncoderFactory.Builder(
                    applicationContext,
                )
                    // Çözünürlüğün sessizce değiştirilmesine izin verme.
                    .setEnableFormatFallback(false)
                    .setRequestedVideoEncoderSettings(
                        videoEncoderSettings,
                    )
                    .setRequestedAudioEncoderSettings(
                        audioEncoderSettings,
                    )
                    .build()

            val presentation =
                Presentation.createForWidthAndHeight(
                    outputWidth,
                    outputHeight,
                    Presentation.LAYOUT_SCALE_TO_FIT,
                )

            val editedMediaItem =
                EditedMediaItem.Builder(
                    MediaItem.fromUri(
                        Uri.fromFile(
                            File(inputPath),
                        ),
                    ),
                )
                    .setEffects(
                        Effects(
                            emptyList(),
                            listOf(presentation),
                        ),
                    )
                    .build()

            val transformer =
                Transformer.Builder(applicationContext)
                    .setEncoderFactory(encoderFactory)
                    .setVideoMimeType(
                        MimeTypes.VIDEO_H264,
                    )
                    .setAudioMimeType(
                        MimeTypes.AUDIO_AAC,
                    )
                    .addListener(
                        createTransformerListener(
                            outputFile,
                        ),
                    )
                    .build()

            activeTransformer = transformer

            emitProgress(
                progressStartForAttempt(attempt),
            )

            transformer.start(
                editedMediaItem,
                outputFile.absolutePath,
            )

            stopProgressPolling()
            mainHandler.post(progressRunnable)
        } catch (error: Exception) {
            activeTransformer = null

            val message =
                error.message?.trim().orEmpty()

            val code =
                if (
                    message.contains(
                        "resolution",
                        ignoreCase = true,
                    ) ||
                    message.contains(
                        "codec",
                        ignoreCase = true,
                    ) ||
                    message.contains(
                        "encoder",
                        ignoreCase = true,
                    ) ||
                    message.contains(
                        "format",
                        ignoreCase = true,
                    )
                ) {
                    ERROR_UNSUPPORTED_RESOLUTION
                } else {
                    ERROR_COMPRESSION_FAILED
                }

            finishWithError(
                code = code,
                message =
                    message.ifBlank {
                        "Cihaz videoyu çözünürlüğünü "
                            + "koruyarak sıkıştıramadı."
                    },
            )
        }
    }

    private fun createTransformerListener(
        outputFile: File,
    ): Transformer.Listener {
        return object : Transformer.Listener {
            override fun onCompleted(
                composition: Composition,
                result: ExportResult,
            ) {
                handleCompleted(outputFile)
            }

            override fun onError(
                composition: Composition,
                result: ExportResult,
                exception: ExportException,
            ) {
                handleExportError(exception)
            }
        }
    }

    private fun handleCompleted(
        outputFile: File,
    ) {
        stopProgressPolling()
        activeTransformer = null

        if (
            cancelled.get() ||
            finished.get()
        ) {
            safeDelete(outputFile)
            return
        }

        val outputSize = outputFile.length()

        if (outputSize <= 0L) {
            finishWithError(
                code = ERROR_COMPRESSION_FAILED,
                message =
                    "Sıkıştırılmış video dosyası oluşturulamadı.",
            )
            return
        }

        if (
            outputSize > maxBytes &&
            currentAttempt + 1 < MAX_ATTEMPTS
        ) {
            val nextTargetBytes =
                calculateNextTargetBytes(
                    outputSize,
                )

            safeDelete(outputFile)
            outputFiles.remove(outputFile)

            startAttempt(
                attempt = currentAttempt + 1,
                attemptTargetBytes = nextTargetBytes,
            )
            return
        }

        if (outputSize > maxBytes) {
            finishWithError(
                code = ERROR_OUTPUT_TOO_LARGE,
                message =
                    "Video çözünürlüğü korunarak "
                        + "yükleme sınırına indirilemedi.",
            )
            return
        }

        finishWithSuccess(
            outputFile = outputFile,
            outputSize = outputSize,
        )
    }

    private fun handleExportError(
        exception: ExportException,
    ) {
        val message =
            exception.message?.trim().orEmpty()

        val code =
            if (
                message.contains(
                    "resolution",
                    ignoreCase = true,
                ) ||
                message.contains(
                    "codec",
                    ignoreCase = true,
                ) ||
                message.contains(
                    "encoder",
                    ignoreCase = true,
                ) ||
                message.contains(
                    "format",
                    ignoreCase = true,
                )
            ) {
                ERROR_UNSUPPORTED_RESOLUTION
            } else {
                ERROR_COMPRESSION_FAILED
            }

        finishWithError(
            code = code,
            message =
                message.ifBlank {
                    "Cihaz videoyu sıkıştıramadı."
                },
        )
    }

    private fun finishWithSuccess(
        outputFile: File,
        outputSize: Long,
    ) {
        if (!finished.compareAndSet(false, true)) {
            safeDelete(outputFile)
            return
        }

        stopProgressPolling()
        activeTransformer = null

        outputFiles
            .filter { file ->
                file.absolutePath != outputFile.absolutePath
            }
            .forEach(::safeDelete)

        outputFiles.clear()
        outputFiles += outputFile

        emitProgress(100)

        try {
            onSuccess(
                mapOf(
                    "outputPath" to outputFile.absolutePath,
                    "outputSizeBytes" to outputSize,
                    "targetVideoBitrate" to
                        currentVideoBitrate,
                    "outputWidth" to outputWidth,
                    "outputHeight" to outputHeight,
                    "attemptCount" to currentAttempt + 1,
                    "wasCompressed" to true,
                ),
            )
        } catch (error: Exception) {
            Log.e(
                LOG_TAG,
                "Sıkıştırma sonucu Flutter'a iletilemedi.",
                error,
            )
        }
    }

    private fun finishWithError(
        code: String,
        message: String,
    ) {
        if (
            cancelled.get() &&
            code != ERROR_COMPRESSION_CANCELLED
        ) {
            return
        }

        if (!finished.compareAndSet(false, true)) {
            return
        }

        stopProgressPolling()

        val transformer = activeTransformer
        activeTransformer = null

        try {
            transformer?.cancel()
        } catch (error: Exception) {
            Log.w(
                LOG_TAG,
                "Hatalı export temizlenemedi.",
                error,
            )
        }

        deleteAllOutputs()
        emitError(code, message)
    }

    private fun calculateVideoBitrate(
        attemptTargetBytes: Long,
    ): Int? {
        val durationSeconds =
            (durationMs / 1000.0)
                .coerceAtLeast(1.0)

        val targetTotalBitrate =
            (
                attemptTargetBytes *
                    BITS_PER_BYTE *
                    CONTAINER_SAFETY_RATIO /
                    durationSeconds
                ).roundToInt()

        val availableVideoBitrate =
            targetTotalBitrate -
                RESERVED_AUDIO_BITRATE

        if (
            availableVideoBitrate <
            MIN_VIDEO_BITRATE
        ) {
            return null
        }

        return availableVideoBitrate.coerceAtMost(
            MAX_VIDEO_BITRATE,
        )
    }

    private fun calculateNextTargetBytes(
        actualOutputBytes: Long,
    ): Long {
        val proportionalTarget =
            (
                currentTargetBytes.toDouble() *
                    maxBytes.toDouble() /
                    actualOutputBytes.toDouble() *
                    RETRY_SAFETY_RATIO
                ).toLong()

        val maximumReductionTarget =
            (
                currentTargetBytes *
                    RETRY_MAX_TARGET_RATIO
                ).toLong()

        return minOf(
            proportionalTarget,
            maximumReductionTarget,
        ).coerceAtLeast(1L)
    }

    private fun mapAttemptProgress(
        attempt: Int,
        attemptProgress: Int,
    ): Int {
        val safeAttempt =
            attempt.coerceIn(
                0,
                MAX_ATTEMPTS - 1,
            )

        val start =
            PROGRESS_STARTS[safeAttempt]

        val end =
            PROGRESS_ENDS[safeAttempt]

        val fraction =
            attemptProgress
                .coerceIn(0, 100) / 100.0

        return (
            start +
                ((end - start) * fraction)
            ).roundToInt()
    }

    private fun progressStartForAttempt(
        attempt: Int,
    ): Int {
        return PROGRESS_STARTS[
            attempt.coerceIn(
                0,
                MAX_ATTEMPTS - 1,
            )
        ]
    }

    private fun emitProgress(progress: Int) {
        val safeProgress =
            progress.coerceIn(0, 100)

        if (safeProgress <= lastReportedProgress) {
            return
        }

        lastReportedProgress = safeProgress

        try {
            onProgress(safeProgress)
        } catch (error: Exception) {
            Log.w(
                LOG_TAG,
                "İlerleme callback'i tamamlanamadı.",
                error,
            )
        }
    }

    private fun emitError(
        code: String,
        message: String,
    ) {
        try {
            onError(code, message)
        } catch (error: Exception) {
            Log.e(
                LOG_TAG,
                "Sıkıştırma hatası Flutter'a iletilemedi.",
                error,
            )
        }
    }

    private fun stopProgressPolling() {
        mainHandler.removeCallbacks(progressRunnable)
    }

    private fun deleteAllOutputs() {
        outputFiles.forEach(::safeDelete)
        outputFiles.clear()
    }

    private fun safeDelete(file: File) {
        try {
            if (file.exists()) {
                file.delete()
            }
        } catch (error: Exception) {
            Log.w(
                LOG_TAG,
                "Geçici video silinemedi: ${file.path}",
                error,
            )
        }
    }

    private fun runOnMain(action: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            action()
        } else {
            mainHandler.post(action)
        }
    }

    private fun encoderSafeDimension(
        value: Int,
    ): Int {
        if (value <= 0) {
            return 0
        }

        return if (value % 2 == 0) {
            value
        } else {
            value - 1
        }
    }

    private companion object {
        const val LOG_TAG =
            "HexaVideoCompressor"

        const val OUTPUT_DIRECTORY_NAME =
            "hexa_video_compression"

        const val PROGRESS_INTERVAL_MS = 300L

        const val MAX_ATTEMPTS = 3

        val PROGRESS_STARTS =
            intArrayOf(0, 72, 90)

        val PROGRESS_ENDS =
            intArrayOf(72, 90, 99)

        const val BITS_PER_BYTE = 8.0

        const val CONTAINER_SAFETY_RATIO = 0.92
        const val RETRY_SAFETY_RATIO = 0.90
        const val RETRY_MAX_TARGET_RATIO = 0.82

        const val RESERVED_AUDIO_BITRATE = 192_000
        const val REQUESTED_AUDIO_BITRATE = 96_000

        const val MIN_VIDEO_BITRATE = 350_000
        const val MAX_VIDEO_BITRATE = 40_000_000

        const val ERROR_UNSUPPORTED_ANDROID =
            "unsupported_android"

        const val ERROR_INVALID_INPUT =
            "invalid_input"

        const val ERROR_INVALID_ARGUMENTS =
            "invalid_arguments"

        const val ERROR_OUTPUT_DIRECTORY =
            "output_directory_failed"

        const val ERROR_UNSUPPORTED_RESOLUTION =
            "unsupported_resolution"

        const val ERROR_VIDEO_TOO_LONG =
            "video_too_long"

        const val ERROR_OUTPUT_TOO_LARGE =
            "output_too_large"

        const val ERROR_COMPRESSION_FAILED =
            "compression_failed"

        const val ERROR_COMPRESSION_CANCELLED =
            "compression_cancelled"
    }
}