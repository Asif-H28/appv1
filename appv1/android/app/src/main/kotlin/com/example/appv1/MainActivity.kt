package com.example.appv1

import android.content.Context
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.appv1/updater"

    companion object {
        private const val ENGINE_ID = "appv1_main_engine"
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
}
