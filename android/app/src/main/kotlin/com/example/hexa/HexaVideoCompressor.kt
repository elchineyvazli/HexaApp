package com.example.hexa_prod

import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
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
    private val applicationContext = context.applicationContext
    private val mainHandler = Handler(Looper.getMainLooper())
    private val cancelled = AtomicBoolean(false)
    private val outputFiles = mutableListOf<File>()

    private var activeTransformer: Transformer? = null
    private var currentAttempt = 0
    private var currentVideoBitrate = 0

    private val progressHolder = ProgressHolder()

    private val progressRunnable = object : Runnable {
        override fun run() {
            val transformer = activeTransformer ?: return

            val state = transformer.getProgress(progressHolder)

            if (state == Transformer.PROGRESS_STATE_AVAILABLE) {
                val attemptProgress = progressHolder.progress.coerceIn(0, 100)

                val mappedProgress = if (currentAttempt == 0) {
                    (attemptProgress * 0.85).roundToInt()
                } else {
                    85 + (attemptProgress * 0.15).roundToInt()
                }

                onProgress(mappedProgress.coerceIn(0, 99))
            }

            if (!cancelled.get() && activeTransformer != null) {
                mainHandler.postDelayed(this, PROGRESS_INTERVAL_MS)
            }
        }
    }

    fun start() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            fail(
                "unsupported_android",
                "Video sıkıştırma Android 6 veya daha yeni bir cihaz gerektiriyor.",
            )
            return
        }

        val inputFile = File(inputPath)

        if (!inputFile.isFile || inputFile.length() <= 0) {
            fail("invalid_input", "Sıkıştırılacak video dosyası bulunamadı.")
            return
        }

        startAttempt(attempt = 0)
    }

    fun cancel() {
        if (!cancelled.compareAndSet(false, true)) {
            return
        }

        stopProgressPolling()

        try {
            activeTransformer?.cancel()
        } catch (_: Exception) {
            // Kaynak serbest bırakma sırasında hata kullanıcıya gösterilmez.
        }

        activeTransformer = null
        deleteOutputs()

        onError("compression_cancelled", "Video sıkıştırma iptal edildi.")
    }

    private fun startAttempt(attempt: Int) {
        if (cancelled.get()) {
            return
        }

        currentAttempt = attempt

        val attemptTargetBytes = if (attempt == 0) {
            targetBytes
        } else {
            (targetBytes * SECOND_ATTEMPT_RATIO).toLong()
        }

        currentVideoBitrate = calculateVideoBitrate(attemptTargetBytes)

        val outputDirectory = File(
            applicationContext.cacheDir,
            "hexa_video_compression",
        ).apply {
            if (!exists()) {
                mkdirs()
            }
        }

        val outputFile = File(
            outputDirectory,
            "hexa_${System.currentTimeMillis()}_${attempt}.mp4",
        )

        if (outputFile.exists()) {
            outputFile.delete()
        }

        outputFiles += outputFile

        try {
            val videoSettings = VideoEncoderSettings.Builder()
                .setBitrate(currentVideoBitrate)
                .build()

            val audioSettings = AudioEncoderSettings.Builder()
                .setBitrate(REQUESTED_AUDIO_BITRATE)
                .build()

            val encoderFactory = DefaultEncoderFactory.Builder(
                applicationContext,
            )
                // Çözünürlüğün sessizce düşürülmesini engeller.
                .setEnableFallback(false)
                .setRequestedVideoEncoderSettings(videoSettings)
                .setRequestedAudioEncoderSettings(audioSettings)
                .build()

            val presentation = Presentation.createForWidthAndHeight(
                width,
                height,
                Presentation.LAYOUT_SCALE_TO_FIT,
            )

            val editedMediaItem = EditedMediaItem.Builder(
                MediaItem.fromUri(Uri.fromFile(File(inputPath))),
            )
                // Aynı çözünürlükte bir effect eklemek, aynı codec'li kaynaklarda
                // yalnızca remux yapılması yerine video encoder'ı çalıştırır.
                .setEffects(
                    Effects(
                        emptyList(),
                        listOf(presentation),
                    ),
                )
                .build()

            val transformer = Transformer.Builder(applicationContext)
                .setEncoderFactory(encoderFactory)
                .setVideoMimeType(MimeTypes.VIDEO_H264)
                .setAudioMimeType(MimeTypes.AUDIO_AAC)
                .addListener(
                    object : Transformer.Listener {
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
                            fail(
                                "compression_failed",
                                exception.message
                                    ?: "Cihaz videoyu sıkıştıramadı.",
                            )
                        }
                    },
                )
                .build()

            activeTransformer = transformer
            onProgress(if (attempt == 0) 0 else 85)

            transformer.start(editedMediaItem, outputFile.absolutePath)

            stopProgressPolling()
            mainHandler.post(progressRunnable)
        } catch (error: Exception) {
            val message = error.message.orEmpty()

            val code = if (
                message.contains("resolution", ignoreCase = true) ||
                message.contains("codec", ignoreCase = true) ||
                message.contains("format", ignoreCase = true)
            ) {
                "unsupported_resolution"
            } else {
                "compression_failed"
            }

            fail(
                code,
                if (message.isBlank()) {
                    "Cihaz videoyu çözünürlüğünü koruyarak sıkıştıramadı."
                } else {
                    message
                },
            )
        }
    }

    private fun handleCompleted(outputFile: File) {
        stopProgressPolling()
        activeTransformer = null

        if (cancelled.get()) {
            return
        }

        val outputSize = outputFile.length()

        if (outputSize <= 0) {
            fail(
                "compression_failed",
                "Sıkıştırılmış video dosyası oluşturulamadı.",
            )
            return
        }

        if (outputSize > maxBytes && currentAttempt == 0) {
            outputFile.delete()
            startAttempt(attempt = 1)
            return
        }

        if (outputSize > maxBytes) {
            fail(
                "output_too_large",
                "Video çözünürlüğü korunarak 40 MB sınırına indirilemedi.",
            )
            return
        }

        onProgress(100)

        outputFiles
            .filter { it.absolutePath != outputFile.absolutePath }
            .forEach { it.delete() }

        onSuccess(
            mapOf(
                "outputPath" to outputFile.absolutePath,
                "outputSizeBytes" to outputSize,
                "targetVideoBitrate" to currentVideoBitrate,
                "wasCompressed" to true,
            ),
        )
    }

    private fun calculateVideoBitrate(attemptTargetBytes: Long): Int {
        val durationSeconds = (durationMs / 1000.0).coerceAtLeast(1.0)

        val targetTotalBitrate = (
            attemptTargetBytes *
                BITS_PER_BYTE *
                CONTAINER_SAFETY_RATIO /
                durationSeconds
            ).roundToInt()

        return (targetTotalBitrate - RESERVED_AUDIO_BITRATE)
            .coerceIn(MIN_VIDEO_BITRATE, MAX_VIDEO_BITRATE)
    }

    private fun fail(code: String, message: String) {
        if (cancelled.get() && code != "compression_cancelled") {
            return
        }

        stopProgressPolling()

        try {
            activeTransformer?.cancel()
        } catch (_: Exception) {
            // Kaynak temizleme hatası asıl hatayı gizlememeli.
        }

        activeTransformer = null
        deleteOutputs()
        onError(code, message)
    }

    private fun stopProgressPolling() {
        mainHandler.removeCallbacks(progressRunnable)
    }

    private fun deleteOutputs() {
        outputFiles.forEach { file ->
            try {
                if (file.exists()) {
                    file.delete()
                }
            } catch (_: Exception) {
                // Geçici dosya temizleme hatası yok sayılır.
            }
        }

        outputFiles.clear()
    }

    private companion object {
        const val PROGRESS_INTERVAL_MS = 300L
        const val BITS_PER_BYTE = 8.0
        const val CONTAINER_SAFETY_RATIO = 0.90
        const val SECOND_ATTEMPT_RATIO = 0.86

        // Kaynak ses yüksek bitrateli olsa bile nihai boyutun taşmaması için
        // hesaplamada 320 kbps alan ayrılır.
        const val RESERVED_AUDIO_BITRATE = 320_000
        const val REQUESTED_AUDIO_BITRATE = 96_000

        const val MIN_VIDEO_BITRATE = 350_000
        const val MAX_VIDEO_BITRATE = 80_000_000
    }
}
