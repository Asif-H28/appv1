package com.example.appv1

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.appv1/updater"

    companion object {
        private const val ENGINE_ID = "appv1_main_engine"
        private const val DOC_CHANNEL = "com.example.appv1/documents"
        private const val REQ_PICK_DOCUMENT = 4711
        private const val PICK_PREFS = "appv1_document_picks"
        private const val KEY_PATH = "pending_path"
        private const val KEY_NAME = "pending_name"
        private const val KEY_STATUS = "pending_status"
        private const val STATUS_WAITING = "waiting"
        private const val STATUS_PICKED = "picked"
        private const val STATUS_CANCELLED = "cancelled"
    }

    /**
     * Keep one FlutterEngine alive for the whole process instead of letting it
     * die with the Activity.
     *
     * Android destroys a backgrounded Activity whenever it likes — on low
     * memory, on aggressive OEM ROMs, and always when the developer option
     * "Don't keep activities" is on. By default FlutterActivity builds a fresh
     * engine in onCreate and tears it down in onDestroy, so a recreated
     * Activity re-runs main() and the user lands back on the splash and home
     * screen, losing whatever they were doing.
     *
     * Providing the engine ourselves means a recreated Activity reattaches to
     * the isolate that is already running, with its Navigator stack and widget
     * state intact. The engine is built lazily here rather than in an
     * Application subclass so a process started only for a background FCM
     * message doesn't pay for a UI isolate it will never show.
     *
     * Note this survives Activity recreation, not full process death — if
     * Android kills the process outright, main() still re-runs.
     */
    override fun provideFlutterEngine(context: Context): FlutterEngine {
        FlutterEngineCache.getInstance().get(ENGINE_ID)?.let { return it }

        val engine = FlutterEngine(context.applicationContext)
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
        return engine
    }

    /** The cache owns the engine now — don't let a finishing Activity kill it. */
    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "uninstallApp" -> {
                        val packageName = call.argument<String>("packageName")
                            ?: applicationContext.packageName
                        val intent = Intent(Intent.ACTION_DELETE).apply {
                            data = Uri.parse("package:$packageName")
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DOC_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickDocument" -> {
                        markWaiting()
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "application/pdf"
                        }
                        startActivityForResult(intent, REQ_PICK_DOCUMENT)
                        // Returns straight away on purpose. The answer is
                        // collected from disk, never from a callback we hold.
                        result.success(null)
                    }
                    // Collects a pick that completed while Dart was gone.
                    "consumePendingDocument" -> result.success(takeStoredPick())
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.appv1/kiosk")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startLockTask" -> {
                        try {
                            startLockTask()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    "stopLockTask" -> {
                        try {
                            stopLockTask()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ── Document picking ────────────────────────────────────────────────
    //
    // Deliberately not using the file_picker plugin. It parks the Dart
    // MethodChannel.Result in a field and waits for onActivityResult; when
    // Android destroys this Activity while the file manager is in front —
    // routine on a low-memory device — that field is gone and the pick is
    // silently dropped (flutter_file_picker#1258, open with no fix).
    //
    // Android itself never loses the result: it delivers onActivityResult to
    // the *recreated* Activity. So the durable move is to write the file out
    // the moment the result lands, before anything can be torn down, and have
    // Dart read the outcome back from disk. There is deliberately no in-memory
    // callback anywhere in this path — nothing to lose means nothing to
    // recover, so the surviving and destroyed cases run identical code.

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQ_PICK_DOCUMENT) return

        val uri = data?.data
        if (resultCode != RESULT_OK || uri == null) {
            setStatus(STATUS_CANCELLED)
            return
        }

        // Copy off the main thread — a large PDF would otherwise risk an ANR.
        Thread {
            val picked = try {
                copyToCache(uri)
            } catch (e: Exception) {
                null
            }
            if (picked != null) storePick(picked) else setStatus(STATUS_CANCELLED)
        }.start()
    }

    /**
     * Streams the content:// URI into our own cache and returns {path, name}.
     *
     * The URI grant dies with the Activity, so holding on to it would leave us
     * with an unreadable reference later. A real file in cacheDir stays valid.
     */
    private fun copyToCache(uri: Uri): HashMap<String, String>? {
        val name = queryDisplayName(uri) ?: "document_${System.currentTimeMillis()}.pdf"

        val dir = File(cacheDir, "picked_documents").apply { mkdirs() }
        val outFile = File(dir, "${System.currentTimeMillis()}_$name")

        contentResolver.openInputStream(uri)?.use { input ->
            FileOutputStream(outFile).use { output -> input.copyTo(output) }
        } ?: return null

        return hashMapOf("path" to outFile.absolutePath, "name" to name)
    }

    private fun queryDisplayName(uri: Uri): String? {
        return contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (idx >= 0 && cursor.moveToFirst()) cursor.getString(idx) else null
        }
    }

    private fun prefs() = getSharedPreferences(PICK_PREFS, Context.MODE_PRIVATE)

    private fun markWaiting() = setStatus(STATUS_WAITING)

    private fun setStatus(status: String) {
        prefs().edit().putString(KEY_STATUS, status).apply()
    }

    private fun storePick(picked: HashMap<String, String>) {
        prefs().edit()
            .putString(KEY_PATH, picked["path"])
            .putString(KEY_NAME, picked["name"])
            .putString(KEY_STATUS, STATUS_PICKED)
            .apply()
    }

    /**
     * Reports the outcome, clearing it once a final answer is handed over so
     * each pick is delivered exactly once.
     *
     * "waiting" means the copy is still in flight — Dart polls until it isn't.
     */
    private fun takeStoredPick(): HashMap<String, String?> {
        val p = prefs()
        val status = p.getString(KEY_STATUS, null) ?: STATUS_CANCELLED
        if (status == STATUS_WAITING) return hashMapOf("status" to STATUS_WAITING)

        val path = p.getString(KEY_PATH, null)
        val name = p.getString(KEY_NAME, null)
        p.edit().remove(KEY_PATH).remove(KEY_NAME).remove(KEY_STATUS).apply()

        // Cache can be evicted by the OS between the pick and the collection.
        if (status != STATUS_PICKED || path == null || name == null || !File(path).exists()) {
            return hashMapOf("status" to STATUS_CANCELLED)
        }
        return hashMapOf("status" to STATUS_PICKED, "path" to path, "name" to name)
    }
}
