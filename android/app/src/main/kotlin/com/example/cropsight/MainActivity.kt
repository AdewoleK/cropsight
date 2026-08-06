package com.example.cropsight

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors

/**
 * flutter_gemma's own bundled-asset copy (FlutterGemmaPlugin.copyAssetToFile,
 * invoked via its "flutter_gemma_bundled" MethodChannel) runs synchronously
 * on the platform/UI thread. Confirmed on a real device (Xiaomi/MIUI,
 * Android 16) that this ANRs and gets the app killed for the ~2.9GB bundled
 * Gemma3n model — still present in flutter_gemma 1.5.2, the latest version
 * as of this fix.
 *
 * Workaround: copy the same bundled assets ourselves, on a background
 * thread, to the exact destination path flutter_gemma's Dart-side
 * `getBundledResourcePath` check expects
 * (`<app documents dir>/<resourceName>`). By the time flutter_gemma runs its
 * own copy, the file already exists and it short-circuits — its blocking
 * native code path never runs.
 */
class MainActivity : FlutterActivity() {
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var progressSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "cropsight/asset_copy_progress",
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                progressSink = events
            }

            override fun onCancel(arguments: Any?) {
                progressSink = null
            }
        })

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "cropsight/asset_copy",
        ).setMethodCallHandler { call, result ->
            if (call.method != "copyAsset") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val assetPath = call.argument<String>("assetPath")!!
            val destPath = call.argument<String>("destPath")!!
            executor.execute {
                try {
                    copyAssetInBackground(assetPath, destPath)
                    mainHandler.post { result.success(null) }
                } catch (e: Exception) {
                    mainHandler.post { result.error("COPY_ERROR", e.message, null) }
                }
            }
        }
    }

    // Requires the asset to be stored uncompressed in the APK (see
    // `androidResources { noCompress += listOf("task", "tflite", "model") }`
    // in build.gradle.kts) — openFd() throws on a compressed entry, and a
    // known length is what makes real progress reporting possible here.
    //
    // Copies to a `.part` sibling first, renaming to `destPath` only once
    // the copy is fully complete — so an interruption mid-copy (app killed,
    // device unplugged) never leaves a truncated file that a later launch's
    // `File(destPath).exists()` check would mistake for a finished install.
    private fun copyAssetInBackground(assetPath: String, destPath: String) {
        val destFile = File(destPath)
        destFile.parentFile?.mkdirs()
        val tempFile = File("$destPath.part")
        val afd = assets.openFd(assetPath)
        val total = afd.length
        var copied = 0L
        var lastReportedPercent = -1
        afd.createInputStream().use { input ->
            FileOutputStream(tempFile).use { output ->
                val buffer = ByteArray(1 shl 20) // 1MB
                while (true) {
                    val read = input.read(buffer)
                    if (read == -1) break
                    output.write(buffer, 0, read)
                    copied += read
                    val percent = ((copied * 100) / total).toInt()
                    if (percent != lastReportedPercent) {
                        lastReportedPercent = percent
                        mainHandler.post { progressSink?.success(percent) }
                    }
                }
            }
        }
        if (!tempFile.renameTo(destFile)) {
            throw java.io.IOException("Failed to finalize copy to $destPath")
        }
    }
}
